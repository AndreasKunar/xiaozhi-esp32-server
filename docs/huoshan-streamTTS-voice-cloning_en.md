# Smart Console Volcano Streaming TTS + Voice Cloning Configuration Tutorial
This tutorial is divided into 4 stages: Preparation, Configuration, Cloning, and Usage. It mainly explains how to configure Volcano streaming TTS + voice cloning via the Smart Console.

## Phase 1: Preparation
The super administrator must first enable the Volcano Engine service, obtain an **App ID** and **Access Token**. By default, Volcano Engine provides one voice resource. This voice resource needs to be copied into the project.  

If you want to clone multiple voices, you need to purchase and enable multiple voice resources. Copy each voice’s ID (`S_xxxxx`) into the project. Then assign them to a system account. The detailed steps are as follows:

### 1. Enable Volcano Engine Service
Visit https://console.volcengine.com/speech/app and create an application in **Application Management**, checking both **Speech Synthesis Large Model** and **Voice Cloning Large Model**.

### 2. Obtain Voice Resource ID
Visit https://console.volcengine.com/speech/service/9999, copy the three items: **App ID**, **Access Token**, and the **Voice ID** (`S_xxxxx`). See the figure below.

![Obtain Voice Resource](images/image-clone-integration-01.png)

## Phase 2: Configure Volcano Engine Service
### 1. Fill in Volcano Engine Configuration
Use a super administrator account to log into the Smart Console, click the top‑level **Model Configuration**, then click **Speech Synthesis** on the left side of the Model Configuration page, search for **“Volcano Streaming TTS”**, click **Edit**, fill your Volcano Engine’s `App ID` into the **Application ID** field, and fill the `Access Token` into the **Access Token** field. Then save the changes.

### 2. Assign Voice Resource ID to a System Account
Log in to the Smart Console with a super administrator account, click the top‑level **Parameter Dictionary**, then select **System Feature Configuration** from the dropdown. Check the **Voice Cloning** option and save the configuration. The **Voice Cloning** button will then appear in the top menu.

Log in to the Smart Console with a super administrator account, click the top‑level **Voice Cloning** → **Voice Resources**.

Click the **Add** button, and in **Platform Name** select **“Volcano Streaming TTS”**;  

In **Voice Resource ID**, enter your Volcano Engine’s voice resource ID (`S_xxxxx`), press Enter after entering;  

In **Belonging Account**, select the system account you want to assign this to (you can assign it to yourself). Then click **Save**.

## Phase 3: Cloning
If after logging in you click **Voice Cloning** → **Voice Cloning** and see a message “**Your account has no voice resources; please contact the administrator to allocate voice resources**”, it means you have not assigned a voice resource ID to this account in Phase 2. Return to Phase 2 to allocate the voice resource to the corresponding account.

If after logging in you click **Voice Cloning** → **Voice Cloning** and can see the corresponding voice list, continue.

In the list you will see the corresponding voice resources. Select one voice resource and click the **Upload Audio** button. After uploading, you can listen to the audio or clip a segment. Confirm and click **Upload Audio** again.  

![Upload Audio](images/image-clone-integration-02.png)

After uploading the audio, the voice in the list will change to the **“Waiting to Clone”** status. Click the **Clone Now** button. It will return a result within 1–2 seconds.

If cloning fails, hover over the error icon to see the failure reason.

If cloning succeeds, the list will show the voice as **“Training Successful”**. At this point you can click the edit button on the **Voice Name** column to rename the voice resource for easier selection later.

## Phase 4: Usage
Click **Intelligent Agent Management** at the top, select any intelligent agent, and click the **Configure Role** button.

For Speech Synthesis (TTS), choose **Volcano Streaming TTS**. In the list, find a voice resource whose name contains “Clone” (e.g., see figure), select it, and save.  

![Select Voice](images/image-clone-integration-03.png)

Next, you can wake up **Xiaozhi** and converse with it.
