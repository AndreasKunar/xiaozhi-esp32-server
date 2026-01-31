# Single-Module Deployment Firmware OTA Automatic Upgrade Configuration Guide

This tutorial will guide you on how to configure **automatic firmware OTA upgrades** in a **single-module deployment** scenario, enabling devices to update their firmware automatically.

> If you are already using **full-module deployment**, please ignore this guide.

## Feature Overview

In a single-module deployment, **xiaozhi-server** comes with built-in OTA firmware management capabilities that can automatically detect device versions and push upgrade firmware. The system automatically matches and pushes the latest firmware version based on the device model and current version.

## Prerequisites

- You have successfully completed a **single-module deployment** and are running **xiaozhi-server**
- The device is able to connect to the server normally

## Step 1: Prepare Firmware Files

### 1. Create Firmware Storage Directory

Firmware files need to be placed in the `data/bin/` directory. If this directory does not exist, create it manually:

```bash
mkdir -p data/bin
```

### 2. Firmware File Naming Rules

Firmware files must follow this naming pattern:

```
{device_model}_{version}.bin
```

**Naming Rules Explained:**
- `device_model`: The name of the device model, e.g., `lichuang-dev`, `bread-compact-wifi`, etc.
- `version`: The firmware version, which must start with a digit and can contain digits, letters, dots, underscores, and hyphens, e.g., `1.6.6`, `2.0.0`, etc.
- The file extension must be `.bin`

**Naming Examples:**
```
bread-compact-wifi_1.6.6.bin
lichuang-dev_2.0.0.bin
```

### 3. Place Firmware Files

Copy the prepared firmware files (`.bin`) into the `data/bin/` directory:

> **Important:** The upgrade binary file is **`xiaozhi.bin`**, **not** the full firmware file **`merged-binary.bin`!**  
> **Important:** The upgrade binary file is **`xiaozhi.bin`**, **not** the full firmware file **`merged-binary.bin`!**  
> **Important:** The upgrade binary file is **`xiaozhi.bin`**, **not** the full firmware file **`merged-binary.bin`!**

```bash
cp xiaozhi.bin data/bin/{device_model}_{version}.bin
```

For example:

```bash
cp xiaozhi.bin data/bin/bread-compact-wifi_1.6.6.bin
```

## Step 2: Configure Public Network Access Address (Only Needed for Public Network Deployments)

**Note:** This step applies only when you have deployed **xiaozhi-server** on the public network using a public IP or domain name.

If your deployment is on a LAN, you can skip this step.

### Why Configure This Parameter?

In single-module deployments, the OTA firmware download URL is generated using the `vision_explain` setting from the configuration. If this parameter is not configured or is incorrect, devices will be unable to reach the firmware download URL.

### How to Configure

Open `data/.config.yaml` and locate the `server` section. Set the `vision_explain` parameter as follows:

```yaml
server:
  vision_explain: http://your-domain-or-ip:port/mcp/vision/explain
```

**Configuration Examples:**

- **LAN Deployment (default):**
  ```yaml
  server:
    vision_explain: http://192.168.1.100:8003/mcp/vision/explain
  ```

- **Public Domain Deployment:**
  ```yaml
  server:
    vision_explain: http://yourdomain.com:8003/mcp/vision/explain
  ```

### Important Notes

- The domain or IP must be reachable by the device.
- If you are using Docker, **do not** use internal addresses such as `127.0.0.1` or `localhost`.
- If you are using an Nginx reverse proxy, specify the external address and port, **not** the port on which the project itself runs.

## Common Issues

### 1. Device Does Not Receive Firmware Updates

**Possible Causes and Solutions:**

- Check that the firmware filename follows the required pattern: `{model}_{version}.bin`
- Verify that the firmware file is correctly placed in the `data/bin/` directory
- Ensure the device model matches the model part of the firmware filename
- Confirm that the firmware version is newer than the version currently running on the device
- Review server logs to confirm that OTA requests are processed correctly

### 2. Device Reports Download URL Unreachable

**Possible Causes and Solutions:**

- Verify that the domain or IP configured in `server.vision_explain` is correct
- Ensure the port number is properly configured (default is `8003`)
- If using a public network deployment, confirm the device can reach the public address
- If using Docker, ensure you are not using an internal address (`127.0.0.1`)
- Check that the firewall allows traffic on the configured port
- If you are using an Nginx reverse proxy, use the external address and port, not the internal project port

### 3. How to Confirm the Device's Current Version

Check the OTA request logs; the log will display the version reported by the device:

```log
[ota_handler] - 设备 AA:BB:CC:DD:EE:FF 固件已是最新: 1.6.6
```

### 4. Firmware File Placement Has No Effect

The system caches firmware files for **30 seconds** by default. You can:

- Wait 30 seconds before having the device request OTA again
- Restart the `xiaozhi-server` service
- Adjust the `firmware_cache_ttl` configuration to a shorter interval
