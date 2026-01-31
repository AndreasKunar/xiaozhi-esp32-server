# IndexStreamTTS Usage Guide

## Environment Setup
### 1. Clone the Repository  
```bash
git clone https://github.com/Ksuriuri/index-tts-vllm.git
```
Enter the cloned directory  
```bash
cd index-tts-vllm
```
Switch to the specified version (use the historical version of VLLM‑0.10.2)  
```bash
git checkout 224e8d5e5c8f66801845c66b30fa765328fd0be3
```

### 2. Create and Activate a Conda Environment  
```bash
conda create -n index-tts-vllm python=3.12
conda activate index-tts-vllm
```

### 3. Install PyTorch (Version must be 2.8.0)  
#### Check the highest CUDA version supported by your GPU and the actual version installed  
```bash
nvidia-smi
nvcc --version
``` 
#### The highest CUDA version supported by the driver  
```
CUDA Version: 12.8
```
#### The actual CUDA compiler version installed  
```
Cuda compilation tools, release 12.8, V12.8.89
```
#### Therefore, the corresponding installation command (PyTorch defaults to the 12.8 driver version)  
```bash
pip install torch torchvision
```
You need PyTorch version **2.8.0** (which matches VLLM 0.10.2). See the [official PyTorch site](https://pytorch.org/get-started/locally/) for the exact installation command.

### 4. Install Dependencies  
```bash
pip install -r requirements.txt
```

### 5. Download Model Weights  
#### Option 1: Download the official weight files and convert them  
These are the official weights; you can place them anywhere locally. They support **IndexTTS-1.5** weights.  

| HuggingFace                                 | ModelScope                                 |
|---------------------------------------------|-------------------------------------------|
| [IndexTTS](https://huggingface.co/IndexTeam/Index-TTS) | [IndexTTS](https://modelscope.cn/models/IndexTeam/Index-TTS) |
| [IndexTTS-1.5](https://huggingface.co/IndexTeam/IndexTTS-1.5) | [IndexTTS-1.5](https://modelscope.cn/models/IndexTeam/IndexTTS-1.5) |

Below is an example using the ModelScope installation method.  
**Note:** If you have already installed `git` you can skip the `git-lfs` installation step.  

```bash
# Install Git LFS (skip if already installed)
sudo apt-get install git-lfs
git lfs install
```

Create a directory for the models and pull the repository:  
```bash
mkdir model_dir
cd model_dir
git clone https://www.modelscope.cn/IndexTeam/IndexTTS-1.5.git
```

#### Convert the Model Weights  
```bash
bash convert_hf_format.sh /path/to/your/model_dir
```
For example, if the downloaded IndexTTS-1.5 model is located in `model_dir/IndexTTS-1.5`, run:  
```bash
bash convert_hf_format.sh model_dir/IndexTTS-1.5
```
This command converts the official weights into a format compatible with the `transformers` library and places them in a `vllm` folder under the model directory for easy loading by the VLLM library later.

### 6. Adjust the API Interface to Fit the Project  
The response format of the API does not match the project requirements; it needs to be modified to return raw audio data directly.  

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

### 7. Write a Shell Script to Start the Service (Make sure you run it inside the appropriate conda environment)  
```bash
vi start_api.sh
```
Paste the following content, then press `:wq` to save and exit.  
**Please replace `/home/system/index-tts-vllm/model_dir/IndexTTS-1.5` with the actual path to your model directory.**

```bash
# Activate the conda environment
conda activate index-tts-vllm
echo "Activated conda environment"
sleep 2

# Find the process using port 11996
PID_VLLM=$(sudo netstat -tulnp | grep 11996 | awk '{print $7}' | cut -d'/' -f1)

# Check if a process was found
if [ -z "$PID_VLLM" ]; then
  echo "No process found using port 11996"
else
  echo "Found a process using port 11996, PID: $PID_VLLM"
  # Try a normal kill, wait 2 seconds
  kill $PID_VLLM
  sleep 2
  # Check if the process is still running
  if ps -p $PID_VLLM > /dev/null; then
    echo "Process is still running, force killing..."
    kill -9 $PID_VLLM
  fi
  echo "Process $PID_VLLM terminated"
fi

# Find VLLM-related processes (EngineCore)
GPU_PIDS=$(ps aux | grep -E "VLLM|EngineCore" | grep -v grep | awk '{print $2}')

# Check if any such processes exist
if [ -z "$GPU_PIDS" ]; then
  echo "No VLLM-related processes found"
else
  echo "Found VLLM-related processes, PIDs: $GPU_PIDS"
  # Try a normal kill, wait 2 seconds
  kill $GPU_PIDS
  sleep 2
  # Check if they are still running
  if ps -p $GPU_PIDS > /dev/null; then
    echo "Processes are still running, force killing..."
    kill -9 $GPU_PIDS
  fi
  echo "Processes $GPU_PIDS terminated"
fi

# Create a tmp directory if it doesn't exist
mkdir -p tmp

# Run api_server.py in the background, redirecting logs to tmp/server.log
nohup python api_server.py --model_dir /home/system/index-tts-vllm/model_dir/IndexTTS-1.5 --port 11996 > tmp/server.log 2>&1 &
echo "api_server.py has been started in the background, logs are in tmp/server.log"
```
Make the script executable and run it:  
```bash
chmod +x start_api.sh
./start_api.sh
```
You can view the log with:  
```bash
tail -f tmp/server.log
```
If you have enough GPU memory, you can add the parameter `--gpu_memory_utilization` (default is 0.25) to adjust the GPU memory usage ratio.

## Voice Configuration
**IndexStreamTTS** supports registering custom voices through a configuration file, allowing both single‑voice and multi‑voice configurations.  
Edit the `assets/speaker.json` file in the project root to define your custom voices.

### Configuration Format  
```json
{
    "VoiceName1": [
        "Path/To/Audio1.wav",
        "Path/To/Audio2.wav"
    ],
    "VoiceName2": [
        "Path/To/Audio3.wav"
    ]
}
```
**Note:** After adding new voices, you must restart the service for the new voices to be registered. In the smart‑control panel, you also need to add the corresponding voice (replace the voice module accordingly).
