# Full Module Source Code Deployment Auto‑Upgrade Method  

This tutorial is intended for enthusiasts who want to automatically pull code, compile it, and start the service for **full‑module source deployment**. It provides an efficient way to upgrade the system.

The test platform used by this project is **https://2662r3426b.vicp.fun**. Since its launch, this method has been employed there with satisfactory results.

You can refer to the Bilibili video tutorial by creator **毕乐labs**:  
[《开源小智服务器xiaozhi-server自动更新以及最新版本MCP接入点配置保姆教程》](https://www.bilibili.com/video/BV15H37zHE7Q)

---

## Prerequisites  

- Your computer/server runs **Linux**.  
- You have successfully executed the entire workflow at least once.  
- You want to stay up‑to‑date with the latest features but find manual deployment cumbersome and would like an automated update solution.

> **The second prerequisite is mandatory**, because some files mentioned in this guide (JDK, Node.js, Conda, etc.) can only be fully understood after you have completed the initial deployment.

---

## Tutorial Outcome  

- Resolves the issue of being unable to fetch the latest project source code from within China.  
- Automatically pulls the code, compiles the frontend, and starts the services.  
- Automatically kills and restarts the following ports:  
  - **8002** for the Java API module.  
  - **8000** for the Python module.  

---

## Step 1: Choose Your Project Directory  

For example, I organize my project directory as follows. If you want to avoid errors, you can adopt the same structure:

```
/home/system/xiaozhi
```

---

## Step 2: Clone the Repository  

First, run the following command, which works for servers/computers behind the Great Firewall without requiring a VPN:

```bash
cd /home/system/xiaozhi
git clone https://ghproxy.net/https://github.com/xinnan-tech/xiaozhi-esp32-server.git
```

After execution, a folder named **`xiaozhi-esp32-server`** will appear inside `/home/system/xiaozhi`. This folder contains the source code.

---

## Step 3: Copy Base Files  

If you have previously run the entire process, you are already familiar with the two files used by **funasr**:  

- `xiaozhi-server/models/SenseVoiceSmall/model.pt`  
- `xiaozhi-server/data/.config.yaml`  

Now copy these files into the new directory:

```bash
# Create the required directory structure
mkdir -p /home/system/xiaozhi/xiaozhi-esp32-server/main/xiaozhi-server/data/

# Copy the configuration file
cp /path/to/your/original/.config.yaml /home/system/xiaozhi/xiaozhi-esp32-server/main/xiaozhi-server/data/.config.yaml

# Copy the model file
cp /path/to/your/original/model.pt /home/system/xiaozhi/xiaozhi-esp32-server/main/xiaozhi-server/models/SenseVoiceSmall/model.pt
```

---

## Step 4: Set Up Three Auto‑Compilation Scripts  

### 4.1 Auto‑compile the `manager-web` module  

Create a script named **`update_8001.sh`** in `/home/system/xiaozhi/` with the following content:

```bash
cd /home/system/xiaozhi/xiaozhi-esp32-server
git fetch --all
git reset --hard
git pull origin main

cd /home/system/xiaozhi/xiaozhi-esp32-server/main/manager-web
npm install
npm run build
rm -rf /home/system/xiaozhi/manager-web
mv /home/system/xiaozhi/xiaozhi-esp32-server/main/manager-web/dist /home/system/xiaozhi/manager-web
```

Make the script executable:

```bash
chmod 777 update_8001.sh
```

---

### 4.2 Auto‑compile and run the `manager-api` module  

Create a script named **`update_8002.sh`** in `/home/system/xiaozhi/` with the following content:

```bash
cd /home/system/xiaozhi/xiaozhi-esp32-server
git pull origin main

cd /home/system/xiaozhi/xiaozhi-esp32-server/main/manager-api
rm -rf target
mvn clean package -Dmaven.test.skip=true
cd /home/system/xiaozhi/

# Find the PID of the process occupying port 8002
PID=$(sudo netstat -tulnp | grep 8002 | awk '{print $7}' | cut -d'/' -f1)

# If a process is found, kill it
if [ -z "$PID" ]; then
  echo "No process occupying port 8002."
else
  echo "Process occupying port 8002 found, PID: $PID"
  kill -9 $PID
  kill -9 $PID
  echo "Process $PID killed."
fi

# Move the newly built jar and start it
mv /home/system/xiaozhi/xiaozhi-esp32-server/main/manager-api/target/xiaozhi-esp32-api.jar /home/system/xiaozhi/xiaozhi-esp32-api.jar
nohup java -jar xiaozhi-esp32-api.jar --spring.profiles.active=dev &

# Show the log tail
tail -f nohup.out
```

Make the script executable:

```bash
chmod 777 update_8002.sh
```

---

### 4.3 Auto‑compile and run the Python project  

Create a script named **`update_8000.sh`** in `/home/system/xiaozhi/` with the following content:

```bash
cd /home/system/xiaozhi/xiaozhi-esp32-server
git pull origin main

# Find the PID of the process occupying port 8000
PID=$(sudo netstat -tulnp | grep 8000 | awk '{print $7}' | cut -d'/' -f1)

# If a process is found, kill it
if [ -z "$PID" ]; then
  echo "No process occupying port 8000."
else
  echo "Process occupying port 8000 found, PID: $PID"
  kill -9 $PID
  kill -9 $PID
  echo "Process $PID killed."
fi

cd main/xiaozhi-server

# Activate the conda environment
source ~/.bashrc
conda activate xiaozhi-esp32-server

# Install Python requirements
pip install -r requirements.txt

# Run the application in the background
nohup python app.py >/dev/null &

# Tail the log file
tail -f /home/system/xiaozhi/xiaozhi-esp32-server/main/xiaozhi-server/tmp/server.log
```

Make the script executable:

```bash
chmod 777 update_8000.sh
```

---

## Daily Updates  

After the three scripts are prepared, you can update and start all services with the following commands:

```bash
cd /home/system/xiaozhi
# Update and start the Java service
./update_8001.sh

# Update the web module
./update_8002.sh

# Update and start the Python service
./update_8000.sh
```

### Checking Logs  

- **Java logs** (from `nohup.out`):  
  ```bash
  tail -f nohup.out
  ```
- **Python logs** (from `server.log`):  
  ```bash
  tail -f /home/system/xiaozhi/xiaozhi-esp32-server/main/xiaozhi-server/tmp/server.log
  ```

---

## Notes  

- The test platform **https://2662r3426b.vicp.fun** uses **nginx** for reverse proxying. The detailed `nginx.conf` configuration can be found [here](https://github.com/xinnan-tech/xiaozhi-esp32-server/issues/791).

---

## Common Issues  

### 1, Why isn’t port 8001 visible?  

**Answer:** Port 8001 is used in the development environment to run the frontend. If you are deploying on a server, it is not recommended to run the frontend directly on port 8001 with `npm run serve`. Instead, compile the frontend into static HTML files (as demonstrated in this tutorial) and serve them via **nginx**.

### 2, Do I need to manually update SQL statements each time?  

**Answer:** No. The project uses **Liquibase** to manage database schema versions, and it automatically executes any new SQL scripts during updates.
