# ragflow Integration Guide

This tutorial is divided into two parts:

- 1️⃣ How to deploy Ragflow  
- 2️⃣ How to configure the Ragflow interface on the XIAOZHI Console  

If you are already familiar with Ragflow and have already deployed it, you can skip the first part and go directly to the second. However, if you need someone to guide you through deploying Ragflow so that it can share MySQL and Redis services with the **xiaozhi-esp32-server** to reduce resource consumption, you should start from the first part.

---

## Part 1: How to Deploy Ragflow

### Step 1 – Check whether MySQL and Redis are available

Ragflow depends on the **MySQL** database. If you have previously deployed the **XIAOZHI Console**, you already have MySQL installed, so you can reuse it.

You can test whether you can access MySQL and Redis ports on the host machine with `telnet`:

```bash
telnet 127.0.0.1 3306   # MySQL
telnet 127.0.0.1 6379   # Redis
```

If both commands connect successfully, skip the following steps and go straight to **Step 2**.  
If they cannot connect, recall how you installed MySQL.

- If you installed MySQL manually, it may be isolated from the network. You need to resolve the ability to access MySQL on port **3306**.  
- If you installed MySQL via the `docker-compose_all.yml` in this project, locate that file and modify the relevant sections.

#### Fix for `docker-compose_all.yml`

Change `expose` to `ports` for both services:

```yaml
# Before
  xiaozhi-esp32-server-db:
    ...
    networks:
      - default
    expose:
      - "3306:3306"
  xiaozhi-esp32-server-redis:
    ...
    expose:
      - 6379

# After
  xiaozhi-esp32-server-db:
    ...
    networks:
      - default
    ports:
      - "3306:3306"
  xiaozhi-esp32-server-redis:
    ...
    ports:
      - "6379:6379"
```

*Note*: Replace `expose` with `ports` under both services. After editing, restart the containers:

```bash
cd xiaozhi-server                # go to the folder containing docker-compose_all.yml
docker compose -f docker-compose_all.yml down
docker compose -f docker-compose.yml up -d
```

Then test again with `telnet 127.0.0.1 3306` and `telnet 127.0.0.1 6379`. They should now be reachable.

---

### Step 2 – Create the database and user

If you can connect to MySQL, create a database named `rag_flow` and a user `rag_flow` with password `infini_rag_flow`:

```sql
-- Create database
CREATE DATABASE IF NOT EXISTS rag_flow CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user and grant privileges
CREATE USER IF NOT EXISTS 'rag_flow'@'%' IDENTIFIED BY 'infini_rag_flow';
GRANT ALL PRIVILEGES ON rag_flow.* TO 'rag_flow'@'%';
FLUSH PRIVILEGES;
```

---

### Step 3 – Download the Ragflow project

Choose a folder on your machine to store the Ragflow project, e.g., `/home/system/xiaozhi`.

```bash
git clone https://ghfast.top/https://github.com/infiniflow/ragflow.git
cd ragflow
git checkout v0.22.0
cd docker
```

Edit `docker-compose.yml` inside `docker` and **remove** the `depends_on` entries for the `ragflow-cpu` and `ragflow-gpu` services that reference MySQL.  

*Before*:

```yaml
  ragflow-cpu:
    depends_on:
      mysql:
        condition: service_healthy
    profiles:
      - cpu
  ...
  ragflow-gpu:
    depends_on:
      mysql:
        condition: service_healthy
    profiles:
      - gpu
```

*After*:

```yaml
  ragflow-cpu:
    profiles:
      - cpu
  ...
  ragflow-gpu:
    profiles:
      - gpu
```

Next, edit `docker-compose-base.yml` in the same folder and **remove** the definitions for `mysql` and `redis` services:

*Before*:

```yaml
services:
  minio:
    image: quay.io/minio/minio:RELEASE.2025-06-13T11-33-47Z
    ...
  mysql:
    image: mysql:8.0
    ...
  redis:
    image: redis:6.2-alpine
    ...
```

*After*:

```yaml
services:
  minio:
    image: quay.io/minio/minio:RELEASE.2025-06-13T11-33-47Z
    ...
```

---

### Step 4 – Adjust environment variables

Edit the `.env` file under `docker` and modify each configuration item listed below.  
**Important**: About **60 %** of users forget to set `MYSQL_USER`, which prevents Ragflow from starting. Do it three times if necessary:

> **Emphasis 1**: If `.env` does **not** contain `MYSQL_USER`, you must add it.  
> **Emphasis 2**: If `.env` does **not** contain `MYSQL_USER`, you must add it.  
> **Emphasis 3**: If `.env` does **not** contain `MYSQL_USER`, you must add it.  

```dotenv
# Port settings
SVR_WEB_HTTP_PORT=8008           # HTTP port
SVR_WEB_HTTPS_PORT=8009          # HTTPS port

# MySQL configuration – replace with your local MySQL info
MYSQL_HOST=host.docker.internal  # Use host.docker.internal so the container can reach the host's services
MYSQL_PORT=3306                  # Local MySQL port
MYSQL_USER=rag_flow              # Username you created above (add this if missing)
MYSQL_PASSWORD=infini_rag_flow   # Password you set above
MYSQL_DBNAME=rag_flow            # Database name

# Redis configuration – replace with your local Redis info
REDIS_HOST=host.docker.internal  # Use host.docker.internal so the container can reach the host's services
REDIS_PORT=6379                  # Local Redis port
REDIS_PASSWORD=                  # Leave empty if Redis has no password; otherwise put the password
```

Now locate `service_conf.yaml.template` inside `docker` and change the Redis password reference from `infini_rag_flow` to an empty string:

```yaml
# Before
redis:
  db: 1
  password: '${REDIS_PASSWORD:-infini_rag_flow}'
  host: '${REDIS_HOST:-redis}:6379'

# After
redis:
  db: 1
  password: '${REDIS_PASSWORD:-}'
  host: '${REDIS_HOST:-redis}:6379'
```

---

### Step 5 – Start Ragflow services

```bash
docker-compose -f docker-compose.yml up -d
```

After the containers are up, monitor the CPU service logs:

```bash
docker logs -n 20 -f docker-ragflow-cpu-1
```

If there are no error messages in the logs, the service has started successfully.

---

### Step 6 – Register an account

Open a browser and go to `http://127.0.0.1:8008`. Click **Sign Up** to create an account.

After registration, click **Sign In** to log in.  
If you want to **disable public registration**, edit the `.env` file in the `docker` folder and set:

```dotenv
REGISTER_ENABLED=0
```

Save the file and restart the services:

```bash
docker-compose -f docker-compose.yml down
docker-compose -f docker-compose.yml up -d
```

---

### Step 7 – Configure models for Ragflow

1. Open `http://127.0.0.1:8008` in your browser, sign in, then click the avatar (top‑right) → **Settings**.  
2. In the left navigation bar, select **Model Providers**.  
   - Under the **Optional Models** search box, choose **LLM**, pick your model provider from the list, click **Add**, and enter your API key.  
   - Switch to **TEXT EMBEDDING**, similarly select a provider and add your key.  
3. Refresh the page and, in the **Default Model** column, select the LLM you just added for default LLM, and select the embedding model for default embedding.  
   *Make sure the provider’s service is activated and, if required, you have purchased the necessary resource package.*

---

## Part 2: Configuring Ragflow on the XIAOZHI Console

### Step 1 – Log in to Ragflow

Visit `http://127.0.0.1:8008`, click **Sign In**, and log in.

1. Click the avatar (top‑right) → **Settings**.  
2. In the left navigation bar, click **API**, then press the **Create New Key** button in the dialog.  
3. Copy the generated **API Key**; you will use it later.

---

### Step 2 – Configure on the XIAOZHI Console

1. Ensure your XIAOZHI Console version is **0.8.7** or newer. Log in with a super‑admin account.  
2. Enable the **Knowledge Base** feature:  
   - Top navigation → **Parameter Dictionary** → **System Feature Configuration**.  
   - Check **Knowledge Base** and click **Save**.  
   - The **Knowledge Base** entry will now appear in the top navigation.  

3. Still in the top navigation, click **Model Configuration** → **Knowledge Base** in the left sidebar.  
   - Find **RAG_RAGFlow** in the list, click **Edit**.  
   - Fill in:  
     - **Service Address**: `http://<ragflow‑host‑IP>:8008` (e.g., `http://192.168.1.100:8008`).  
     - **API Key**: paste the API key you copied earlier.  
   - Click **Save**.

---

### Step 3 – Create a Knowledge Base

1. Log into the XIAOZHI Console with a super‑admin account.  
2. Top navigation → **Knowledge Base** → click **New** at the lower‑left corner.  
3. Enter a meaningful name and description for the knowledge base. Example:  
   - **Name**: `Company Profile`  
   - **Description**: `Information about the company, such as basic details, services, contact phone, address, etc.`  
4. Save the knowledge base.  
5. In the knowledge base list, click **View** on the newly created entry, then click **Add** at the bottom‑left to upload documents.  
6. After uploading, click **Parse** on a document to parse it, then view the generated chunks.  
7. To test retrieval, click **Recall Test** on the knowledge base page. This checks how well the knowledge base can be queried.

---

### Step 4 – Use the Knowledge Base in a Smart Agent

1. Log into the XIAOZHI Console.  
2. Top navigation → **Agent** → locate the agent you want to configure, click **Configure Role**.  
3. In the **Intent Recognition** left panel, click **Edit Function** and a dialog will appear.  
4. In the dialog, select the knowledge base you just created and save.  

Now the agent can retrieve information from the configured Ragflow knowledge base.  
