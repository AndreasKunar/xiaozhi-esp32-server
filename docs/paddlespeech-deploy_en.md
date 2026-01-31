# Integrating PaddleSpeechTTS with xiaozhi Service  

## Key Points  
- **Advantages:** local offline deployment, high speed  
- **Disadvantages:** As of September 25, 2025, the default model is Chinese‑only and does **not** support English TTS. If you need bilingual (Chinese + English) synthesis, you must train a custom model yourself.  

## I. Basic Environment Requirements  
**Operating System:** Windows / Linux / WSL 2  

**Python version:** 3.9 or higher (adjust according to the Paddle official tutorial)  

**Paddle version:** Official latest version
  
```markdown
https://www.paddlepaddle.org.cn/install
```  

**Dependency manager:** conda or venv  

## II. Starting the PaddleSpeech Service  

### 1. Clone the official PaddleSpeech repository  

```bash 
git clone https://github.com/PaddlePaddle/PaddleSpeech.git
```  

### 2. Create a virtual environment

```bash
conda create -n paddle_env python=3.10 -y
conda activate paddle_env
```  

### 3. Install Paddle  
Because of different CPU/GPU architectures, follow the Paddle official installation guide that matches your Python version:  

```
https://www.paddlepaddle.org.cn/install
```  

### 4. Enter the PaddleSpeech directory 
 
```bash
cd PaddleSpeech
```  

### 5. Install PaddleSpeech  

```bash
pip install pytest-runner -i https://pypi.tuna.tsinghua.edu.cn/simple

# You can use any of the following commands
pip install paddlepaddle -i https://mirror.baidu.com/pypi/simple
pip install paddlespeech -i https://pypi.tuna.tsinghua.edu.cn/simple
```  

### 6. Automatically download TTS models using the command  

```bash
paddlespeech tts --input "你好，这是一次测试"
```  

This command will automatically download the models into the local `.paddlespeech/models` directory.  

### 7. Modify the `tts_online_application.yaml` configuration  
Reference the file located at 
```"PaddleSpeech\demos\streaming_tts_server\conf\tts_online_application.yaml"```

Open the `tts_online_application.yaml` file in an editor and set the `protocol` to `websocket`.  

### 8. Start the service  

```yaml
paddlespeech_server start --config_file ./demos/streaming_tts_server/conf/tts_online_application.yaml
# Official default startup command:
paddlespeech_server start --config_file ./conf/tts_online_application.yaml
```  

Use the appropriate command based on the actual location of your `tts_online_application.yaml`. When you see logs similar to the following, the server has started successfully: 
 
```
Prefix dict has been built successfully.
[2025-08-07 10:03:11,312] [   DEBUG] __init__.py:166 - Prefix dict has been built successfully.
INFO:     Started server process [2298]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8092 (Press CTRL+C to quit)
```  

## III. Modifying xiaozhi Configuration Files  

### 1. `main/xiaozhi-server/core/providers/tts/paddle_speech.py`  

### 2. `main/xiaozhi-server/data/.config.yaml`  
*Using a single‑module deployment*  

```yaml
selected_module:
  TTS: PaddleSpeechTTS
TTS:
  PaddleSpeechTTS:
      type: paddle_speech
      protocol: websocket 
      url:  ws://127.0.0.1:8092/paddlespeech/tts/streaming  # TTS service URL, points to the local server [default websocket: ws://127.0.0.1:8092/paddlespeech/tts/streaming]
      spk_id: 0  # Speaker ID; 0 usually denotes the default speaker
      sample_rate: 24000  # Sample rate [default 24000 for websocket, 0 for HTTP auto‑selection]
      speed: 1.0  # Playback speed; 1.0 = normal, >1 = faster, <1 = slower
      volume: 1.0  # Volume level; 1.0 = normal, >1 = louder, <1 = quieter
      save_path:   # Save path
```  

### 3. Start the xiaozhi service  

```py
python app.py
```  
Open `test_page.html` in the `test` directory to verify that the connection and message sending trigger output logs from the PaddleSpeech side.  

**Sample log output:**  

```
INFO:     127.0.0.1:44312 - "WebSocket /paddlespeech/tts/streaming" [accepted]
INFO:     connection open
[2025-08-07 11:16:33,355] [    INFO] - sentence: 哈哈，怎么突然找我聊天啦？
[2025-08-07 11:16:33,356] [    INFO] - The durations of audio is: 2.4625 s
[2025-08-07 11:16:33,356] [    INFO] - first response time: 0.1143045425415039 s
[2025-08-07 11:16:33,356] [    INFO] - final response time: 0.4777836799621582 s
[2025-08-07 11:16:33,356] [    INFO] - RTF: 0.19402382942625715
[2025-08-07 11:16:33,356] [    INFO] - Other info: front time: 0.06514096260070801 s, first am infer time: 0.008037090301513672 s, first voc infer time: 0.04112648963928223 s,
[2025-08-07 11:16:33,356] [    INFO] - Complete the synthesis of the audio streams
INFO:     connection closed
```  
