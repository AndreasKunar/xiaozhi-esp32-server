# MCP Endpoint Usage Guide

This tutorial uses the MCP calculator feature from Xiaozhi's open-source project as an example, explaining how to integrate your own MCP service into your own endpoint.

**Prerequisite:** Your `xiaozhi-server` must have MCP endpoint functionality enabled. If not, enable it first by following [this tutorial](./mcp-endpoint-enable.md).

# How to Attach an Agent to a Simple MCP Feature (e.g., Calculator)

### If You’re Using Full-Module Deployment

If you are using full-module deployment, go to the **Intelligent Agent Management** section in the smart control panel, click **Configure Role**, and then click the **Edit Function** button next to **Intent Recognition**.

Click this button. At the bottom of the opened page, you’ll see an **MCP Endpoint**. Normally, it will display the **MCP Endpoint Address** for this agent. Next, we’ll extend this agent with a calculator function based on MCP technology.

The **MCP Endpoint Address** is important; you’ll use it shortly.

### If You’re Using Single-Module Deployment

If you are using single-module deployment and have already configured the MCP Endpoint Address in your configuration file, then when the module starts, you should see logs similar to the following:

```text
250705[__main__]-INFO-初始化组件: vad成功 SileroVAD
250705[__main__]-INFO-初始化组件: asr成功 FunASRServer
250705[__main__]-INFO-OTA接口是          http://192.168.1.25:8002/xiaozhi/ota/
250705[__main__]-INFO-视觉分析接口是     http://192.168.1.25:8002/mcp/vision/explain
250705[__main__]-INFO-mcp接入点是        ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=abc
250705[__main__]-INFO-Websocket地址是    ws://192.168.1.25:8000/xiaozhi/v1/
250705[__main__]-INFO-=======上面的地址是websocket协议地址，请勿用浏览器访问=======
250705[__main__]-INFO-如想测试websocket请用谷歌浏览器打开test目录下的test_page.html
250705[__main__]-INFO-=============================================================
```
In the above logs, the line:

```text
250705[__main__]-INFO-mcp接入点是        ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=abc
```

represents your **MCP Endpoint Address**. 

or

```text
250705[__main__]-INFO-Initialize component: VAD successful SileroVAD
250705[__main__]-INFO-Initialize component: ASR successful FunASRServer
250705[__main__]-INFO-OTA interface is          http://192.168.1.25:8002/xiaozhi/ota/
250705[__main__]-INFO-Vision analysis interface is     http://192.168.1.25:8002/mcp/vision/explain
250705[__main__]-INFO-MCP endpoint is        ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=abc
250705[__main__]-INFO-WebSocket address is    ws://192.168.1.25:8000/xiaozhi/v1/
250705[__main__]-INFO-==========The above address is a WebSocket protocol address; do not access it via a browser==========
250705[__main__]-INFO-If you want to test the WebSocket, open test_page.html in the test directory using Google Chrome
250705[__main__]-INFO-=============================================================
```

The MCP Endpoint Address address is crucial for the next steps.

## Step 1: Download the Calculator Project from Xiaozhi

Open the calculator project written by Xiaozhi at https://github.com/78/mcp-calculator.

On the project page, click the green **Code** button, then select **Download ZIP**.

Download the source code archive to your computer and extract it. The extracted folder may be named something like `mcp-calculatorr-main`. Rename it to `mcp-calculator`. Then navigate into the project directory to install dependencies:

```bash
# Enter the project directory
cd mcp-calculator

conda remove -n mcp-calculator --all -y
conda create -n mcp-calculator python=3.10 -y
conda activate mcp-calculator

pip install -r requirements.txt
```

## Step 2: Start the Service

Before starting, copy the MCP Endpoint address from your agent in the smart control panel. For example, if your agent’s MCP address is:

```text
ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=abc
```

Set the environment variable:

```bash
export MCP_ENDPOINT=ws://192.168.1.25:8004/mcp_endpoint/mcp/?token=abc
```

Then start the service:

```bash
python mcp_pipe.py calculator.py
```

### If You Are Using Full-Module Deployment

After starting, return to the smart control panel, refresh the MCP connection status, and you should see the newly added functionality listed.

### If You Are Using Single-Module Deployment

When the device connects, you’ll see logs similar to the following indicating success:

```text
250705 -INFO-正在初始化MCP接入点: wss://2662r3426b.vicp.fun/mcp_e 
250705 -INFO-发送MCP接入点初始化消息
250705 -INFO-MCP接入点连接成功
250705 -INFO-MCP接入点初始化成功
250705 -INFO-统一工具处理器初始化完成
250705 -INFO-MCP接入点服务器信息: name=Calculator, version=1.9.4
250705 -INFO-MCP接入点支持的工具数量: 1
250705 -INFO-所有MCP接入点工具已获取，客户端准备就绪
250705 -INFO-工具缓存已刷新
250705 -INFO-当前支持的函数列表: [ 'get_time', 'get_lunar', 'play_music', 'get_weather', 'handle_exit_intent', 'calculator']
```

or

```text
250705 -INFO-Initializing MCP endpoint: wss://2662r3426b.vicp.fun/mcp_e 
250705 -INFO-Sending MCP endpoint initialization message
250705 -INFO-MCP endpoint connection successful
250705 -INFO-MCP endpoint initialization successful
250705 -INFO-Unified tool processor initialization completed
250705 -INFO-MCP endpoint server info: name=Calculator, version=1.9.4
250705 -INFO-Number of tools supported by MCP endpoint: 1
250705 -INFO-All MCP endpoint tools have been retrieved, client is ready
250705 -INFO-Tool cache has been refreshed
250705 -INFO-Current supported functions list: [ 'get_time', 'get_lunar', 'play_music', 'get_weather', 'handle_exit_intent', 'calculator']
```

If the list includes `'calculator'`, the device will be able to invoke the calculator tool based on intent recognition.