# IndexStreamTTS Usage Guide

## Environment Setup

### 1. Clone the Repository  
```bash 
git clone https://github.com/Ksuriuri/index-tts-vllm.git
```
Enter the directory after cloning  
```bash
cd index-tts-vllm
```
Switch to the specified version (use the historic VLLM‑0.10.2 version)  
```bash
git checkout 224e8d5e5c8f66801845c66b30fa765328fd0be3
```

### 2. Create and Activate a Conda Environment  
```bash 
conda create -n index-tts-vllm python=3.12
conda activate index-tts-vllm
```

### 3. Install PyTorch (Version must be 2.8.0)  
#### Check the highest GPU‑supported version and the actual installed version  
```bash
nvidia-smi
nvcc --version
``` 
#### Highest CUDA version supported by the driver  
```bash
CUDA Version: 12.8
```
#### Actual CUDA compiler version installed  
```bash
Cuda compilation tools, release 12.8, V12.8.89
```
#### Accordingly, the installation command (the version provided by pytorch defaults to the 12.8 driver)  
```bash
pip install torch torchvision
```
The required PyTorch version is **2.8.0** (corresponding to vllm 0.10.2). See the official PyTorch site for the exact installation command: [PyTorch Official Site](https://pytorch.org/get-started/locally/)

### 4. Install Dependencies  
```bash 
pip install -r requirements.txt
```

### 5. Download Model Weights  
#### Option 1: Download the official weight files and convert them  
These are the official weight files; you can place them anywhere locally and they support **IndexTTS‑1.5** weights.  

| HuggingFace                                                               | ModelScope                                                            |
|---------------------------------------------------------------------------|-----------------------------------------------------------------------|
| [IndexTTS](https://huggingface.co/IndexTeam/Index-TTS)                    | [IndexTTS](https://modelscope.cn/models/IndexTeam/Index-TTS)           |
| [IndexTTS‑1.5](https://huggingface.co/IndexTeam/IndexTTS-1.5)              | [IndexTTS‑1.5](https://modelscope.cn/models/IndexTeam/IndexTTS-1.5)     |

Below we use the ModelScope installation method as an example.  
**Note:** If you have not installed `git` or enabled LFS, install and initialize it first.  
```bash
sudo apt-get install git-lfs
git lfs install
```
Create a model directory and clone the model:  
```bash 
mkdir model_dir
cd model_dir
git clone https://www.modelscope.cn/IndexTeam/IndexTTS-1.5.git
```

#### Convert the model weights  
```bash 
bash convert_hf_format.sh /path/to/your/model_dir
```
For example, if the downloaded IndexTTS‑1.5 model is stored in `model_dir/IndexTTS-1.5`, run:  
```bash
bash convert_hf_format.sh model_dir/IndexTTS-1.5
```
This command converts the official model weights to a format compatible with the `transformers` library and stores them in a `vllm` folder under the model path, making them ready for loading by the vllm library later.

### 6. Adjust the Interface to Fit the Project  
The API response format does not match the project, so we need to modify it to directly return audio data.  
```bash
vi api_server.py
```
```python
@app.post("/tts", responses={
    200: {"content": {"application/octet-stream": {}}},
    500: {"content": {"application/json": {}}}
})
async def tts_api(request: Request):
    try:
        data = await request.json()
        text = data["text"]
        character = data["character"]

        global tts
        sr, wav = await tts.infer_with_ref_audio_embed(character, text)

        return Response(content=wav.tobytes(), media_type="application/octet-stream")
        
    except Exception as ex:
        tb_str = ''.join(traceback.format_exception(type(ex), ex, ex.__traceback__))
        print(tb_str)
        return JSONResponse(
            status_code=500,
            content={
                "status": "error",
                "error": str(tb_str)
            }
        )
```

### 7. Write a Shell Script to Start the Service (must be run inside the appropriate conda environment)  
```bash 
vi start_api.sh
```
Paste the following content and press `:wq` to save.  
**Important:** Replace `/home/system/index-tts-vllm/model_dir/IndexTTS-1.5` with the actual path to your model directory.  
```bash
# Activate the conda environment
conda activate index-tts-vllm 
echo "Activated conda environment"
sleep 2

# Find the process occupying port 11996
PID_VLLM=$(sudo netstat -tulnp | grep 11996 | awk '{print $7}' | cut -d'/' -f1)

# Check whether a process was found
if [ -z "$PID_VLLM" ]; then
  echo "No process occupying port 11996 was found"
else
  echo "Found a process occupying port 11996, PID: $PID_VLLM"
  # Try a graceful kill, wait 2 seconds
  kill $PID_VLLM
  sleep 2
  # Check if the process is still running
  if ps -p $PID_VLLM > /dev/null; then
    echo "Process still running, forcibly killing it..."
    kill -9 $PID_VLLM
  fi
  echo "Process $PID_VLLM terminated"
fi

# Find VLLM‑related processes (EngineCore)
GPU_PIDS=$(ps aux | grep -E "VLLM|EngineCore" | grep -v grep | awk '{print $2}')

# Check whether any such processes exist
if [ -z "$GPU_PIDS" ]; then
  echo "No VLLM‑related processes found"
else
  echo "Found VLLM‑related processes, PIDs: $GPU_PIDS"
  # Try a graceful kill, wait 2 seconds
  kill $GPU_PIDS
  sleep 2
  # Check if they are still alive
  if ps -p $GPU_PIDS > /dev/null; then
    echo "Processes still running, forcibly killing them..."
    kill -9 $GPU_PIDS
  fi
  echo "Processes $GPU_PIDS terminated"
fi

# Create a tmp directory if it does not exist
mkdir -p tmp

# Run api_server.py in the background, redirecting logs to tmp/server.log
nohup python api_server.py --model_dir /home/system/index-tts-vllm/model_dir/IndexTTS-1.5 --port 11996 > tmp/server.log 2>&1 &
echo "api_server.py has been started in the background; logs are in tmp/server.log"
```
Make the script executable and run it:  
```bash 
chmod +x start_api.sh
./start_api.sh
```
Logs are written to `tmp/server.log`; you can monitor them with:  
```bash
tail -f tmp/server.log
```
If the GPU memory is sufficient, you can add the startup argument `--gpu_memory_utilization` (default is `0.25`) to control the GPU memory usage ratio.

## Voice Configuration  
`index-tts-vllm` supports registering custom voices through a configuration file, allowing both single‑voice and mixed‑voice setups.  
Edit `assets/speaker.json` in the project root to define custom voices.  

### Configuration Format  
```json
{
    "VoiceName1": [
        "Path/To/AudioFile1.wav",
        "Path/To/AudioFile2.wav"
    ],
    "VoiceName2": [
        "Path/To/AudioFile3.wav"
    ]
}
```
**Note:** After adding new voices, you must restart the service for the new voices to be registered. In the control panel, add the corresponding voice(s) (if using a single‑module setup, replace with the appropriate voice name).
