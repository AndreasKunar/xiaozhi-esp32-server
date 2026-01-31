# How to Use MCP Methods to Get Device Information

## Step 1: Customize your `agent-base-prompt.txt` file  
Copy the content of the `agent-base-prompt.txt` file from the **xiaozhi‑server** directory into your `data` directory and rename it to `.agent-base-prompt.txt`.

## Step 2: Edit `data/.agent-base-prompt.txt`  
Locate the `<context>` tag in the file and insert the following code inside it:

``` 
- **Device ID:** {{device_id}}
```

After adding the code, the `<context>` section of your `data/.agent-base-prompt.txt` file should look approximately like this:

``` 
<context>
【Important! The following information is provided in real time and does not require tool calls; use directly:】
- **Device ID:** {{device_id}}
- **Current time:** {{current_time}}
- **Today's date:** {{today_date}} ({{today_weekday}})
- **Lunar date:** {{lunar_date}}
- **User's city:** {{local_address}}
- **Local weather for the next 7 days:** {{weather_info}}
</context>
```

## Step 3: Edit `data/.config.yaml`  
Find the `agent-base-prompt` configuration and replace its original content:

```yaml
prompt_template: agent-base-prompt.txt
```

with:

```yaml
prompt_template: data/.agent-base-prompt.txt
```

## Step 4: Restart the xiaozhi-server service.  

## Step 5: Add a parameter to your MCP method  
Add a parameter named `device_id`, of type `string`, with the description `Device ID` to your MCP method.

## Step 6: Re‑activate XiaoZhi and have him call the MCP method to verify that the method can retrieve the `Device ID`.  
