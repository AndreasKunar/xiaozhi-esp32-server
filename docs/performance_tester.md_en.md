# Performance Tester Usage Guide  
*Speech Recognition, Large Language Model, Non‑streaming TTS, Streaming TTS, Visual Model*

1. In the `main/xiaozhi-server` directory, create a `data` folder.  
2. In the `data` directory, create a `.config.yaml` file.  
3. In `data/.config.yaml`, write the parameters for speech recognition, large language model, streaming TTS, and visual model. Example:  

   ```yaml
   LLM:
     ChatGLMLLM:
       # Define LLM API type
       type: openai
       # glm-4-flash is free, but still requires registering and filling in an API key
       # You can find your API key here: https://bigmodel.cn/usercenter/proj-mgmt/apikeys
       model_name: glm-4-flash
       url: https://open.bigmodel.cn/api/paas/v4/
       api_key: your chat-glm web key

   TTS:

   VLLM:

   ASR:
   ```

4. In the `main/xiaozhi-server` directory, run `performance_tester.py`:  

   ```bash
   python performance_tester.py
   ```
