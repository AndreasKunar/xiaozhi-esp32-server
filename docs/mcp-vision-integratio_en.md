# Visual Model Usage Guide  
This tutorial is divided into two parts:  

- **Part 1:** Running `xiaozhi-server` as a single module to enable the visual model  
- **Part 2:** Enabling the visual model when running all modules  

Before enabling the visual model, you need to prepare three things:  

- You need a device with a camera that is already in the Xiaozhi repository and implements camera functionality. Example: **`KREAT ESP32‑S3 Development Board`**  
- Your device firmware must be upgraded to version **1.6.6 or higher**  
- You have successfully run the basic conversation module  

---  

## Enabling the Visual Model with a Single Module of `xiaozhi-server`

### 1️⃣ Step 1: Confirm the Network  
Since the visual model will default to listening on **port 8003**.  

- **If you are running via Docker**, make sure your `docker-compose.yml` maps port 8003. If it does not, update it with the latest `docker-compose.yml`.  
- **If you are running from source**, confirm that the firewall allows traffic on port 8003.  

### 2️⃣ Step 2: Choose Your Visual Model  
Open your `data/.config.yaml` file and set `selected_module.VLLM` to a visual model. Currently we support visual models that use the **OpenAI‑style** interface. `ChatGLMVLLM` is one such model compatible with the OpenAI interface.  

```yaml
selected_module:
  VAD: ..
  ASR: ..
  LLM: ..
  VLLM: ChatGLMVLLM      # <-- set this to your chosen visual model
  TTS: ..
  Memory: ..
  Intent: ..
```

Assuming we use `ChatGLMVLLM` as the visual model, you first need to log in to the [Zhipu AI](https://bigmodel.cn/usercenter/proj-mgmt/apikeys) website and obtain an API key. If you already have a key, you can reuse it.  

Add the following configuration to your file; if it already exists, just fill in your `api_key`.  

```yaml
VLLM:
  ChatGLMVLLM:
    api_key: your_api_key_here
```

### 3️⃣ Step 3: Start the `xiaozhi-server` Service  

- **Running from source:**  

  ```bash
  python app.py
  ```

- **Running via Docker:**  

  ```bash
  docker restart xiaozhi-esp32-server
  ```

After starting, the logs will contain something like the following:

```
2025-06-01 **** - OTA interface is           http://192.168.4.7:8003/xiaozhi/ota/
2025-06-01 **** - Visual analysis interface is        http://192.168.4.7:8003/mcp/vision/explain
2025-06-01 **** - Websocket address is       ws://192.168.4.7:8000/xiaozhi/v1/
2025-06-01 **** - ======= The above address is a websocket protocol address, do NOT access it via a browser =======
2025-06-01 **** - To test the websocket, open test_page.html in the test directory using Google Chrome
2025-06-01 **** - =============================================================
```

#### Test the Visual Analysis Interface  
Open the **Visual analysis interface** address shown in the logs in a web browser. If you are on Linux and have no browser, you can use `curl`:

```bash
curl -i your_visual_analysis_interface
```

You should see something like:

```
MCP Vision interface is running normally, the visual explanation interface address is: http://xxxx:8003/mcp/vision/explain
```

> **Important:** If you are deploying publicly or using Docker, you must update the `server.visual_explain` entry in `data/.config.yaml` to use a reachable address.  

```yaml
server:
  vision_explain: http://your_ip_or_domain:port_number/mcp/vision/explain
```

Why? The visual explanation interface must be reachable from the device. If the address is a local‑network IP or a Docker‑internal address, the device cannot access it.

Suppose your public address is `111.111.111.111`; then configure it as:

```yaml
server:
  vision_explain: http://111.111.111.111:8003/mcp/vision/explain
```

If the MCP Vision interface runs normally and you can open the visual explanation interface address in a browser, proceed to the next step.

### 4️⃣ Step 4: Wake Up the Device  
Tell the device **“Please turn on the camera and describe what you see.”**  

Watch the logs of `xiaozhi-server` for any errors.

---  

## Enabling the Visual Model When All Modules Are Running

### 1️⃣ Step 1: Confirm the Network  
The visual model still defaults to port 8003.  

- **If you are running via Docker**, ensure your `docker-compose_all.yml` maps port 8003. If not, update it with the latest `docker-compose_all.yml`.  
- **If you are running from source**, ensure the firewall allows port 8003.  

### 2️⃣ Step 2: Verify Your Configuration File  
Open `data/.config.yaml` and ensure its structure matches `data/config_from_api.yaml`. If any fields are missing or the structure differs, add or correct them accordingly.  

### 3️⃣ Step 3: Configure the Visual Model Key  

1. Log in to the [Zhipu AI](https://bigmodel.cn/usercenter/proj-mgmt/apikeys) website and apply for an API key. If you already have one, you can reuse it.  

2. In the **Smart Control Panel**, click **“Model Configuration”** on the top menu, then select **“Visual Language Model”** in the left sidebar. Find **`VLLM_ChatGLMVLLM`**, click **“Edit”**, enter your API key in the popup, and click **“Save.”**  

3. Navigate to the agent you intend to test, click **“Configure Role,”** locate the **“Visual Large Language Model (VLLM)”** entry, confirm that it selects the visual model you just configured, and click **“Save.”**  

### 4️⃣ Step 3: Start the `xiaozhi-server` Module  

- **Running from source:**  

  ```bash
  python app.py
  ```

- **Running via Docker:**  

  ```bash
  docker restart xiaozhi-esp32-server
  ```

After starting, the logs will display:

```
2025-06-01 **** - Visual analysis interface is        http://192.168.4.7:8003/mcp/vision/explain
2025-06-01 **** - Websocket address is       ws://192.168.4.7:8000/xiaozhi/v1/
2025-06-01 **** - ======= The above address is a websocket protocol address, do NOT access it via a browser =======
2025-06-01 **** - To test the websocket, open test_page.html in the test directory using Google Chrome
2025-06-01 **** - =============================================================
```

#### Test the Visual Analysis Interface  
Open the **Visual analysis interface** address shown in the logs in a browser. If you are on Linux without a browser, you can use `curl`:

```bash
curl -i your_visual_analysis_interface
```

You should see:

```
MCP Vision interface is running normally, the visual explanation interface address is: http://xxxx:8003/mcp/vision/explain
```

> **Important:** If you are deploying publicly or using Docker, you must adjust the `server.visual_explain` entry in `data/.config.yaml` to reflect a reachable address, exactly as shown earlier:

```yaml
server:
  vision_explain: http://your_ip_or_domain:port_number/mcp/vision/explain
```

Again, the visual explanation interface must be reachable from the device; local‑network or Docker‑internal addresses will not work.

Suppose your public address is `111.111.111.111`; configure it as:

```yaml
server:
  vision_explain: http://111.111.111.111:8003/mcp/vision/explain
```

If the MCP Vision interface is running correctly and you can open the visual explanation interface address in a browser, proceed to the final step.

### 5️⃣ Step 4: Wake Up the Device  
Instruct the device **“Please turn on the camera and describe what you see.”**  

Monitor the `xiaozhi-server` logs for any errors.
