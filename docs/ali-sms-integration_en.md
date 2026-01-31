# **Aliyun SMS Integration Guide**

## **Step 1: Add Signature**
![Step](images/alisms/sms-01.png)  
![Step](images/alisms/sms-02.png)

The above steps will provide you with a signature. Please enter it into the Smart Console parameter, `aliyun.sms.sign_name`.

> **Note:** The signature must wait for **7 working days** until the carrier’s registration is completed before it can be used for sending messages.

---

## **Step 2: Add Template**
![Step](images/alisms/sms-11.png)

The above steps will give you a template code. Please enter it into the Smart Console parameter, `aliyun.sms.sms_code_template_code`.

> **Note:** The signature must wait for **7 working days** until the carrier’s registration is completed before it can be used for sending messages.

---

## **Step 3: Create SMS Account and Enable Permissions**

Log in to the Aliyun console and go to the **Access Control** page:  
https://ram.console.aliyun.com/overview?activeTab=overview

![Step](images/alisms/sms-21.png)  
![Step](images/alisms/sms-22.png)  
![Step](images/alisms/sms-23.png)  
![Step](images/alisms/sms-24.png)  
![Step](images/alisms/sms-25.png)

The above steps will provide you with an **Access Key ID** and **Access Key Secret**. Enter them into the Smart Console parameters, `aliyun.sms.access_key_id` and `aliyun.sms.access_key_secret`.

---

## **Step 4: Enable Mobile Registration**

1. Normally, after completing the above information you will see the following effect. If you don’t, a step might be missing.  
   ![Step](images/alisms/sms-31.png)

2. Enable allowing non‑admin users to register by setting the parameter `server.allow_user_register` to `true`.

3. Enable mobile registration functionality by setting the parameter `server.enable_mobile_register` to `true`.  
   ![Step](images/alisms/sms-32.png)

--- 

*All parameter names remain unchanged.*
