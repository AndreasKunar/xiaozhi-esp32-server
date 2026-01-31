# XiaoZhi ESP32‑Open‑Source Server & HomeAssistant Integration Guide

[Table of Contents]

---

## Introduction

This document will guide you on how to integrate an ESP32 device with HomeAssistant.

## Prerequisites

- You have already installed and configured **HomeAssistant**.
- The model I chose is the **free ChatGLM**, which supports function‑call operations.

## Pre‑Setup Steps (Required)

### 1. Obtain HomeAssistant Network Information

Visit your HomeAssistant address. For example, if my HA address is `192.168.4.7` and the default port is `8123`, open it in a browser:

```
http://192.168.4.7:8123
```

> **How to manually query the HA IP address** (only applicable when **XiaoZhi ESP32 Server** and **HA are deployed on the same network device**, e.g., the same Wi‑Fi):
> 1. Open **Home Assistant** in the frontend.
> 2. Click the **gear icon (Settings)** in the lower‑left corner → **System** → **Network**.
> 3. Scroll to the bottom of the page where the **“Home Assistant website (Home Assistant website)”** section appears. In the **“Local network”** area, click the **eye icon** to view the current IP address (e.g., `192.168.1.10`) and network interface. You can also click **“Copy link”** to copy the URL directly.
>   
>    ![image-20250504051716417](images/image-ha-integration-01.png)

> Alternatively, if you have already set up a direct OAuth address for HomeAssistant, you can also access it directly via the browser:
> 
> ```
> http://homeassistant.local:8123
> ```

### 2. Log into HomeAssistant and Retrieve the API Key

1. Log into **HomeAssistant**.
2. Click the **avatar in the lower‑left corner** → **Personal** → switch to the **Security** tab.
3. Scroll to the bottom of the **Long‑Lived Access Token** section, generate an API key, and copy it for later use (note: this key appears only once).  
   *Tip: You can save the generated QR code image and later scan it to extract the API key.*

## Method 1: XiaoZhi Community‑Built HomeAssistant Integration Functionality

### Feature Description

- When you later add new devices, this method requires you to **restart the `xiaozhi-esp32-server` service** to update the device list (**important**).
- You must ensure that **Xiaomi Home** has been integrated in HomeAssistant and that the Mi home devices have been imported.
- You must ensure that the **XiaoZhi Smart Control Panel** (`xiaozhi-esp32-server`) works properly.
- My **XiaoZhi ESP32 Server Control Panel** and **HomeAssistant** are deployed on the same machine but on a different port, version `0.3.10`:

```
http://192.168.4.7:8002
```

### Configuration Steps

#### 1. Compile a List of Devices to Control in HomeAssistant

1. Log into HomeAssistant and click the **gear icon (Settings)** → **Devices & Services** → **Entities**.
2. Search for the switches you intend to control. Once the entities appear in the list, click on one of them to view its details.
3. In the switch panel, locate the **“Configure”** button and click it to view the entity’s identifier.
4. Open a text editor and record the information in the following format:  

   `Location,Device Name,Entity Identifier;`
   
   Example: If I have a toy lamp with the identifier `switch.cuco_cn_460494544_cp1_on_p_2_1`, the entry would be:

   ```
   Company, Toy Lamp, switch.cuco_cn_460494544_cp1_on_p_2_1;
   ```

   If I need to control two lights, the final list looks like:

   ```
   Company, Toy Lamp, switch.cuco_cn_460494544_cp1_on_p_2_1;
   Company, Desk Lamp, switch.iot_cn_831898993_socn1_on_p_2_1;
   ```

   This collection of entries is called a **“device list string”** and should be saved for later use.

#### 2. Log into the Smart Control Panel

![image-20250504051716417](images/image-ha-integration-06.png)

1. Use an admin account to log into the **Smart Control Panel**.
2. Navigate to **Intelligent Body Management**, find your intelligent body, and click **Configure Role**.
3. Set the **Intent Recognition** mode to **External LLM Intent Recognition** or **Large Model Autonomous Function Call**.
4. After selection, a right‑hand **Edit Function** button appears. Click it to open the **Function Management** dialog.
5. In the **Function Management** dialog, check the following features:
   - **HomeAssistant Device State Query**
   - **HomeAssistant Device State Modification**
6. After checking, click on **HomeAssistant Device State Query** under **Selected Functions**, then configure the following parameters in the **Parameter Configuration** area:
   - HomeAssistant address
   - API key
   - Device list string
7. Click **Save Configuration**; the dialog will close. Then click **Save Configuration** for the intelligent body.
8. At this point, you can wake the device to perform control actions.

#### 3. Wake the Device for Control

Try saying to the ESP32, “**Turn on XXX light**” (replace `XXX` with the desired device name).

---

## Method 2: Using HomeAssistant as the LLM Tool for XiaoZhi

### Feature Description

- This method has a significant drawback: **it cannot use XiaoZhi’s open‑source function‑call plugin**, because the intent‑recognition capability is handed over to HomeAssistant.  
- However, **it allows you to experience native HomeAssistant operations**, while XiaoZhi’s chat capability remains unchanged.  
- If this limitation is a concern, you may instead use **Method 3** (see below), which more fully leverages XiaoZhi’s function‑call capabilities.

### Configuration Steps

#### 1. Configure HomeAssistant’s LLM Voice Assistant

- **Prerequisite:** You must have already configured a voice assistant or LLM tool within HomeAssistant.

#### 2. Obtain the Agent ID of the HomeAssistant Assistant

1. Open the **Developer Tools** in HomeAssistant.
2. Switch to the **Actions** tab (refer to Illustration 1).
3. In the **Actions** pane, locate or type `conversation.process (process conversation)` and select **Conversation → process**.
   
   ![image-20250504043539343](images/image-ha-integration-02.png)

4. Enable the **Proxy (agent)** option, and in the now‑enabled **Conversation Agent** field, select the voice assistant you configured in step 1 (e.g., `ZhipuAi`).  
   ![image-20250504043854760](images/image-ha-integration-03.png)

5. Click **Enter YAML mode**.
6. Copy the **agent‑id** value (e.g., `01JP2DYMBDF7F4ZA2DMCF2AGX2` as shown in Illustration 5).  
   ![image-20250504044046466](images/image-ha-integration-05.png)

#### 3. Edit the XiaoZhi Server Configuration

1. Open the `config.yaml` file of the XiaoZhi ESP32 server.
2. In the LLM configuration section, set:
   - HomeAssistant network address
   - API key
   - The agent‑id obtained in step 2.
3. Change the `selected_module` attribute’s `LLM` to `HomeAssistant` and set `Intent` to `nointent`.
4. Restart the XiaoZhi ESP32 server to apply the changes.

---

## Method 3: Using HomeAssistant’s MCP Service (Recommended)

### Feature Description

- This method requires you to **first install and integrate the HomeAssistant MCP integration** (`Model Context Protocol Server`) into HomeAssistant.
- Like Method 2, it is an official HomeAssistant solution, but it **allows you to continue using XiaoZhi’s open‑source plugins** while still being able to use any function‑call‑capable LLM.
- It provides the most complete experience of HomeAssistant functionality.

### Configuration Steps

#### 1. Install the MCP Server Integration in HomeAssistant

- Official documentation: **[Model Context Protocol Server](https://www.home-assistant.io/integrations/mcp_server/)**.
- Manual steps:
  1. Go to **Settings → Devices & Services** in HomeAssistant.
  2. Click **Add Integration** in the lower‑right corner.
  3. Select **Model Context Protocol Server** from the list.
  4. Follow the on‑screen instructions to complete the setup.

#### 2. Configure XiaoZhi Server’s MCP Settings

1. Navigate to the `data` directory of XiaoZhi‑ESP32‑Server and locate the file `.mcp_server_settings.json`.  
   - If the file does not exist, copy the `mcp_server_settings.json` from the root of the XiaoZhi server folder into `data` and rename it to `.mcp_server_settings.json`, **or** download it from the repository and place it in `data`, renaming it appropriately.
2. Edit the `"mcpServers"` section and add/ modify the entry for HomeAssistant:

```json
"mcpServers": {
    "Home Assistant": {
      "command": "mcp-proxy",
      "args": [
        "http://YOUR_HA_HOST/mcp_server/sse"
      ],
      "env": {
        "API_ACCESS_TOKEN": "YOUR_API_ACCESS_TOKEN"
      }
    }
  }
```

- **Replace the placeholders**:
  - In `args`, replace `YOUR_HA_HOST` with your HA server address. If the address already includes the scheme/port (e.g., `http://192.168.1.101:8123`), you may simply provide `192.168.1.101:8123`.
  - Replace `YOUR_API_ACCESS_TOKEN` with the API key you generated earlier.
- **Important:** If you are adding a new entry after existing ones, **remove the trailing comma** after the closing brace of the previous entry to avoid JSON parsing errors.

**Example completed configuration:**

```json
"mcpServers": {
    "Home Assistant": {
      "command": "mcp-proxy",
      "args": [
        "http://192.168.1.101:8123/mcp_server/sse"
      ],
      "env": {
        "API_ACCESS_TOKEN": "abcd.efghi.jkl"
      }
    }
  }
```

#### 3. Configure XiaoZhi Server’s System Settings

1. **Select any LLM that supports function calls** as the LLM for XiaoZhi (do **not** select HomeAssistant as the LLM).  
   - I chose the free **ChatGLM**, which supports function calls, though it can be unstable at times. For higher stability, consider using **DoubaoLLM** with model name `doubao-1-5-pro-32k-250115`.
2. Open `config.yaml` of the XiaoZhi ESP32 server and configure the LLM settings accordingly.
3. Set `selected_module` → `Intent` to `function_call`.
4. Restart the XiaoZhi ESP32 server to finalize the configuration.
