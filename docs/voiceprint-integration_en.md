# Voiceprint Identification Enable Guide

This tutorial contains three sections  
- 1. How to deploy the voiceprint service  
- 2. How to configure the voiceprint interface when deploying all modules  
- 3. How to configure voiceprint in the simplest deployment  

---

## 1. How to Deploy the Voiceprint Service

### Step 1: Download the Voiceprint Project Source Code  

Open the browser and go to [the Voiceprint project address](https://github.com/xinnan-tech/voiceprint-api).  
On the page you will see a green **Code** button; click it and then you will see a **Download ZIP** button.  

Click it to download the project archive to your computer. After decompression, the file may be named `voiceprint-api-main`.  
Rename it to `voiceprint-api`.

### Step 2: Create a Database and Table  

The voiceprint service depends on a MySQL database. If you have already deployed **智控台** (Zhilian Platform), you likely already have MySQL installed and can reuse it.

You can test whether the MySQL port 3306 is accessible on the host by running:

```bash
telnet 127.0.0.1 3306
```

* If you can connect, skip the following content and proceed to Step 3.  
* If you cannot connect, recall how MySQL was installed.

* If MySQL was installed by yourself using an installer package, it may have network isolation. You will need to resolve the issue of accessing port 3306 first.

* If MySQL was installed via the `docker-compose_all.yml` file in this project, locate the `docker-compose_all.yml` you used to create the database and modify the following part:

```yaml
  xiaozhi-esp32-server-db:
    ...
    networks:
      - default
    expose:
      - "3306:3306"
```

Change it to:

```yaml
  xiaozhi-esp32-server-db:
    ...
    networks:
      - default
    ports:
      - "3306:3306"
```

*Note: replace `expose` with `ports` under the `xiaozhi-esp32-server-db` service.*  
After modifying, restart MySQL:

```bash
# Navigate to the directory containing docker-compose_all.yml, e.g., my path is xiaozhi-server
cd xiaozhi-server
docker compose -f docker-compose_all.yml down
docker compose -f docker-compose.yml up -d
```

Then test the connection again:

```bash
telnet 127.0.0.1 3306
```

You should now be able to access MySQL.

### Step 3: Create the Database and Table  

If the host can access MySQL normally, create a database named `voiceprint_db` and a table `voiceprints`:

```sql
CREATE DATABASE voiceprint_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE voiceprint_db;

CREATE TABLE voiceprints (
    id INT AUTO_INCREMENT PRIMARY KEY,
    speaker_id VARCHAR(255) NOT NULL UNIQUE,
    feature_vector LONGBLOB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_speaker_id (speaker_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Step 4: Configure Database Connection  

Enter the `voiceprint-api` directory and create a folder named `data`.  
Copy `voiceprint.yaml` from the project root into `data` and rename it to `.voiceprint.yaml`.

Open `.voiceprint.yaml` and configure the database connection (this is the key part):

```yaml
mysql:
  host: "127.0.0.1"
  port: 3306
  user: "root"
  password: "your_password"
  database: "voiceprint_db"
```

**Important!** Because the voiceprint service is deployed via Docker, `host` must be set to the **local‑network IP** of the machine running MySQL.

*Repeat the reminder:* Because the voiceprint service is deployed via Docker, `host` must be set to the **local‑network IP** of the machine running MySQL.

### Step 5: Start the Service  

The project is simple; it can be run with Docker or by compiling from source.  
Below is the Docker method:

```bash
# Enter the project root directory
cd voiceprint-api

# Clean up the cache
docker compose -f docker-compose.yml down
docker stop voiceprint-api
docker rm voiceprint-api
docker rmi ghcr.nju.edu.cn/xinnan-tech/voiceprint-api:latest

# Start the Docker containers
docker compose -f docker-compose.yml up -d
# View logs
docker logs -f voiceprint-api
```

You should see logs similar to:

```
250711 INFO-🚀 开始: 生产环境服务启动（Uvicorn），监听地址: 0.0.0.0:8005
250711 INFO-============================================================
250711 INFO-声纹接口地址: http://127.0.0.1:8005/voiceprint/health?key=abcd
250711 INFO-============================================================
```

Copy the displayed address into a draft. Since you are using Docker, **do not use the address directly**.  

Replace the original address:

```
http://127.0.0.1:8005/voiceprint/health?key=abcd
```

with your host’s local‑network IP, e.g., if your IP is `192.168.1.25`:

```
http://192.168.1.25:8005/voiceprint/health?key=abcd
```

Open a browser and navigate to the modified address. If you receive:

```json
{"total_voiceprints":0,"status":"healthy"}
```

the configuration succeeded. Keep this address for the next step.

---

## 2. Configuring Voiceprint When Deploying All Modules

### Step 1: Enable the Interface  

1. In the **智控台** (Zhilian Platform) UI, click **参数字典** (Parameter Dictionary) → **系统功能配置** (System Function Configuration).  
2. Check **声纹识别** (Voiceprint) and click **保存配置** (Save Configuration).  
   The **Voiceprint** button will now appear on new smart‑body cards.

If you are using the full‑module deployment, log in with an admin account, go to **参数字典** → **参数管理** (Parameter Management).  

Search for the parameter `server.voice_print`. Its value should be `null`.  

Click **修改** (Edit), paste the voiceprint interface address you obtained earlier into the **参数值** (Parameter Value) field, then **保存** (Save).  

If the save succeeds, everything is fine; otherwise, the Zhilian platform may not be able to reach the voiceprint service—likely due to a firewall or an incorrect local‑network IP.

### Step 2: Set the Smart Body’s Memory Mode  

In the smart body’s role configuration, set the memory mode to **本地短期记忆** (Local Short‑Term Memory) and enable **上报文字+语音** (Report Text and Voice).

### Step 3: Chat with Your Smart Body  

Power up the device and converse with it at a normal pace and tone.

### Step 4: Register a Voiceprint  

In the **智能体管理** (Smart Body Management) page, locate the **声纹识别** (Voiceprint) button on the smart body panel and click it.  

At the bottom, a **新增** (Add) button appears. Click it to register a speaker’s voiceprint.  

In the pop‑up, fill the **描述** (Description) field with relevant information such as the person’s occupation, personality, or hobby. This helps the smart body understand and analyze the speaker.

### Step 4: Chat with Your Smart Body  

Power up the device and ask, “Do you know who I am?”  
If the smart body can answer correctly, the voiceprint functionality is working.

---

## 3. Minimal Deployment Configuration for Voiceprint

### Step 1: Configure the Interface  

Open the file `xiaozhi-server/data/.config.yaml` (create it if it does not exist) and add/modify the following content:

```yaml
# Voiceprint Configuration
voiceprint:
  # Voiceprint interface address
  url: YOUR_VOICEPRINT_INTERFACE_ADDRESS
  # Speaker configurations: speaker_id, name, description
  speakers:
    - "test1,张三,张三是一个程序员"
    - "test2,李四,李四是一个产品经理"
    - "test3,王五,王五是一个设计师"
```

Replace `YOUR_VOICEPRINT_INTERFACE_ADDRESS` with the address you obtained in the previous section.  
Save the file.

The `speakers` list can be adjusted as needed. **Important:** The `speaker_id` values must match those used when registering voiceprints later.

### Step 2: Register a Voiceprint  

Assuming the voiceprint service is already running, open a browser at `http://localhost:8005/voiceprint/docs` to view the API documentation.  
Below is how to use the **register** endpoint:

*Endpoint:* `POST http://localhost:8005/voiceprint/register`  
*Header:* Include a Bearer token where the token is the part after `?key=` in the voiceprint **health** URL.  
  *Example:* If the health URL is `http://127.0.0.1:8005/voiceprint/health?key=abcd`, the token is `abcd`.

*Request Body:* Include a `speaker_id` that matches the one defined in the `.config.yaml` file and a WAV audio file (`file`).

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "speaker_id=your_speaker_id_here" \
  -F "file=@/path/to/your/file" \
  http://localhost:8005/voiceprint/register
```

Here, `file` is the audio clip of the speaker you want to register, and `speaker_id` must correspond to the identifier you set in `.config.yaml`.  
For example, if you configured `张三` with `speaker_id` `test1`, then the request body’s `speaker_id` must be `test1` and `file` should point to Zhang San’s spoken audio.

### Step 3: Start the Services  

Start both the Zhilian server and the voiceprint service to begin using them.
