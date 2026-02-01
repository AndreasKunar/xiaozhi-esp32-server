# MCP Endpoint Deployment & Configuration Guide  

This tutorial contains three parts:  
1️. How to deploy the MCP endpoint service  
2️. How to configure the MCP endpoint when deploying all modules  
3. How to configure the MCP endpoint when deploying a single module  

---  

## 1️. How to Deploy the MCP Endpoint Service  

### Step 1: Download the MCP Endpoint Project Source Code  

Open the project URL in your browser: **[MCP Endpoint Project](https://github.com/xinnan-tech/mcp-endpoint-server)**  

On the page you will see a green button labeled **`Code`**. Click it and you will see a **`Download ZIP`** button.  

Click **`Download ZIP`** to download the source‑code archive. After downloading, unzip it on your computer. The folder may be named something like `mcp-endpoint-server-main`. Rename it to **`mcp-endpoint-server`**.  

### Step 2: Start the Service  

The project is simple and can be run with Docker. If you prefer not to use Docker, see the README for alternative instructions:  
[Run from source](https://github.com/xinnan-tech/mcp-endpoint-server/blob/main/README_dev.md)  

**Docker deployment steps:**  

```bash
# 1. Enter the project root directory
cd mcp-endpoint-server

# 2. Clean up previous containers/images
docker compose -f docker-compose.yml down
docker stop mcp-endpoint-server
docker rm mcp-endpoint-server
docker rmi ghcr.nju.edu.cn/xinnan-tech/mcp-endpoint-server:latest

# 3. Start the Docker container
docker compose -f docker-compose.yml up -d

# 4. View the logs
docker logs -f mcp-endpoint-server
```

When the container starts, the logs will contain something similar to:  

```
250705 INFO-=====The following addresses are the MCP endpoint addresses for the control panel / single‑module MCP=====
250705 INFO- Control panel MCP configuration: http://172.22.0.2:8004/mcp_endpoint/health?key=abc
250705 INFO- Single‑module MCP endpoint: ws://172.22.0.2:8004/mcp_endpoint/mcp/?token=def
250705 INFO-=====Please choose the appropriate one based on your deployment, and do NOT share these URLs with anyone======
```

⚠️ **Important:** Because you are using Docker, **do not** use the addresses shown above directly. Replace `172.22.0.2` with the IP address of your own machine on the local network (e.g., `192.168.1.25`).  

So the example addresses:  

```
Control panel MCP configuration: http://172.22.0.2:8004/mcp_endpoint/health?key=abc
Single‑module MCP endpoint: ws://172.22.0.2:8004/mcp_endpoint/mcp/?token=def
```

Should become:  

```
Control panel MCP configuration: http://192.168.1.25:8004/mcp_endpoint/health?key=abc
Single‑module MCP endpoint: ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=def
```

Copy these two endpoint URLs and keep them in a draft for later use.  

### Verify the URLs  

Open a browser and navigate to the **Control panel MCP configuration** address you just customized. If you see output similar to the following, the endpoint is working:  

```json
{
  "result": {
    "status": "success",
    "connections": {
      "tool_connections": 0,
      "robot_connections": 0,
      "total_connections": 0
    }
  },
  "error": null,
  "id": null,
  "jsonrpc": "2.0"
}
```

Keep the two endpoint URLs handy; you’ll need them for the next steps.  

---  

## 2️. Configuring the MCP Endpoint for Full‑Module Deployments  

1. **Enable the MCP Endpoint feature**  
   - In the control panel, click **`Parameter Dictionary`** → select **`System Feature Configuration`** from the dropdown.  
   - Check the **`MCP Endpoint`** option and click **`Save Configuration`**.  
   - On the **`Role Configuration`** page, click **`Edit Function`** to see the **`mcp endpoint`** feature listed.  

2. **Set the parameter value**  
   - Log in to the control panel with an admin account.  
   - Navigate to **`Parameter Dictionary`** → **`Parameter Management`**.  
   - Search for the parameter **`server.mcp_endpoint`**. Its current value should be `null`.  
   - Click **`Edit`**, paste the **Control panel MCP configuration** URL you obtained earlier into the **`Parameter Value`** field, and **Save**.  

If the save succeeds, the configuration is complete and you can test it via the agent view. If it fails, the control panel likely cannot reach the MCP endpoint—common causes are a firewall or an incorrect local IP address.  

---  

## 3️. Configuring the MCP Endpoint for Single‑Module Deployments  

1. **Locate the configuration file**  
   - Find your configuration file at `data/.config.yaml`.  
   - Search for `mcp_endpoint`. If it does not exist, add it.  

2. **Add / modify the `mcp_endpoint` entry**  

   Example (replace placeholders with your actual values):  

   ```yaml
   server:
     websocket: ws://your-ip-or-domain:port/xiaozhi/v1/
     http_port: 8002
     log:
       log_level: INFO

   # ... other configurations ...

   mcp_endpoint: ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=def   # <-- paste the single‑module endpoint URL here
   ```

3. **Start the single‑module service**  

   After editing, when you start the service you should see logs similar to:  

   ```
   250705[__main__]-INFO-Initializing component: vad successfully (SileroVAD)
   250705[__main__]-INFO-Initializing component: asr successfully (FunASRServer)
   250705[__main__]-INFO-OTA interface: http://192.168.1.25:8002/xiaozhi/ota/
   250705[__main__]-INFO-Visual analysis interface: http://192.168.1.25:8002/mcp/vision/explain
   250705[__main__]-INFO-MCP endpoint: ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=abc
   250705[__main__]-INFO-Websocket address: ws://192.168.1.25:8000/xiaozhi/v1/
   250705[__main__]-INFO-=======The above address is a WebSocket URL; do NOT open it in a browser=======
   250705[__main__]-INFO-If you want to test the WebSocket, open test_page.html in the test directory with Google Chrome
   250705[__main__]-INFO-=============================================================
   ```

   The line `mcp_endpoint: ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=abc` confirms that the endpoint has been correctly configured.  

---  

### Quick Recap  

| Deployment Type | Where to Configure | URL to Use |
|-----------------|-------------------|------------|
| **Full‑module** | Control panel → Parameter Management → `server.mcp_endpoint` | `http://<your‑LAN‑IP>:8004/mcp_endpoint/health?key=abc` |
| **Single‑module** | `data/.config.yaml` → `mcp_endpoint` field | `ws://<your‑LAN‑IP>:8004/mcp_endpoint/mcp/?token=def` |

After completing the appropriate steps, your MCP endpoint will be ready for use.  
