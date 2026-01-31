# Context Provider Usage Guide

## Overview

A **context source** is a way to add a **[data source]** to the context of XiaoZhi’s prompt.  
When XiaoZhi wakes up, it retrieves external system data and dynamically injects it into the system prompt (the “System Prompt”). This allows XiaoZhi to perceive the state of something in the world.

It is fundamentally different from **MCP** and **memory**:

- **Context source** forces XiaoZhi to sense the state of the external world.  
- **Memory (Mem)** lets XiaoZhi know what has been discussed previously.  
- **MCP (function call)** is used when XiaoZhi needs to invoke a specific capability or piece of knowledge.

Through this functionality, at the moment XiaoZhi wakes up it “perceives”:

- Human‑health sensor status (body temperature, blood pressure, blood‑oxygen, etc.)  
- Real‑time business system data (server load, pending tasks, stock information, etc.)  
- Any textual information that can be accessed via an HTTP API  

**Note:** This feature only helps XiaoZhi sense the state of things at wake‑up time. If you need XiaoZhi to obtain real‑time state continuously after waking, you should combine this feature with an MCP tool call.

## Working Principle

1. **Configure the source** – Users configure one or more HTTP API addresses.  
2. **Trigger the request** – When the system builds a prompt, if a template contains the placeholder `{{ dynamic_context }}`, it sends requests to all configured APIs.  
3. **Automatic injection** – The system automatically formats the API response as a Markdown list and replaces the `{{ dynamic_context }}` placeholder with the formatted data.

## API Specification

To ensure XiaoZhi can parse the data correctly, your API must meet the following requirements:

- **Request method:** `GET`  
- **Request headers:** The system automatically adds a `device-id` field to the request header.  
- **Response format:** Must return JSON containing `code` and `data` fields.

### Response Example

#### Case 1: Returning key‑value pairs
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "Living room temperature": "26°C",
    "Living room humidity": "45%",
    "Front door status": "Closed"
  }
}
```
*Injected effect:*
```markdown
<context>
- **Living room temperature:** 26°C
- **Living room humidity:** 45%
- **Front door status:** Closed
</context>
```

#### Case 2: Returning a list
```json
{
  "code": 0,
  "data": [
    "You have 10 pending tasks",
    "The current speed of the car is 100 km per hour"
  ]
}
```
*Injected effect:*
```markdown
<context>
- You have 10 pending tasks
- The current speed of the car is 100 km per hour
</context>
```

## Configuration Guide

### Method 1: Configuring via the Control Panel (for full‑module deployment)

1. Log in to the control panel and navigate to the **Role Configuration** page.  
2. Locate the **Context Source** configuration item (click the “Edit Source” button).  
3. Click **Add**, and enter your API address.  
4. If the API requires authentication, you can add `Authorization` or other headers in the **Headers** section.  
5. Save the configuration.

### Method 2: Configuring via a config file (for single‑module deployment)

Edit the file `xiaozhi-server/data/.config.yaml` and add the `context_providers` section:

```yaml
# Context source configuration
context_providers:
  - url: "http://api.example.com/data"
    headers:
      Authorization: "Bearer your-token"
  - url: "http://another-api.com/data"
```

## Enabling the Feature

By default, the system’s prompt template file (`data/.agent-base-prompt.txt`) already includes the `{{ dynamic_context }}` placeholder, so you do **not** need to add it manually.

**Example:**

```markdown
<context>
【Important! The following information is provided in real‑time and does not require tool calls; please use it directly:】
- **Device ID:** {{device_id}}
- **Current time:** {{current_time}}
...
{{ dynamic_context }}
</context>
```

**Note:** If you do not want to use this feature, you can either **not configure any context sources** or **remove the `{{ dynamic_context }}` placeholder** from the prompt template file.

## Appendix: Mock Test Service Example

To simplify testing and development, we provide a simple Python mock server script. Run this script locally to simulate the API endpoints.

**mock_api_server.py**

```python
import http.server
import socketserver
import json
from urllib.parse import urlparse, parse_qs

# Set the port number
PORT = 8081

class MockRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Parse path and query
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        query = parse_qs(parsed_path.query)

        response_data = {}
        status_code = 200

        print(f"Received request: {path}, parameters: {query}")

        # Case 1: Simulate health data (returns a dict)
        # Path style: /health
        # device_id is taken from the Header
        if path == "/health":
            device_id = self.headers.get("device-id", "unknown_device")
            print(f"device_id: {device_id}")
            response_data = {
                "code": 0,
                "msg": "success",
                "data": {
                    "Test device ID": device_id,
                    "Heart rate": "80 bpm",
                    "Blood pressure": "120/80 mmHg",
                    "Status": "Good"
                }
            }

        # Case 2: Simulate a news list (returns a list)
        # No parameters: /news/list
        elif path == "/news/list":
            response_data = {
                "code": 0,
                "msg": "success",
                "data": [
                    "Today's headline: Python 3.14 is released",
                    "Tech news: AI assistants are changing life",
                    "Local news: Heavy rain tomorrow, remember to bring an umbrella"
                ]
            }

        # Case 3: Simulate a simple weather brief (returns a string)
        # No parameters: /weather/simple
        elif path == "/weather/simple":
            response_data = {
                "code": 0,
                "msg": "success",
                "data": "Today is sunny turning to cloudy, temperature 20-25°C, air quality is excellent, suitable for outings."
            }

        # Case 4: Simulate device details (query‑style parameters)
        # Parameter style: /device/info
        # device_id is taken from Header
        elif path == "/device/info":
            device_id = self.headers.get("device-id", "unknown_device")
            response_data = {
                "code": 0,
                "msg": "success",
                "data": {
                    "Query method": "Header parameter",
                    "Device ID": device_id,
                    "Battery level": "85%",
                    "Firmware": "v2.0.1"
                }
            }
        
        # Case 5: 404 Not Found
        else:
            status_code = 404
            response_data = {"error": "Endpoint does not exist"}

        # Send response
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json; charset=utf-8')
        self.end_headers()
        self.wfile.write(json.dumps(response_data, ensure_ascii=False).encode('utf-8'))

# Start the server
# Allow address reuse to avoid errors on quick restarts
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("", PORT), MockRequestHandler) as httpd:
    print(f"==================================================")
    print(f"Mock API Server started: http://localhost:{PORT}")
    print(f"Available endpoints:")
    print(f"1. [Dict] http://localhost:{PORT}/health")
    print(f"2. [List] http://localhost:{PORT}/news/list")
    print(f"3. [Text] http://localhost:{PORT}/weather/simple")
    print(f"4. [Param] http://localhost:{PORT}/device/info")
    print(f"==================================================")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped")
```

