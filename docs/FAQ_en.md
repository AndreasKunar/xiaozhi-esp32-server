# Frequently Asked Questions

### 1, Why does the system recognize many languages such as Korean, Japanese, and English when I speak? 🇰🇷  
**Suggestion:** Check whether the model file `models/SenseVoiceSmall/model.pt` exists in the `models/SenseVoiceSmall` directory. If not, download it from [download the speech‑recognition model file](Deployment.md#model-files).

### 2, Why does “TTS task failed, file does not exist” appear? 📁  
**Suggestion:** Verify that `libopus` and `ffmpeg` libraries were correctly installed via `conda`. If they are missing, install them as follows:

```bash
conda install conda-forge::libopus
conda install conda-forge::ffmpeg
```

### 3, TTS frequently fails and often times out ⏰  
**Suggestion:** If `EdgeTTS` often fails, first check whether a proxy (a “ladder”) is being used. If so, try disabling the proxy and try again;  
If you are using Volcano Engine’s Doubao TTS, frequent failures may be mitigated by using the paid version, because the trial version only supports 2 concurrent connections.

### 4, I can connect to the self‑hosted server over Wi‑Fi, but not over 4G 🔐  
**Cause:** The firmware of “Xiaogē” requires a secure connection in 4G mode.  

**Solutions:** There are currently two ways to resolve this. Choose either one:

1. **Modify the code.** Reference this video for the solution: https://www.bilibili.com/video/BV18MfTYoE85  
2. **Configure an SSL certificate with Nginx.** Follow the tutorial here: https://icnt94i5ctj4.feishu.cn/docx/GnYOdMNJOoRCljx1ctecsj9cnRe

### 5, How can I improve the response speed of Xiaozhi? ⚡  
The project’s default configuration is a low‑cost setup; beginners are advised to first use the default free model to ensure it “runs”, and then optimize for “speed”.  
From version `0.5.2` onward, the project supports streaming configuration, which improves response speed by approximately `2.5 seconds` compared to earlier versions, significantly enhancing user experience.

| Module | Free Setup | Streaming Configuration |
|:---:|:---:|:---:|
| ASR (Speech Recognition) | FunASR (local) | 👍 XunfeiStreamASR (iFlytek streaming) |
| LLM (Large Language Model) | glm‑4‑flash (Zhipu) | 👍 qwen‑flash (Alibaba Tongyi) |
| VLLM (Vision Large Model) | glm‑4v‑flash (Zhipu) | 👍 qwen2.5‑vl‑3b‑instructh (Alibaba Tongyi) |
| TTS (Text‑to‑Speech) | ✅ LinkeraiTTS (Lingji streaming) | 👍 HuoshanDoubleStreamTTS (Volcano streaming) |
| Intent (Intent Recognition) | function_call (function calling) | function_call (function calling) |
| Memory (Memory Function) | mem_local_short (local short‑term memory) | mem_local_short (local short‑term memory) |

If you are concerned about the latency of each component, please refer to the [Xiaozhi component performance test report](https://github.com/xinnan-tech/xiaozhi-performance-research); you can follow the testing methodology described there to evaluate performance in your own environment.

### 6, I speak slowly and pause often; Xiaozhi keeps interrupting me 🗣️  
**Suggestion:** In the configuration file, locate the following section and increase the value of `min_silence_duration_ms` (e.g., set it to `1000`):

```yaml
VAD:
  SileroVAD:
    threshold: 0.5
    model_dir: models/snakers4_silero-vad
    min_silence_duration_ms: 700  # If pauses are long, increase this value
```

### 7, Deployment‑related Tutorials
1. [How to perform the simplest deployment](./Deployment.md)  
2. [How to perform full‑module deployment](./Deployment_all.md)  
3. [How to deploy the MQTT gateway to enable MQTT+UDP protocol](./mqtt-gateway-integration.md)  
4. [How to automatically pull the latest code of this project, compile, and start it](./dev-ops-integration.md)  
5. [How to integrate with Nginx](https://github.com/xinnan-tech/xiaozhi-esp32-server/issues/791)

### 9, Firmware compilation‑related Tutorials
1. [How to compile the Xiaozhi firmware yourself](./firmware-build.md)  
2. [How to modify the OTA address based on pre‑compiled firmware from Xiaogē](./firmware-setting.md)  
3. [How to configure OTA automatic upgrade for single‑module deployment](./ota-upgrade-guide.md)

### 10, Extension‑related Tutorials
1. [How to enable phone‑number registration on the Smart Control Panel](./ali-sms-integration.md)  
2. [How to integrate with HomeAssistant for smart home control](./homeassistant-integration.md)  
3. [How to enable visual models for object recognition when taking photos](./mcp-vision-integration.md)  
4. [How to deploy an MCP endpoint](./mcp-endpoint-enable.md)  
5. [How to access an MCP endpoint](./mcp-endpoint-integration.md)  
6. [How to obtain device information via MCP methods](./mcp-get-device-info.md)  
7. [How to enable voiceprint recognition](./voiceprint-integration.md)  
8. [News plugin source configuration guide](./newsnow_plugin_config.md)  
9. [Knowledge base RagFlow integration guide](./ragflow-integration.md)  
10. [How to deploy a context provider](./context-provider-integration.md)

### 11, Voice cloning and local speech deployment tutorials
1. [How to clone a voice tone in the Smart Control Panel](./huoshan-streamTTS-voice-cloning.md)  
2. [How to deploy integrated index‑tts locally](./index-stream-integration.md)  
3. [How to deploy integrated fish‑speech locally](./fish-speech-integration.md)  
4. [How to deploy integrated PaddleSpeech locally](./paddlespeech-deploy.md)

### 12, Performance testing tutorials
1. [Component speed testing guide](./performance_tester.md)  
2. [Publicly released test results](https://github.com/xinnan-tech/xiaozhi-performance-research)

### 13, More questions, please contact us for feedback 💬  

You can submit your questions at [issues](https://github.com/xinnan-tech/xiaozhi-esp32-server/issues).
