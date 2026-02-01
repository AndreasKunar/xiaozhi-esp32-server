import os
import io
import wave
import uuid
import json
import time
import queue
import asyncio
import traceback
import threading
import opuslib_next
from abc import ABC, abstractmethod
from config.logger import setup_logging
from typing import Optional, Tuple, List
from core.handle.receiveAudioHandle import startToChat
from core.handle.reportHandle import enqueue_asr_report
from core.utils.util import remove_punctuation_and_length
from core.handle.receiveAudioHandle import handleAudioMessage

TAG = __name__
logger = setup_logging()


class ASRProviderBase(ABC):
    def __init__(self):
        pass

    # Open audio channel
    async def open_audio_channels(self, conn):
        conn.asr_priority_thread = threading.Thread(
            target=self.asr_text_priority_thread, args=(conn,), daemon=True
        )
        conn.asr_priority_thread.start()

    # Ordered processing of ASR audio
    def asr_text_priority_thread(self, conn):
        while not conn.stop_event.is_set():
            try:
                message = conn.asr_audio_queue.get(timeout=1)
                future = asyncio.run_coroutine_threadsafe(
                    handleAudioMessage(conn, message),
                    conn.loop,
                )
                future.result()
            except queue.Empty:
                continue
            except Exception as e:
                logger.bind(tag=TAG).error(
                    f"Failed to process ASR text: {str(e)}, Type: {type(e).__name__}, Stack: {traceback.format_exc()}"
                )
                continue

    # Receive audio
    async def receive_audio(self, conn, audio, audio_have_voice):
        if conn.client_listen_mode == "manual":
            # Manual mode: cache audio for ASR recognition
            conn.asr_audio.append(audio)
        else:
            # Automatic/real-time mode: use VAD detection
            have_voice = audio_have_voice

            conn.asr_audio.append(audio)
            if not have_voice and not conn.client_have_voice:
                conn.asr_audio = conn.asr_audio[-10:]
                return

            # Trigger recognition when voice stops detected by VAD in automatic mode
            if conn.client_voice_stop:
                asr_audio_task = conn.asr_audio.copy()
                conn.asr_audio.clear()
                conn.reset_vad_states()

                if len(asr_audio_task) > 15:
                    await self.handle_voice_stop(conn, asr_audio_task)

    # Handle voice stop
    async def handle_voice_stop(self, conn, asr_audio_task: List[bytes]):
        """Parallel processing of ASR and voiceprint recognition"""
        try:
            total_start_time = time.monotonic()

            # Prepare audio data
            if conn.audio_format == "pcm":
                pcm_data = asr_audio_task
            else:
                pcm_data = self.decode_opus(asr_audio_task)

            combined_pcm_data = b"".join(pcm_data)

            # Prepare WAV data in advance
            wav_data = None
            if conn.voiceprint_provider and combined_pcm_data:
                wav_data = self._pcm_to_wav(combined_pcm_data)

            # Define ASR task
            asr_task = self.speech_to_text(asr_audio_task, conn.session_id, conn.audio_format)

            if conn.voiceprint_provider and wav_data:
                voiceprint_task = conn.voiceprint_provider.identify_speaker(wav_data, conn.session_id)
                # Concurrently wait for both results
                asr_result, voiceprint_result = await asyncio.gather(
                    asr_task, voiceprint_task, return_exceptions=True
                )
            else:
                asr_result = await asr_task
                voiceprint_result = None

            # Log recognition results - check for exceptions
            if isinstance(asr_result, Exception):
                logger.bind(tag=TAG).error(f"ASR recognition failed: {asr_result}")
                raw_text = ""
            else:
                raw_text, _ = asr_result

            if isinstance(voiceprint_result, Exception):
                logger.bind(tag=TAG).error(f"Voiceprint recognition failed: {voiceprint_result}")
                speaker_name = ""
            else:
                speaker_name = voiceprint_result

            # Determine ASR result type
            if isinstance(raw_text, dict):
                # FunASR returns dict format
                if speaker_name:
                    raw_text["speaker"] = speaker_name

                # Log recognition results
                if raw_text.get("language"):
                    logger.bind(tag=TAG).info(f"Recognized language: {raw_text['language']}")
                if raw_text.get("emotion"):
                    logger.bind(tag=TAG).info(f"Recognized emotion: {raw_text['emotion']}")
                if raw_text.get("content"):
                    logger.bind(tag=TAG).info(f"Recognized text: {raw_text['content']}")
                if speaker_name:
                    logger.bind(tag=TAG).info(f"Recognized speaker: {speaker_name}")

                # Convert to JSON string for downstream
                enhanced_text = json.dumps(raw_text, ensure_ascii=False)
                content_for_length_check = raw_text.get("content", "")
            else:
                # Other ASR returns plain text
                if raw_text:
                    logger.bind(tag=TAG).info(f"Recognized text: {raw_text}")
                if speaker_name:
                    logger.bind(tag=TAG).info(f"Recognized speaker: {speaker_name}")

                # Build JSON string containing speaker information
                enhanced_text = self._build_enhanced_text(raw_text, speaker_name)
                content_for_length_check = raw_text

            # Performance monitoring
            total_time = time.monotonic() - total_start_time
            logger.bind(tag=TAG).debug(f"Total processing time: {total_time:.3f}s")

            # Check text length
            text_len, _ = remove_punctuation_and_length(content_for_length_check)
            self.stop_ws_connection()

            if text_len > 0:
                # Use custom module for reporting
                await startToChat(conn, enhanced_text)
                enqueue_asr_report(conn, enhanced_text, asr_audio_task)
                
        except Exception as e:
            logger.bind(tag=TAG).error(f"Voice stop processing failure: {e}")
            import traceback
            logger.bind(tag=TAG).debug(f"Exception details: {traceback.format_exc()}")

    def _build_enhanced_text(self, text: str, speaker_name: Optional[str]) -> str:
        """Build text containing speaker information (only for plain text ASR)"""
        if speaker_name and speaker_name.strip():
            return json.dumps({
                "speaker": speaker_name,
                "content": text
            }, ensure_ascii=False)
        else:
            return text

    def _pcm_to_wav(self, pcm_data: bytes) -> bytes:
        """Convert PCM data to WAV format"""
        if len(pcm_data) == 0:
            logger.bind(tag=TAG).warning("PCM data is empty, cannot convert to WAV")
            return b""
        
        # Ensure data length is even (16-bit audio)
        if len(pcm_data) % 2 != 0:
            pcm_data = pcm_data[:-1]
        
        # Create WAV file header
        wav_buffer = io.BytesIO()
        try:
            with wave.open(wav_buffer, 'wb') as wav_file:
                wav_file.setnchannels(1)      # Mono
                wav_file.setsampwidth(2)      # 16-bit
                wav_file.setframerate(16000)  # 16kHz sampling rate
                wav_file.writeframes(pcm_data)
            
            wav_buffer.seek(0)
            wav_data = wav_buffer.read()
            
            return wav_data
        except Exception as e:
            logger.bind(tag=TAG).error(f"WAV conversion failed: {e}")
            return b""

    def stop_ws_connection(self):
        pass

    def save_audio_to_file(self, pcm_data: List[bytes], session_id: str) -> str:
        """Save PCM data as a WAV file"""
        module_name = __name__.split(".")[-1]
        file_name = f"asr_{module_name}_{session_id}_{uuid.uuid4()}.wav"
        file_path = os.path.join(self.output_dir, file_name)

        with wave.open(file_path, "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)  # 2 bytes = 16-bit
            wf.setframerate(16000)
            wf.writeframes(b"".join(pcm_data))

        return file_path

    @abstractmethod
    async def speech_to_text(
        self, opus_data: List[bytes], session_id: str, audio_format="opus"
    ) -> Tuple[Optional[str], Optional[str]]:
        """Convert speech data to text"""
        pass

    @staticmethod
    def decode_opus(opus_data: List[bytes]) -> List[bytes]:
        """Decode Opus audio data to PCM data"""
        decoder = None
        try:
            decoder = opuslib_next.Decoder(16000, 1)
            pcm_data = []
            buffer_size = 960  # Process 960 samples at a time (60ms at 16kHz)
            
            for i, opus_packet in enumerate(opus_data):
                try:
                    if not opus_packet or len(opus_packet) == 0:
                        continue
                    
                    pcm_frame = decoder.decode(opus_packet, buffer_size)
                    if pcm_frame and len(pcm_frame) > 0:
                        pcm_data.append(pcm_frame)
                        
                except opuslib_next.OpusError as e:
                    logger.bind(tag=TAG).warning(f"Opus decoding error, skipping packet {i}: {e}")
                except Exception as e:
                    logger.bind(tag=TAG).error(f"Audio processing error, packet {i}: {e}")
            
            return pcm_data
            
        except Exception as e:
            logger.bind(tag=TAG).error(f"Error occurred during audio decoding: {e}")
            return []
        finally:
            if decoder is not None:
                try:
                    del decoder
                except Exception as e:
                    logger.bind(tag=TAG).debug(f"Error occurred while releasing decoder resources: {e}")
