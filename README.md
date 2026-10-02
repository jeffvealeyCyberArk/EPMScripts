# EPMScripts

Repo for scripts for customers to use.

This repository contains PowerShell and Bash utilities for administering **CyberArk Endpoint Privilege Manager (EPM)**. Each script lives in its own folder and is meant to be run independently.

## Repository structure

```
EPMScripts/
├── Delete Duplicate Endpoints/
├── Delete Stale Endpoints/
├── SSL Inspection/
└── .gitignore
```

| Folder | Purpose |
|---|---|
| [`Delete Duplicate Endpoints`](./Delete%20Duplicate%20Endpoints) | Identifies and removes duplicate endpoint agent entries from an EPM Set. See the script/README inside this folder for setup and usage details. |
| [`Delete Stale Endpoints`](./Delete%20Stale%20Endpoints) | Identifies and removes endpoint agents that haven't connected (or been installed) within a configurable number of days. Supports both the legacy Computers API and the modern Endpoints API, and both legacy and OAuth2 (CyberArk Identity/ISPSS) authentication. See the script/README inside this folder for setup and usage details. |
| [`SSL Inspection`](./SSL%20Inspection) | Tests SSL/TLS certificates for CyberArk EPM service URLs to detect if SSL inspection/decryption is occurring. Helps identify proxy or firewall configurations that may cause agent communication issues. Supports all EPM regions and can test by region or specific tenant server. **Available for both Windows (PowerShell) and macOS/Linux (Bash).** See the script/README inside this folder for setup and usage details. |

> Each folder is self-contained — open it for the script itself and any folder-specific documentation before running anything against a production EPM tenant.

## Getting started

### Prerequisites

- **PowerShell 5.1+** (Windows PowerShell) or **PowerShell 7+** (cross-platform) for PowerShell scripts.
- **Bash** and **curl** for the SSL Inspection shell script (macOS/Linux).
- Network access to your EPM cloud tenant.
- An EPM account (or service user) with sufficient permissions in the target Set for the action the script performs — see the individual script's documentation for exact requirements.
- Your EPM **Set ID** (for delete scripts).

### Running a script

1. Clone the repo:
   ```bash
   git clone https://github.com/jeffvealeyCyberArk/EPMScripts.git
   cd EPMScripts
   ```
2. Open the folder for the script you want to use.
3. Run it from a PowerShell or Bash prompt, e.g.:

   **PowerShell (Windows):**
   ```powershell
   cd "Delete Stale Endpoints"
   .\EPM-DeleteStaleEndpoints.ps1
   ```

   **Bash (macOS/Linux) — SSL Inspection only:**
   ```bash
   cd "SSL Inspection"
   chmod +x Test-EPM-SSLInspection.sh
   ./Test-EPM-SSLInspection.sh
   ```
4. Follow the interactive prompts — each script will ask for the EPM Set ID, authentication details, and any script-specific options before taking action.

## ⚠️ Safety notes

Some scripts in this repo perform **destructive operations** (deleting endpoint entries from EPM). Before running any delete script against a production Set:

- Review the preview/confirmation output the script shows before it deletes anything.
- Test against a non-production Set first, if one is available.
- Confirm you understand what "delete" means for that specific script (e.g., deleting an endpoint entry from EPM does **not** uninstall the agent from the machine).

> **Note:** The SSL Inspection scripts are read-only and do not modify any EPM data — they only test SSL certificates to detect inspection.

## Disclaimer

These scripts are provided for educational purposes only, as-is, with no warranty. Use at your own risk — the author assumes no liability for any damages or issues caused by their use.

## Contributing

This repo is intended for customer use. If you find an issue or want to suggest an improvement, please open an [issue](https://github.com/jeffvealeyCyberArk/EPMScripts/issues) or submit a pull request.
