{\rtf1\ansi\ansicpg1252\cocoartf2870
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 # EPM Stale Endpoint Cleanup Script\
\
A PowerShell script that connects to **CyberArk Endpoint Privilege Manager (EPM)**, identifies endpoint agents that haven't checked in recently (or, optionally, that were installed a long time ago), and deletes them from your EPM Set. It supports both the legacy Computers API and the modern Endpoints API, and both legacy username/password auth and modern OAuth2 (CyberArk Identity/ISPSS) auth.\
\
> \uc0\u9888 \u65039  **This is a destructive operation.** Deleted endpoints are removed from EPM (the agent itself is *not* uninstalled from the machine). Always review the preview list before confirming deletion, and test in a non-production Set first if possible.\
\
---\
\
## Table of contents\
\
- [What this script does](#what-this-script-does)\
- [Prerequisites](#prerequisites)\
- [Installation](#installation)\
- [Running the script](#running-the-script)\
  - [1. Set ID and staleness threshold](#1-set-id-and-staleness-threshold)\
  - [2. Choosing a date field](#2-choosing-a-date-field)\
  - [3. Authenticating](#3-authenticating)\
  - [4. Choosing an API version](#4-choosing-an-api-version)\
  - [5. Review and confirm deletion](#5-review-and-confirm-deletion)\
- [How staleness is determined](#how-staleness-is-determined)\
- [Rate limiting and batching](#rate-limiting-and-batching)\
- [Troubleshooting](#troubleshooting)\
- [Disclaimer](#disclaimer)\
\
---\
\
## What this script does\
\
1. Prompts you for an EPM **Set ID** and a **stale threshold** in days.\
2. Retrieves the full list of endpoints/computers in that Set (paginated automatically).\
3. Flags any endpoint that hasn't connected (or wasn't installed, depending on your choice) within the threshold as **stale**.\
4. Shows you the full list of stale endpoints before doing anything.\
5. On explicit confirmation, deletes the stale endpoints from EPM in batches, respecting API rate limits.\
\
## Prerequisites\
\
- **PowerShell 5.1+** (Windows PowerShell) or **PowerShell 7+** (cross-platform).\
- Network access to your EPM cloud tenant.\
- An EPM account with permissions to view and delete endpoints in the target Set, provisioned via **one** of:\
  - **Legacy EPM authentication** \'97 an EPM username/password (and optionally an Application ID).\
  - **Modern OAuth2 (CyberArk Identity / ISPSS)** \'97 a service user created in Identity Administration, bound to a custom EPM API web app, with API permissions on an EPM role. See [Authenticating](#3-authenticating) below for the exact setup.\
- Your **EPM Set ID** for the Set you want to clean up.\
\
## Installation\
\
Clone the repo (or just download the `.ps1` file) and keep it somewhere convenient:\
\
```bash\
git clone https://github.com/<your-org>/<your-repo>.git\
cd <your-repo>\
```\
\
No modules need to be installed \'97 the script only uses built-in PowerShell cmdlets (`Invoke-RestMethod`, etc.).\
\
## Running the script\
\
From a PowerShell prompt:\
\
```powershell\
.\\EPM-DeleteStaleEndpoints.ps1\
```\
\
The script is fully interactive \'97 it will prompt you for everything it needs, step by step.\
\
### 1. Set ID and staleness threshold\
\
You'll first be asked for:\
\
- **EPM Set ID** \'97 the numeric ID of the Set containing the endpoints you want to evaluate.\
- **Number of days** \'97 endpoints that haven't connected (or been installed) within this many days are considered stale. Must be a whole number \uc0\u8805  1.\
\
The script computes a cutoff date (`now - N days`) and displays it so you can sanity-check it before proceeding.\
\
### 2. Choosing a date field\
\
You choose which timestamp to evaluate staleness against:\
\
| Choice | Field | Meaning |\
|---|---|---|\
| `1` | **Last Connected** *(recommended)* | When the endpoint last communicated with EPM |\
| `2` | **Install Time** | When the agent was first installed |\
\
If you enter something invalid, the script defaults to **Last Connected**.\
\
> **Note on Last Connected + the modern API:** when you're on the modern Endpoints API and evaluating **Last Connected**, the script first checks each endpoint's `connectionStatus`. If an endpoint is currently `Connected`, its `lastConnected` value is ignored entirely and it's treated as **not stale** \'97 a live connection is a stronger signal than a potentially stale-looking timestamp. Only endpoints that are **not** `Connected` (e.g., `Disconnected`) have their `lastConnected` date compared against the cutoff.\
\
### 3. Authenticating\
\
You'll be asked to choose an authentication method:\
\
**`1` \'97 Legacy EPM Authentication**\
- Choose your EPM cloud environment: Commercial, US Government, or a custom dispatcher URL.\
- Enter your EPM username and password (password entry is masked).\
- Optionally supply an Application ID (defaults to `PowerShell-EPM-Script` if left blank).\
\
**`2` \'97 Modern OAuth2 via CyberArk Identity (ISPSS)**\
\
Before using this option, make sure you have:\
- A service user created in Identity Administration.\
- A custom EPM API web app configured in Identity.\
- The service user bound to that web app.\
- The service user assigned to an EPM role with API permissions.\
\
You'll then be prompted for:\
- Your **Identity tenant subdomain** (e.g. `abc1234` from `abc1234.id.cyberark.cloud`).\
- The **OAuth app alias** configured in Identity Administration.\
- The **service user** (e.g. `svc-epm-api@mycompany.cyberark.cloud`) and its password (masked).\
- Your **EPM server name** (the subdomain from your EPM console URL, e.g. `mycompany` from `mycompany.epm.cyberark.com`).\
\
The script performs a client-credentials OAuth2 flow against Identity and uses the resulting bearer token for all subsequent EPM API calls.\
\
### 4. Choosing an API version\
\
| Choice | API | Notes |\
|---|---|---|\
| `1` | **Legacy Computers API** | Deprecated; supported for older EPM versions. Paginates at 2,500 records/page. |\
| `2` | **Modern Endpoints API** | Recommended for EPM v25.4+. Paginates at 1,000 records/page, and is the only mode that supports the `connectionStatus` check described above. |\
\
The script retrieves every page of results automatically and reports the total count.\
\
### 5. Review and confirm deletion\
\
Once staleness analysis finishes, the script prints:\
\
- A summary count of stale endpoints found.\
- A formatted table (capped at the first 100 rows for readability) showing name, ID, and the relevant date.\
- An explicit warning that this will **permanently remove** those endpoints from EPM (agents are not uninstalled).\
\
You must type **`yes`** at the confirmation prompt to proceed. Anything else cancels the run with no changes made.\
\
If you confirm, deletion proceeds:\
- **Modern API:** endpoints are deleted in batches of 10 via a single filtered `Endpoints/delete` call per batch.\
- **Legacy API:** computers are deleted one at a time via individual `DELETE` calls.\
\
A final summary reports how many were deleted and how many errors occurred, if any.\
\
## How staleness is determined\
\
For each endpoint/computer, the relevant date field is compared to the cutoff date:\
\
- **Date present and older than cutoff** \uc0\u8594  stale, marked for deletion.\
- **Date present and within threshold** \uc0\u8594  not stale, left alone.\
- **Date missing/empty** \uc0\u8594  treated as stale (never connected).\
- **Date field is unparseable** \uc0\u8594  skipped (left alone) rather than risking an incorrect deletion.\
- **Modern API + Last Connected + `connectionStatus = Connected`** \uc0\u8594  always treated as not stale, regardless of the `lastConnected` timestamp.\
\
## Rate limiting and batching\
\
CyberArk EPM's cloud APIs are rate-limited. The script accounts for this:\
\
- **Modern API:** batches of 10 endpoints per delete call, with a 6-second pause between batches.\
- **Legacy API:** a 6-second pause between each individual delete call.\
\
For very large stale lists, expect the deletion phase to take a while \'97 this is intentional, to stay within the ~20 calls per 2 minutes limit.\
\
## Troubleshooting\
\
- **"EPM authentication failed"** \'97 double-check your dispatcher URL/environment choice, username, and password.\
- **"OAuth2 authentication failed"** \'97 verify the Identity subdomain, app alias, service user credentials, that the service user is bound to the web app under its Tokens tab, and that it's assigned to an EPM role with API access.\
- **"Error retrieving computers/endpoints"** \'97 usually a permissions or Set ID issue; confirm the account can view the target Set.\
- **Endpoints missing dates showing as stale unexpectedly** \'97 this is by design (no date = never connected = stale). If that's not what you want, review the endpoint manually before running deletion.\
\
## Disclaimer\
\
This script is provided for educational purposes only. Use at your own risk \'97 the author assumes no liability for damages or issues arising from its use. Always test against a non-production Set and confirm the preview list carefully before typing `yes`.}