# CyberArk EPM SSL Inspection Tester

A PowerShell script to detect SSL/TLS inspection on CyberArk Endpoint Privilege Manager (EPM) service URLs. This tool helps identify if your organization's proxy or firewall is performing SSL decryption on EPM traffic, which can cause agent communication issues.

## 📋 Table of Contents

- [Overview](#overview)
- [Why SSL Inspection Matters](#why-ssl-inspection-matters)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
  - [Interactive Mode](#interactive-mode)
  - [Command Line Mode](#command-line-mode)
- [Understanding the Results](#understanding-the-results)
- [Supported Regions](#supported-regions)
- [Troubleshooting](#troubleshooting)
- [References](#references)

## Overview

The EPM SSL Inspection Tester checks SSL certificates for CyberArk EPM service URLs and reports:

- **Certificate Subject** - Who the certificate was issued to
- **Certificate Issuer** - The Certificate Authority (CA) that signed the certificate
- **Expiration Date** - When the certificate expires
- **SSL Inspection Status** - Whether SSL inspection is likely occurring

## Why SSL Inspection Matters

CyberArk EPM requires secure, unmodified TLS connections between endpoints and the EPM cloud service. According to [CyberArk's documentation](https://docs.cyberark.com/epm/latest/en/content/installation/network-setup.htm):

> Bypass SSL inspection for destinations used by the new endpoint management service, including the EPM service URLs. Do not terminate or re-sign the TLS session used for endpoint management service communication.

If SSL inspection is occurring, you may experience:
- Agent registration failures
- Policy update issues
- Real-time communication problems
- Certificate validation errors

### Expected Certificate Issuers

| URL Type | Expected Issuer |
|----------|-----------------|
| Tenant URLs (`*.epm.cyberark.com`) | Cloudflare Inc, Google Trust Services |
| S3/Download URLs | Amazon |
| Agent Communication URLs | Amazon |

If you see a different issuer (e.g., your organization's internal CA, Palo Alto Networks, Zscaler, etc.), SSL inspection is likely occurring.

## Prerequisites

- **Windows PowerShell 5.1** or **PowerShell 7+**
- Network access to CyberArk EPM URLs (port 443)
- No special permissions required

## Installation

1. Download the script:
   ```powershell
   # Clone the repository
   git clone https://github.com/yourusername/EPMScripts.git
   
   # Or download just the script
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/yourusername/EPMScripts/main/SSL%20Inspection/Test-EPM-SSLInspection.ps1" -OutFile "Test-EPM-SSLInspection.ps1"
   ```

2. Unblock the script (if downloaded from the internet):
   ```powershell
   Unblock-File -Path ".\Test-EPM-SSLInspection.ps1"
   ```

## Usage

### Interactive Mode

Simply run the script without parameters for a guided experience:

```powershell
.\Test-EPM-SSLInspection.ps1
```

You'll see the main menu:

```
  ╔════════════════════════════════════════════════════════════╗
  ║           CyberArk EPM SSL Inspection Tester               ║
  ╠════════════════════════════════════════════════════════════╣
  ║  This tool checks SSL certificates for EPM service URLs    ║
  ║  to detect if SSL inspection/decryption is occurring.      ║
  ╚════════════════════════════════════════════════════════════╝

  How would you like to test?

    [1] Select a region
        Test all URLs for a specific region

    [2] Enter a specific server
        Test a single tenant server (e.g., NA123, EU140)
```

#### Option 1: Select a Region

Choose this option to test all EPM URLs for a specific region. This includes:
- All tenant server URLs for that region
- S3/download URLs
- Agent communication URLs

```
  Select your EPM region:

     [1] AU - Australia (8 URLs)
     [2] BR - Brazil (5 URLs)
     [3] CA - Canada (9 URLs)
     [4] CH - Switzerland (5 URLs)
     [5] AE - UAE (4 URLs)
     [6] EU - Germany/EU (27 URLs)
     [7] IL - Israel (5 URLs)
     [8] IN - India (9 URLs)
     [9] IT - Italy (8 URLs)
    [10] JP - Japan (7 URLs)
    [11] SG - Singapore (8 URLs)
    [12] UK - United Kingdom (10 URLs)
    [13] NA - USA (North America) (78 URLs)
    [14] FED - US Federal (GovCloud) (4 URLs)

  Enter selection (1-14 or region code): _
```

#### Option 2: Enter a Specific Server

If you know your specific EPM tenant server (visible in your EPM console URL), enter it directly:

```
  Enter your specific EPM server:

  Format: <Region><Number>
  Examples: NA123, EU140, AU126, UK149, SVC107, SVC8

  Valid region prefixes:
    NA, EU, AU, BR, CA, CH, IL, IN, IT, JP, SG, UK, SVC

  Enter server name: NA123
```

This will test:
1. Your specific tenant URL (e.g., `https://NA123.epm.cyberark.com`)
2. The regional login URL
3. S3/download URLs for your region
4. Agent communication URLs for your region

### Command Line Mode

For automation or scripting, specify the region directly:

```powershell
# Test a specific region
.\Test-EPM-SSLInspection.ps1 -Region NA

# Test EU region
.\Test-EPM-SSLInspection.ps1 -Region EU
```

## Understanding the Results

### Sample Output

```
================================================
  Testing Server: NA123
  Region: USA (NA)
================================================

[Tenant URL - Specific Server]
  Testing: https://NA123.epm.cyberark.com

================================================================
  SSL INSPECTION TEST RESULTS
  Region: Server: NA123 (USA)
================================================================

--------------------------------------------------
URL:            https://NA123.epm.cyberark.com
Type:           Tenant
Subject:        CN=epm.cyberark.com, O="CyberArk Software Ltd.", L=Petah Tikva, C=IL
Issuer:         CN=Cloudflare Inc ECC CA-3, O="Cloudflare, Inc.", C=US
Expires:        2025-07-15 23:59:59
SSL Inspection: Not Detected
```

### Result Fields

| Field | Description |
|-------|-------------|
| **URL** | The EPM service URL that was tested |
| **Type** | URL category (Tenant, S3/Downloads, Agent) |
| **Subject** | The entity the certificate was issued to |
| **Issuer** | The Certificate Authority that signed the certificate |
| **Expires** | Certificate expiration date |
| **SSL Inspection** | Detection status (see below) |

### SSL Inspection Status

| Status | Meaning | Action |
|--------|---------|--------|
| ✅ **Not Detected** | Certificate issuer matches expected CAs | No action needed |
| ❌ **LIKELY DETECTED** | Certificate issuer is unexpected | Configure SSL bypass |

### Exporting Results

After testing, you'll be prompted to export results to CSV:

```
  Export results to CSV? (Y/N): Y
  Results exported to: EPM_SSL_Inspection_Results_NA123_20260930_173000.csv
```

The CSV includes all test data for documentation or further analysis.

## Supported Regions

| Code | Region | Login URL |
|------|--------|-----------|
| AU | Australia | au.epm.cyberark.com |
| BR | Brazil | br.epm.cyberark.com |
| CA | Canada | ca.epm.cyberark.com |
| CH | Switzerland | ch.epm.cyberark.com |
| AE | UAE | ae.epm.cyberark.com |
| EU | Germany/EU | eu.epm.cyberark.com |
| IL | Israel | il.epm.cyberark.com |
| IN | India | in.epm.cyberark.com |
| IT | Italy | it.epm.cyberark.com |
| JP | Japan | jp.epm.cyberark.com |
| SG | Singapore | sg.epm.cyberark.com |
| UK | United Kingdom | uk.epm.cyberark.com |
| NA | USA | login.epm.cyberark.com |
| FED | US Federal | login.epm.cyberarkgov.cloud |

## Troubleshooting

### SSL Inspection Detected

If SSL inspection is detected, work with your network/security team to:

1. **Add SSL bypass rules** for the following domains:
   - `*.epm.cyberark.com`
   - `agents-*.epm.cyberark.com`
   - `files-*.epm.cyberark.com`
   - `epm-downloads*.s3.*.amazonaws.com`

2. **For US Federal environments**, also bypass:
   - `*.epm.cyberarkgov.cloud`
   - `*.iot.us-gov-west-1.amazonaws.com`

### Connection Errors

If you see connection errors:

1. **Check network connectivity** - Ensure port 443 is open to EPM URLs
2. **Check proxy settings** - The script uses system proxy settings
3. **Check firewall rules** - Verify EPM URLs are allowed

### Script Execution Policy

If you receive an execution policy error:

```powershell
# Option 1: Run with bypass for this session
powershell -ExecutionPolicy Bypass -File .\Test-EPM-SSLInspection.ps1

# Option 2: Unblock the specific file
Unblock-File -Path .\Test-EPM-SSLInspection.ps1
```

## References

- [CyberArk EPM Network Setup Documentation](https://docs.cyberark.com/epm/latest/en/content/installation/network-setup.htm)
- [CyberArk EPM Service URLs by Region](https://docs.cyberark.com/epm/latest/en/content/installation/network-setup.htm#ServiceURLsforaspecificregion)
- [Required Root Certificates for EPM](https://docs.cyberark.com/epm/latest/en/content/installation/network-setup.htm#Networkprerequisites)

## License

This script is provided as-is for troubleshooting purposes. Use at your own discretion.

## Contributing

Contributions are welcome! Please submit issues or pull requests for:
- New region support
- Bug fixes
- Documentation improvements
