# ESP32 Firmware Compilation  

## Step 1: Prepare Your OTA Address  

If you are using version **0.3.12** or later of this project, regardless of whether you deploy a simple server or a full‑module version, there will be an OTA address.

Because the OTA address setup differs between simple server deployment and full‑module deployment, please choose the appropriate method below:

### If You Are Using Simple Server Deployment 
 
At this point, open your OTA address in a browser, e.g. `http://192.168.1.25:8003/xiaozhi/ota/`  

If you see **“OTA interface is running normally; the WebSocket address sent to the device is: ws://xxx:8000/xiaozhi/v1/**”, you can use the project’s built‑in `test_page.html` to test whether it can connect to the OTA page and output WebSocket address.

If you cannot access it, you need to modify the address in the configuration file `.config.yaml` under `server.websocket`, restart, and test again until `test_page.html` can be accessed normally.

After the test succeeds, proceed to **Step 2**.

### If You Are Using Full‑Module Deployment  

At this point, open your OTA address in a browser, e.g. `http://192.168.1.25:8003/xiaozhi/ota/`  

If you see `OTA interface is running normally, WebSocket cluster count: X`, you can continue to Step 2.

If you see **“OTA interface is abnormal”**, it is likely because you have not yet configured the **WebSocket** address in the **Smart Control Panel** (`智控台`). Then:

1. Log in to the Smart Control Panel with a super‑admin account.  
2. Click the top‑menu **“Parameter Management”** (`参数管理`).  
3. In the list, locate the `server.websocket` item and enter your WebSocket address, e.g. `ws://192.168.1.25:8000/xiaozhi/v1/`  

After configuring, refresh your OTA interface address in the browser to see if it becomes normal. If it is still abnormal, double‑check whether the WebSocket has started correctly and whether the WebSocket address has been configured.

## Step 2: Configure the Environment  

Set up the project environment according to[Windows搭建 ESP IDF 5.3.2开发环境以及编译小智](https://icnynnzcwou8.feishu.cn/wiki/JEYDwTTALi5s2zkGlFGcDiRknXf) (Windows setup of ESP IDF 5.3.2 development environment and compilation of Xiaozhi).
==ToDo EN Version!==

## Step 3: Open the Configuration File  

After the environment is ready, download the **xiaozhi‑esp32** source code from [https://github.com/78/xiaozhi-esp32](https://github.com/78/xiaozhi-esp32).  

Open the file `xiaozhi-esp32/main/Kconfig.projbuild`.

## Step 4: Modify the OTA URL  

Find the `default` value of `OTA_URL` and replace the original `https://api.tenclass.net/xiaozhi/ota/` with your own address, e.g. `http://192.168.1.25:8002/xiaozhi/ota/`.

**Before modification:**

```text
config OTA_URL
    string "Default OTA URL"
    default "https://api.tenclass.net/xiaozhi/ota/"
    help
        The application will access this URL to check for new firmwares and server address.
```

**After modification, e.g.:**

```text
config OTA_URL
    string "Default OTA URL"
    default "http://192.168.1.25:8002/xiaozhi/ota/"
    help
        The application will access this URL to check for new firmwares and server address.
```

## Step 5: Set the Build Target  

Set the build target:

```bash
# Enter the root directory of the xiaozhi-esp32 project in the terminal
cd xiaozhi-esp32

# For example, if you are using an esp32s3 board, set the target to esp32s3.
# If your board model is different, replace it with the corresponding model.
idf.py set-target esp32s3

# Enter the menu configuration interface
idf.py menuconfig
```

In the menu configuration, navigate to **“Xiaozhi Assistant”** (`Xiaozhi Assistant`) and set `BOARD_TYPE` to the specific model of your board. Save and exit, then return to the terminal.

## Step 6: Build the Firmware  

```bash
idf.py build
```

## Step 7: Package the Binary  

```bash
cd scripts
python release.py
```

After executing the above command, the compiled binary `merged-binary.bin` will be placed in the project’s root `build` directory. This `merged-binary.bin` is the firmware file you need to flash to the hardware.

> **Note:** If the `release.py` script reports an error related to `zip`, you can ignore the error. As long as the `build` directory contains the `merged-binary.bin` file, you can continue.

## Step 8: Flash the Firmware  

1. Connect your ESP32 device to the computer.  
2. Open Chrome and go to `https://espressif.github.io/esp-launchpad/`. This opens the **Flash tool / Web‑based flashing (no IDF development environment required)** documentation.
3. Follow the instructions under **“Method 2: Flash via ESP‑Launchpad Web UI”** starting from step 3 **“Flash Firmware / Download to Device”**.

After flashing succeeds and the device connects to the network, wake up Xiaozhi with the wake word and monitor the server console output.

## Common Issues  

Below is a list of frequently asked questions for reference:

1. [Why does Xiaozhi recognize many Korean, Japanese, and English words when I speak?](./FAQ_en.md)  
2. [Why does it report “TTS task failed, file does not exist”?](./FAQ_en.md)  
3. [TTS frequently fails and often times out.](./FAQ_en.md)  
4. [Can I connect to a self‑hosted server via Wi‑Fi, but not via 4G?](./FAQ_en.md)  
5. [How can I improve Xiaozhi’s response speed?](./FAQ_en.md)  
6. [I speak slowly; Xiaozhi often interrupts me.](./FAQ_en.md)  
7. [How can I control lights, air‑conditioners, remote power‑on/off, etc., via Xiaozhi?](./FAQ_en.md)  
