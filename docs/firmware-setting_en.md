# Custom Server Configuration for XiaoZhi-ESP32 Firmware 

## Step 1: Confirm Firmware Version  
Flash the xiaozhi-esp32 firmware (needs release v 1.6.1 or later). Device-specific images are available [here](https://github.com/78/xiaozhi-esp32/releases)

## Step 2: Prepare Your OTA Address  

If you are using the full‑module deployment as described in the tutorial, you should have an OTA address.  

At this point, open your OTA address in a browser, e.g. `https://2662r3426b.vicp.fun/xiaozhi/ota/`  

If the opened page shows `OTA interface is running normally, WebSocket cluster count: X` then proceed to the next step.  

If the page shows **“OTA interface is abnormal”**, it probably means you have not yet configured the WebSocket address in the **Smart Control Panel** (智控台). To fix it:

1. Log in to the Smart Control Panel with a super‑admin account.  
2. Click **Parameter Management** in the top menu.  
3. In the list, find the `server.websocket` item and enter your WebSocket address, e.g. `wss://2662r3426b.vicp.fun/xiaozhi/v1/`  

   After configuring, refresh the OTA interface address in your browser to see if it becomes normal. If it is still abnormal, double‑check that the WebSocket has started correctly and that the WebSocket address was entered properly.

## Step 3: Enter Configuration Network Mode  
Enter the device’s configuration network mode. At the top of the page, click **Advanced Options**, enter your server’s OTA address there, and click **Save**. Then restart the device.  

![OTA Address Setting](./images/firmware-setting-ota.png)

==ToDo: EN translation?== 

## Step 4: Wake Up Xiaozhi and Check Log Output  
Wake up Xiaozhi and verify that the logs are output normally.

## FAQ  
Below are some common questions for reference:

[Why does Xiaozhi recognize a lot of Korean, Japanese, and English when I speak?](./FAQ_en.md)  

[Why does it show “TTS task error: file does not exist”?](./FAQ_en.md)

[TTS often fails and often times out.](./FAQ_en.md)

[I can connect to a self‑built server via Wi‑Fi, but cannot connect in 4G mode.](./FAQ_en.md)

[How can I increase Xiaozhi’s response speed?](./FAQ_en.md)

[I speak slowly, and Xiaozhi often interrupts during pauses.](./FAQ_en.md)

[I want to control lights, air conditioners, remote power on/off, etc., through Xiaozhi.](./FAQ_en.md)
