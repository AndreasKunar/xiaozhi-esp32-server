# MQTT Gateway Deployment Guide

`xiaozhi-esp32-server` project can be combined with the open‑source [xiaozhi‑mqtt‑gateway](https://github.com/78/xiaozhi-mqtt-gateway) project and slightly modified to enable MQTT + UDP connectivity for Xiaozhi hardware.  
This guide is divided into three parts; you can choose the corresponding part based on whether you are deploying the entire module or just a single module:

- **Part 1:** Deploy the MQTT gateway  
- **Part 2:** Run the full module to achieve MQTT + UDP connectivity for Xiaozhi hardware  
- **Part 3:** Run `xiaozhi-server` as a single module to achieve MQTT + UDP connectivity  

---

## Preparation Phase

Obtain the `mqtt-websocket` connection address of your `xiaozhi-server`. By appending `?from=mqtt_gateway` to your original WebSocket address, you can obtain the `mqtt-websocket` address.

1. **If you are deploying from source**, the `mqtt-websocket` address is:  
   ```
   ws://127.0.0.1:8000/xiaozhi/v1/?from=mqtt_gateway
   ```

2. **If you are deploying via Docker**, the `mqtt-websocket` address is:  
   ```
   ws://<host‑machine‑LAN‑IP>:8000/xiaozhi/v1/?from=mqtt_gateway
   ```

---

## Important Notes

If you are deploying on a server, you must ensure that ports **1883**, **8884**, and **8007** are exposed externally.  
- Port **8884** uses the **UDP** protocol.  
- Ports **1883** and **8007** use the **TCP** protocol.  

> **Note:** The above note appears three times in the original document; it has been retained once for clarity.

---

## Part 1: Deploy the MQTT Gateway

1. **Clone the modified xiaozhi‑mqtt‑gateway project**:  
   ```bash
   git clone https://ghfast.top/https://github.com/xinnan-tech/xiaozhi-mqtt-gateway.git
   cd xiaozhi-mqtt-gateway
   ```

2. **Install dependencies**:  
   ```bash
   npm install
   npm install -g pm2
   ```

3. **Configure `config.json`**:  
   ```bash
   cp config/mqtt.json.example config/mqtt.json
   ```

4. **Edit the configuration file** `config/mqtt.json` and replace the `chat_servers` entry with the `mqtt-websocket` address you obtained in the *Preparation Phase*.  
   For example, if you are using source deployment of `xiaozhi-server`, the configuration looks like this:

   ```json
   {
       "production": {
           "chat_servers": [
               "ws://127.0.0.1:8000/xiaozhi/v1/?from=mqtt_gateway"
           ]
       },
       "debug": false,
       "max_mqtt_payload_size": 8192,
       "mcp_client": {
           "capabilities": {
           },
           "client_info": {
               "name": "xiaozhi-mqtt-client",
               "version": "1.0.0"
           },
           "max_tools_count": 128
       }
   }
   ```

5. **Create a `.env` file in the project root** and set the following environment variables:  
   ```
   PUBLIC_IP=your-ip         # Server public IP (or domain)
   MQTT_PORT=1883            # MQTT server port
   UDP_PORT=8884             # UDP server port
   API_PORT=8007             # Management API port
   MQTT_SIGNATURE_KEY=test   # MQTT signature key (use a complex value)
   SERVER_SECRET=Te1st12134  # Server secret; must match server.secret in the smart‑control panel or server.auth_key in xiaozhi-server
   ```

   > **Important:**  
   > - Do **not** use simple passwords such as `123456` or `test`.  
   > - `PUBLIC_IP` must match the actual public IP; if you are using a domain, put the domain here.  
   > - `MQTT_SIGNATURE_KEY` should be at least 8 characters long and contain both uppercase and lowercase letters for better security.  
   > - `SERVER_SECRET` is used to generate WebSocket authentication information.  
   >   - If you are doing a **full‑module deployment** and have enabled `server.auth` in the smart‑control panel, `SERVER_SECRET` must match the `server.secret` in the panel.  
   >   - If you are doing a **single‑module deployment** and have enabled `server.auth` in the configuration file, `SERVER_SECRET` must match the `server.auth_key` you set there.

6. **Start the MQTT gateway**:  
   ```bash
   # Start the service
   pm2 start ecosystem.config.js

   # View logs
   pm2 logs xz-mqtt
   ```

   When you see logs similar to the following, the MQTT gateway has started successfully:  
   ```
   0|xz-mqtt  | 2025-09-11T12:14:48: MQTT server is listening on port 1883
   0|xz-mqtt  | 2025-09-11T12:14:48: UDP server is listening on x.x.x.x:8884
   ```

   To restart the MQTT gateway, run:  
   ```
   pm2 restart xz-mqtt
   ```

---

## Part 2: Run the Full Module to Achieve MQTT + UDP Connectivity

1. Check the version number displayed at the bottom of the smart‑control panel. Ensure that the version is **0.7.7** or higher; if not, upgrade the panel first.

2. In the smart‑control panel, go to **Parameter Management**, search for `server.mqtt_gateway`, and edit it. Enter `PUBLIC_IP:MQTT_PORT` from your `.env` file, e.g.:  
   ```
   192.168.0.7:1883
   ```

3. Still in **Parameter Management**, search for `server.mqtt_signature_key` and set it to the value of `MQTT_SIGNATURE_KEY` from your `.env` file.

4. Search for `server.udp_gateway` and set it to `PUBLIC_IP:UDP_PORT` from your `.env` file, e.g.:  
   ```
   192.168.0.7:8884
   ```

5. Search for `server.mqtt_manager_api` and set it to `PUBLIC_IP:UDP_PORT` from your `.env` file, e.g.:  
   ```
   192.168.0.7:8007
   ```

   After completing the above configuration, you can verify that the OTA address pushes MQTT settings using `curl`. Replace `http://localhost:8002/xiaozhi/ota/` with your actual OTA address:

   ```bash
   curl 'http://localhost:8002/xiaozhi/ota/' \
     -H 'Content-Type: application/json' \
     -H 'Client-Id: 7b94d69a-9808-4c59-9c9b-704333b38aff' \
     -H 'Device-Id: 11:22:33:44:55:66' \
     --data-raw $'{\n  "application": {\n    "version": "1.0.1",\n    "elf_sha256": "1"\n  },\n  "board": {\n    "mac": "11:22:33:44:55:66"\n  }\n}'
   ```

   If the response contains MQTT‑related configuration, the setup succeeded. Example response:

   ```json
   {
       "server_time": {
           "timestamp": 1757567894012,
           "timeZone": "Asia/Shanghai",
           "timezone_offset": 480
       },
       "activation": {
           "code": "460609",
           "message": "http://xiaozhi.server.com\n460609",
           "challenge": "11:22:33:44:55:66"
       },
       "firmware": {
           "version": "1.0.1",
           "url": "http://xiaozhi.server.com:8002/xiaozhi/otaMag/download/NOT_ACTIVATED_FIRMWARE_THIS_IS_A_INVALID_URL"
       },
       "websocket": {
           "url": "ws://192.168.4.23:8000/xiaozhi/v1/"
       },
       "mqtt": {
           "endpoint": "192.168.0.7:1883",
           "client_id": "GID_default@@@11_22_33_44_55_66@@@7b94d69a-9808-4c59-9c9b-704333b38aff",
           "username": "eyJpcCI6IjA6MDowOjA6MDowOjA6MSJ9",
           "password": "Y8XP9xcUhVIN9OmbCHT9ETBiYNE3l3Z07Wk46wV9PE8=",
           "publish_topic": "device-server",
           "subscribe_topic": "devices/p2p/11_22_33_44_55_66"
       }
   }
   ```

   Since MQTT information is delivered via the OTA address, you must ensure that the OTA address can be reached; otherwise the device cannot wake up properly. After rebooting, check the MQTT gateway logs for successful connection messages:  
   ```
   pm2 logs xz-mqtt
   ```

---

## Part 3: Run the Single‑Module Version of xiaozhi-server for MQTT + UDP Connectivity

1. Open your `data/.config.yaml` file. Under the `server` section, locate `mqtt_gateway` and set it to `PUBLIC_IP:MQTT_PORT`, e.g.:  
   ```
   192.168.0.7:1883
   ```

2. Still under `server`, find `mqtt_signature_key` and set it to the value of `MQTT_SIGNATURE_KEY` from your `.env` file.

3. Under `server`, locate `udp_gateway` and set it to `PUBLIC_IP:UDP_PORT` from your `.env` file, e.g.:  
   ```
   192.168.0.7:8884
   ```

   After these changes, you can again test the OTA address with `curl` as described in Part 2. If the response contains MQTT configuration, the setup is successful.

   Example response:

   ```json
   {
       "server_time": {
           "timestamp": 1758781561083,
           "timeZone": "GMT+08:00",
           "timezone_offset": 480
       },
       "activation": {
           "code": "527111",
           "message": "http://xiaozhi.server.com\n527111",
           "challenge": "11:22:33:44:55:66"
       },
       "firmware": {
           "version": "1.0.1",
           "url": "http://xiaozhi.server.com:8002/xiaozhi/otaMag/download/NOT_ACTIVATED_FIRMWARE_THIS_IS_A_INVALID_URL"
       },
       "websocket": {
           "url": "ws://192.168.1.15:8000/xiaozhi/v1/"
       },
       "mqtt": {
           "endpoint": "192.168.1.15:1883",
           "client_id": "GID_default@@@11_22_33_44_55_66@@@11_22_33_44_55_66",
           "username": "eyJpcCI6IjE5Mi4xNjguMS4xNSJ9",
           "password": "fjAYs49zTJecWqJ3jBt+kqxVn/x7vkXRAc85ak/va7Y=",
           "publish_topic": "device-server",
           "subscribe_topic": "devices/p2p/11_22_33_44_55_66"
       }
   }
   ```

   Again, because MQTT settings are pushed via the OTA address, you must ensure the OTA endpoint works; after rebooting, verify successful connection logs in the MQTT gateway:  
   ```
   pm2 logs xz-mqtt
   ```
