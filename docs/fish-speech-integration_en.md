# fish-speech-integration.md

Login to AutoDL and rent an instance  
Select an image:  
```
PyTorch / 2.1.0 / 3.10(ubuntu22.04) / cuda 12.1
```

After the machine boots, set up the academic accelerator  
```
source /etc/network_turbo
```

Enter the working directory  
```
cd autodl-tmp/
```

Clone the repository  
```
git clone https://gitclone.com/github.com/fishaudio/fish-speech.git ; cd fish-speech
```

Install the dependencies  
```
pip install -e.
```

If an error occurs, install PortAudio  
```
apt-get install portaudio19-dev -y
```

After installation, run  
```
pip install torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 --index-url https://download.pytorch.org/whl/cu121
```

Download the model  
```
cd tools
python download_models.py 
```

After the model is downloaded, start the API server  
```
python -m tools.api_server --listen 0.0.0.0:6006 
```

Then open the AutoDL instance page in a browser  
```
https://autodl.com/console/instance/list
```

Click the **Custom Service** button for your machine as shown below to enable port‑forwarding  
![Custom Service](images/fishspeech/autodl-01.png)

After the port‑forwarding service is set up, you can access the fish‑speech interface on your local computer at `http://localhost:6006/`  
![Service preview](images/fishspeech/autodl-02.png)

If you are deploying a single module, the core configuration is as follows  
```
selected_module:
  TTS: FishSpeech
TTS:
  FishSpeech:
    reference_audio: ["config/assets/wakeup_words.wav",]
    reference_text: ["哈啰啊，我是小智啦，声音好听的台湾女孩一枚，超开心认识你耶，最近在忙啥，别忘了给我来点有趣的料哦，我超爱听八卦的啦",]
    api_key: "123"
    api_url: "http://127.0.0.1:6006/v1/tts"
```

Then restart the service.
