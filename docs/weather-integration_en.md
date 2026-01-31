# Weather Plugin Usage Guide

## Overview  

The weather plugin `get_weather` is one of the core features of the XiaoZhi ESP32 voice assistant, supporting voice queries for weather information across the country. The plugin is based on the HeWeather API, providing real‑time weather and 7‑day forecast functionality.  

---  

## API Key Application Guide  

### 1. Register for a HeWeather Account  

1. Visit [HeWeather Console](https://console.qweather.com/)  
2. Register an account and complete email verification  
3. Log in to the console  

### 2. Create an Application to Obtain the API Key  

1. After logging into the console, click ["Project Management"](https://console.qweather.com/project?lang=zh) → **"Create Project"**  
2. Fill in project information:  
   - **Project Name**: e.g., **"XiaoZhi Voice Assistant"**  
3. Click **Save**  
4. After the project is created, in that project click **"Create Credential"**  
5. Fill in the credential information:  
   - **Credential Name**: e.g., **"XiaoZhi Voice Assistant"**  
   - **Authentication Method**: Select **"API Key"**  
6. Click **Save**  
7. In the credentials list, copy the `API Key`; this is the first key configuration item you need  

### 3. Obtain the API Host  

1. In the console, click ["Settings"](https://console.qweather.com/setting?lang=zh) → **"API Host"**  
2. View the `API Host` address assigned to you; this is the second key configuration item you need  

> **Result:** The above steps provide you with two essential configuration items: `API Key` and `API Host`.  

---  

## Configuration Method (Choose One)  

### Method 1. If You Are Using the Smart Console Deployment (Recommended)  

1. Log in to the Smart Console  
2. Navigate to the **"Role Configuration"** page  
3. Select the intelligent agent you wish to configure  
4. Click the **"Edit Function"** button  
5. In the parameter configuration area on the right, locate the **"Weather Query"** plugin  
6. Check **"Weather Query"**  
7. Paste the copied first key configuration `API Key` into the **"Weather Plugin API Key"** field  
8. Paste the copied second key configuration `API Host` into the **"Developer API Host"** field  
9. Save the configuration, then save the intelligent agent configuration  

### Method 2. If You Are Deploying Only a Single Module `xiaozhi-server`  

Edit `data/.config.yaml` as follows:  

1. Paste the copied first key configuration `API Key` into the `api_key` field  
2. Paste the copied second key configuration `API Host` into the `api_host` field  
3. Enter your default city in `default_location`; for example, **"Guangzhou"**  

```yaml
plugins:
  get_weather:
    api_key: "Your HeWeather API Key"
    api_host: "Your HeWeather API Host"
    default_location: "Your default query city"
```  
