# EPM Duplicate Endpoint Cleanup Script - Tutorial

## Overview

This PowerShell script identifies and removes duplicate endpoint agents from Idira Endpoint Privilege Manager (EPM) based on their computer name. When multiple agents exist for the same hostname, the script keeps the most recently installed agent and removes the older duplicates.

**Important:** This script only removes endpoint records from the EPM console. It does **not** uninstall the EPM agent from the actual machines.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Getting Started](#getting-started)
3. [Authentication Options](#authentication-options)
4. [API Version Selection](#api-version-selection)
5. [Understanding the Output](#understanding-the-output)
6. [Step-by-Step Walkthrough](#step-by-step-walkthrough)
7. [Troubleshooting](#troubleshooting)
8. [FAQ](#faq)

---



## Prerequisites



### Required Information

Before running the script, gather the following information:


| Item                | Description                   | Where to Find                                                              |
| ------------------- | ----------------------------- | -------------------------------------------------------------------------- |
| **Set ID**          | The GUID of your EPM Set      | EPM Console → Sets → Select Set → URL contains the Set ID                  |
| **EPM Credentials** | Username and password for EPM | Your EPM administrator account                                             |
| **EPM Server URL**  | Your EPM cloud environment    | Commercial: `login.epm.cyberark.com` US Gov: `login.epm.cyberarkgov.cloud` |




### For OAuth2 Authentication (Optional)

If using modern OAuth2 authentication via Idira Identity, you'll also need:


| Item                   | Description                       | Where to Find                                                  |
| ---------------------- | --------------------------------- | -------------------------------------------------------------- |
| **Identity Subdomain** | Your Identity tenant subdomain    | From URL: `abc1234.id.cyberark.cloud` → subdomain is `abc1234` |
| **OAuth App Alias**    | The alias of your EPM API web app | Identity Admin → Apps → Your EPM API App → Settings            |
| **Service User**       | Dedicated service account         | Format: `svc-epm-api@yourtenant.cyberark.cloud`                |
| **EPM Server Name**    | Your EPM server subdomain         | From URL: `mycompany.epm.cyberark.com` → name is `mycompany`   |




### System Requirements

- Windows PowerShell 5.1 or later
- Network access to CyberArk EPM cloud services
- EPM user account with appropriate permissions:
  - View computers/endpoints
  - Delete computers/endpoints

---



## Getting Started



### Step 1: Download the Script

Save the script file `EPM-DeleteDuplicateEndpoints.ps1` to a local folder, such as:

```
C:\Users\YourName\Desktop\EPM Scripts\
```



### Step 2: Open PowerShell

1. Press `Win + X` and select **Windows PowerShell** or **Terminal**
2. Navigate to the script location:
  ```powershell
   cd "C:\Users\YourName\Desktop\EPM Scripts\"
  ```



### Step 3: Run the Script

```powershell
.\EPM-DeleteDuplicateEndpoints.ps1
```

---



## Authentication Options

The script supports two authentication methods:

### Option 1: Legacy EPM Authentication

Traditional username/password authentication directly with EPM.

**When to use:**

- Simple setup with no additional configuration required
- Your organization hasn't migrated to Idira Identity
- Quick one-time script execution

**Flow:**

1. Select option `[1]` when prompted
2. Choose your EPM cloud environment (Commercial, US Government, or Custom)
3. Enter your EPM username
4. Enter your EPM password (input is masked)
5. Optionally enter an Application ID (or press Enter to skip)



### Option 2: Modern OAuth2 via Idira Identity (ISPSS)

OAuth 2.0 client credentials flow using IdiraIdentity Security Platform Shared Services.

**When to use:**

- Your organization uses Idira Identity for authentication
- You need token-based authentication for automation
- Enhanced security requirements

**Prerequisites for OAuth2:**

1. A service user created in Identity Administration
2. A custom EPM API web app configured in Identity
3. The service user bound to the web app (in the Tokens tab)
4. The service user assigned to an EPM role with API permissions

**Flow:**

1. Select option `[2]` when prompted
2. Enter your Identity tenant subdomain
3. Enter the OAuth app alias
4. Enter the service user email
5. Enter the service user password (input is masked)
6. Enter your EPM server name

---



## API Version Selection

After authentication, choose which EPM API to use:

### Option 1: Legacy Computers API

**When to use:**

- EPM version prior to 25.4
- Your organization hasn't migrated to the new Endpoints page
- Compatibility with older EPM deployments

**Characteristics:**

- Uses `GET /Sets/{SetId}/Computers` endpoint
- Supports up to 2,500 records per page
- Deletes one computer at a time
- Property names: `ComputerName`, `AgentId`, `InstallTime`



### Option 2: Modern Endpoints API (Recommended)

**When to use:**

- EPM version 25.4 or later
- Your organization has activated the new Endpoints management page
- Better performance with batch deletions

**Characteristics:**

- Uses `POST /Sets/{SetId}/Endpoints/search` endpoint
- Maximum 1,000 records per page
- Batch deletion (up to 10 endpoints per API call)
- Property names: `name`, `id`, `installTime`

---



## Understanding the Output



### Duplicate Detection

The script identifies duplicates by grouping endpoints with the same hostname. For each group:

- The endpoint with the **most recent install time** is **KEPT**
- All older endpoints are marked for **DELETION**



### Sample Output

```
============================================
  DUPLICATE ENDPOINTS FOUND
============================================

Found 3 duplicate endpoint(s) that will be DELETED:
(Keeping the most recently installed agent for each hostname)

  ENDPOINT NAME                  ENDPOINT ID                              INSTALL TIME             
  ------------------------------ ---------------------------------------- -------------------------
  WORKSTATION-01                 abc123-def456-7890-abcd-ef1234567890     2024-01-15T10:30:00Z     
  WORKSTATION-01                 xyz789-uvw012-3456-wxyz-012345678901     2024-02-20T14:45:00Z     
  SERVER-DB-01                   qrs345-tuv678-9012-qrst-345678901234     2024-03-01T08:00:00Z     

The following endpoints will be KEPT (newest install per hostname):

  WORKSTATION-01                 newest-1234-5678-9012-345678901234       2024-05-10T09:15:00Z     
  SERVER-DB-01                   newest-db01-5678-9012-567890123456       2024-06-01T11:30:00Z     

============================================
  WARNING
============================================
This action will permanently remove the duplicate endpoints listed above from EPM.
The EPM agent will NOT be uninstalled from the machines.

Do you want to proceed with deletion? Type 'yes' to confirm:
```



### Deletion Progress

During deletion, you'll see progress updates:

```
Starting deletion process...

Processing batch 1 of 1 - Deleting 3 endpoint(s)...
  - WORKSTATION-01
  - WORKSTATION-01
  - SERVER-DB-01
  [OK] Successfully queued 3 endpoint(s) for deletion

============================================
  DELETION COMPLETE
============================================

  Total endpoints processed: 3
```

---



## Step-by-Step Walkthrough



### Complete Example Using Legacy EPM Authentication + Modern Endpoints API

```
============================================
  EPM Duplicate Endpoint Cleanup Script
============================================

Enter your EPM Set ID: 398a88e0-0276-4473-ba06-c986626029ae

Select Authentication Method:
  [1] Legacy EPM Authentication (username/password)
  [2] Modern OAuth2 via CyberArk Identity (ISPSS)

Enter choice (1 or 2): 1

--- Legacy EPM Authentication ---

Select EPM Cloud Environment:
  [1] Commercial (login.epm.cyberark.com)
  [2] US Government (login.epm.cyberarkgov.cloud)
  [3] Custom URL
Enter choice (1, 2, or 3): 1
Enter EPM username: admin@mycompany.com
Enter EPM password: ********
Enter Application ID (optional, press Enter to skip): 

Authenticating via Legacy EPM authentication...
EPM authentication successful!

Connected to EPM server: https://mycompany.epm.cyberark.com

Select API Version:
  [1] Legacy Computers API (deprecated, for older EPM versions)
  [2] Modern Endpoints API (recommended for EPM v25.4+)

Enter choice (1 or 2): 2

Using Modern Endpoints API...

Getting endpoints: currently on page 1
Getting endpoints: currently on page 2
Total endpoints retrieved: 1547

[... duplicate display and confirmation ...]

Do you want to proceed with deletion? Type 'yes' to confirm: yes

Starting deletion process...
[... deletion progress ...]

============================================
  DELETION COMPLETE
============================================

  Total endpoints processed: 12
```

---



## Troubleshooting



### Authentication Errors



#### "EPM authentication failed"

**Possible causes:**

- Incorrect username or password
- Account is locked or disabled
- Wrong EPM cloud environment selected

**Solutions:**

1. Verify your credentials by logging into the EPM console manually
2. Check if your account is locked in EPM Administration
3. Ensure you selected the correct cloud environment (Commercial vs. US Government)



#### "OAuth2 authentication failed"

**Possible causes:**

- Incorrect Identity subdomain
- Wrong app alias
- Service user not bound to the web app
- Service user not assigned to an EPM role

**Solutions:**

1. Verify the Identity subdomain from your Identity console URL
2. Check the app alias in Identity Admin → Apps → Your App → Settings
3. Ensure the service user is bound in the app's Tokens tab
4. Verify the service user has an EPM role with API permissions



### API Errors



#### "Parameter limit must be between 1 and 1000"

This error occurs when using the Modern Endpoints API with an invalid page size. The script has been updated to use the correct limit of 1000.

#### "Error retrieving endpoints/computers"

**Possible causes:**

- Invalid Set ID
- Insufficient permissions
- Network connectivity issues

**Solutions:**

1. Verify the Set ID is correct (copy from EPM console URL)
2. Ensure your account has permission to view endpoints in this set
3. Check network connectivity to EPM cloud services



### No Duplicates Found

If the script reports "No duplicates found" but you expect duplicates:

1. Verify you're checking the correct Set ID
2. Duplicates are identified by **exact hostname match** (case-sensitive)
3. Ensure the endpoints exist in the EPM console

---



## FAQ



### Q: Will this uninstall the EPM agent from my computers?

**A:** No. This script only removes the endpoint record from the EPM console. The EPM agent remains installed on the actual machine. To fully remove an agent, use the EPM Uninstall feature or manually uninstall from the endpoint.

### Q: How does the script determine which endpoint to keep?

**A:** The script keeps the endpoint with the **most recent install time** for each hostname. All older installations are marked for deletion.

### Q: Can I run this script in a scheduled task?

**A:** The current version is interactive and requires user input. For automation, you would need to modify the script to accept parameters instead of prompts.

### Q: What happens if I have thousands of duplicates?

**A:** The script handles large numbers efficiently:

- **Legacy API:** Deletes one at a time with 6-second delays (API rate limit)
- **Modern API:** Batch deletes up to 10 endpoints per API call with 6-second delays between batches



### Q: Is it safe to run this in production?

**A:** The script includes a confirmation step before any deletions. Always review the list of endpoints to be deleted before typing "yes" to confirm. Consider testing in a non-production set first.

### Q: Which API version should I use?

**A:** 

- Use **Modern Endpoints API** if your EPM version is 25.4 or later and you've activated the new Endpoints page
- Use **Legacy Computers API** for older EPM versions or if you haven't migrated to the new endpoint management



### Q: How do I find my Set ID?

**A:** 

1. Log into the EPM console
2. Navigate to the Set you want to clean up
3. Look at the URL - the Set ID is the GUID in the URL path
  - Example: `https://mycompany.epm.cyberark.com/Sets/398a88e0-0276-4473-ba06-c986626029ae/...`
  - Set ID: `398a88e0-0276-4473-ba06-c986626029ae`

---



## Support

For issues with:

- **This script:** Review the troubleshooting section above
- **Idira EPM:** Contact CyberArk Support or consult the [EPM Documentation](https://docs.cyberark.com/epm/latest/en/content/resources/_topnav/cc_home.htm)
- **Idira Identity:** Consult the [Manage](https://docs.cyberark.com/manage/latest/en/content/resources/_topnav/cc_home.htm) and [Setup](https://docs.cyberark.com/setup/latest/en/content/resources/_topnav/cc_home.htm) spaces

---



## Version History


| Version | Date    | Changes                                                       |
| ------- | ------- | ------------------------------------------------------------- |
| 1.0     | Initial | Original script with Legacy Computers API                     |
| 2.0     | Updated | Added Modern Endpoints API support                            |
| 3.0     | Updated | Added OAuth2 authentication via CyberArk Identity             |
| 4.0     | Updated | Made script fully interactive with enhanced duplicate display |


