<#
.SYNOPSIS
    Tests SSL/TLS certificates for Idira EPM service URLs to detect SSL inspection.

.DESCRIPTION
    This script checks SSL certificates for Idira EPM service URLs across different regions.
    It retrieves and displays the Subject and Issuer of each certificate to help identify
    if SSL inspection is being performed by a proxy or firewall.

    Expected issuers for legitimate Idira EPM certificates:
    - Tenant URLs: Cloudflare Inc (via Google Trust Services or similar)
    - S3 URLs: Amazon (via Amazon Trust Services)
    - Agent URLs: Amazon (via Amazon Trust Services)

    If the issuer shows your organization's internal CA or a security appliance,
    SSL inspection is likely occurring and should be bypassed for EPM traffic.

.PARAMETER Region
    The region code to test. Valid values: AU, BR, CA, EU, IN, IL, IT, JP, SG, CH, AE, UK, NA, FED
    If not specified, the script will prompt for selection.

.EXAMPLE
    .\Test-EPM-SSLInspection.ps1
    Runs interactively and prompts for region selection or specific server entry.

.EXAMPLE
    .\Test-EPM-SSLInspection.ps1 -Region NA
    Tests all URLs for the USA (NA) region.

.NOTES
    Reference: https://docs.cyberark.com/epm/latest/en/content/installation/network-setup.htm
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("AU", "BR", "CA", "EU", "IN", "IL", "IT", "JP", "SG", "CH", "AE", "UK", "NA", "FED")]
    [string]$Region
)

# Ignore SSL certificate validation errors to allow inspection of any certificate
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# EPM Service URLs by Region
# Source: https://docs.cyberark.com/epm/latest/en/content/installation/network-setup.htm
# Tenant server list from EPM Servers List.csv
$EPMRegions = @{
    "AU" = @{
        Name = "Australia"
        TenantURLs = @(
            "https://au.epm.cyberark.com"
            "https://AU126.epm.cyberark.com"
            "https://AU138.epm.cyberark.com"
            "https://AU151.epm.cyberark.com"
            "https://AU185.epm.cyberark.com"
        )
        S3URLs = @(
            "https://epm-downloads-au.s3.ap-southeast-2.amazonaws.com"
            "https://files-au.epm.cyberark.com"
        )
        AgentURLs = @(
            "https://agents-au.epm.cyberark.com"
        )
    }
    "BR" = @{
        Name = "Brazil"
        TenantURLs = @(
            "https://br.epm.cyberark.com"
            "https://BR233.epm.cyberark.com"
        )
        S3URLs = @(
            "https://epm-downloads-br.s3.sa-east-1.amazonaws.com"
            "https://files-br.epm.cyberark.com"
        )
        AgentURLs = @(
            "https://agents-br.epm.cyberark.com"
        )
    }
    "CA" = @{
        Name = "Canada"
        TenantURLs = @(
            "https://ca.epm.cyberark.com"
            "https://CA127.epm.cyberark.com"
            "https://CA139.epm.cyberark.com"
            "https://CA150.epm.cyberark.com"
            "https://CA176.epm.cyberark.com"
            "https://CA211.epm.cyberark.com"
        )
        S3URLs = @(
            "https://epm-downloads-ca.s3.ca-central-1.amazonaws.com"
            "https://files-ca.epm.cyberark.com"
        )
        AgentURLs = @(
            "https://agents-ca.epm.cyberark.com"
        )
    }
    "EU" = @{
        Name = "Germany"
        TenantURLs = @(
            "https://eu.epm.cyberark.com"
            "https://SVC8.epm.cyberark.com"
            "https://EU124.epm.cyberark.com"
            "https://EU131.epm.cyberark.com"
            "https://EU140.epm.cyberark.com"
            "https://EU145.epm.cyberark.com"
            "https://EU155.epm.cyberark.com"
            "https://EU162.epm.cyberark.com"
            "https://EU164.epm.cyberark.com"
            "https://EU165.epm.cyberark.com"
            "https://EU166.epm.cyberark.com"
            "https://EU167.epm.cyberark.com"
            "https://EU169.epm.cyberark.com"
            "https://EU187.epm.cyberark.com"
            "https://EU191.epm.cyberark.com"
            "https://EU192.epm.cyberark.com"
            "https://EU200.epm.cyberark.com"
            "https://EU208.epm.cyberark.com"
            "https://EU219.epm.cyberark.com"
            "https://EU232.epm.cyberark.com"
            "https://EU239.epm.cyberark.com"
            "https://EU240.epm.cyberark.com"
            "https://EU247.epm.cyberark.com"
            "https://EU248.epm.cyberark.com"
        )
        S3URLs = @(
            "https://epm-downloads-eu.s3.eu-central-1.amazonaws.com"
            "https://files-eu.epm.cyberark.com"
        )
        AgentURLs = @(
            "https://agents-eu.epm.cyberark.com"
        )
    }
    "IN" = @{
        Name = "India"
        TenantURLs = @(
            "https://in.epm.cyberark.com"
            "https://IN129.epm.cyberark.com"
            "https://IN141.epm.cyberark.com"
            "https://IN146.epm.cyberark.com"
            "https://IN152.epm.cyberark.com"
            "https://IN175.epm.cyberark.com"
        )
        S3URLs = @(
            "https://epm-downloads-in.s3.ap-south-1.amazonaws.com"
            "https://files-in.epm.cyberark.com"
        )
        AgentURLs = @(
            "https://agents-in.epm.cyberark.com"
        )
    }
    "IL" = @{
        Name = "Israel"
        TenantURLs = @(
            "https://il.epm.cyberark.com"
            "https://IL231.epm.cyberark.com"
        )
        S3URLs = @(
            "https://epm-downloads-il.s3.il-central-1.amazonaws.com"
            "https://files-il.epm.cyberark.com"
        )
        AgentURLs = @(
            "https://agents-il.epm.cyberark.com"
        )
    }
    "IT" = @{
        Name = "Italy"
        TenantURLs = @(
            "https://it.epm.cyberark.com"
            "https://IT178.epm.cyberark.com"
            "https://IT179.epm.cyberark.com"
            "https://IT216.epm.cyberark.com"
            "https://IT238.epm.cyberark.com"
        )
        S3URLs = @(
            "https://epm-downloads-it.s3.eu-south-1.amazonaws.com"
            "https://files-it.epm.cyberark.com"
        )
        AgentURLs = @(
            "https://agents-it.epm.cyberark.com"
        )
    }
    "JP" = @{
        Name = "Japan"
        TenantURLs = @(
            "https://jp.epm.cyberark.com"
            "https://JP130.epm.cyberark.com"
            "https://JP142.epm.cyberark.com"
            "https://JP153.epm.cyberark.com"
        )
        S3URLs = @(
            "https://epm-downloads-jp.s3.ap-northeast-1.amazonaws.com"
            "https://files-jp.epm.cyberark.com"
        )
        AgentURLs = @(
            "https://agents-jp.epm.cyberark.com"
        )
    }
    "SG" = @{
        Name = "Singapore"
        TenantURLs = @(
            "https://sg.epm.cyberark.com"
            "https://SG144.epm.cyberark.com"
            "https://SG147.epm.cyberark.com"
            "https://SG154.epm.cyberark.com"
            "https://SG201.epm.cyberark.com"
        )
        S3URLs = @(
            "https://epm-downloads-sg.s3.ap-southeast-1.amazonaws.com"
            "https://files-sg.epm.cyberark.com"
        )
        AgentURLs = @(
            "https://agents-sg.epm.cyberark.com"
        )
    }
    "CH" = @{
        Name = "Switzerland"
        TenantURLs = @(
            "https://ch.epm.cyberark.com"
            "https://CH195.epm.cyberark.com"
        )
        S3URLs = @(
            "https://epm-downloads-ch.s3.eu-central-2.amazonaws.com"
            "https://files-ch.epm.cyberark.com"
        )
        AgentURLs = @(
            "https://agents-ch.epm.cyberark.com"
        )
    }
    "AE" = @{
        Name = "UAE"
        TenantURLs = @(
            "https://ae.epm.cyberark.com"
        )
        S3URLs = @(
            "https://epm-downloads-ae.s3.me-central-1.amazonaws.com"
            "https://files-ae.epm.cyberark.com"
        )
        AgentURLs = @(
            "https://agents-ae.epm.cyberark.com"
        )
    }
    "UK" = @{
        Name = "UK"
        TenantURLs = @(
            "https://uk.epm.cyberark.com"
            "https://UK125.epm.cyberark.com"
            "https://UK143.epm.cyberark.com"
            "https://UK149.epm.cyberark.com"
            "https://UK174.epm.cyberark.com"
            "https://UK196.epm.cyberark.com"
            "https://UK210.epm.cyberark.com"
        )
        S3URLs = @(
            "https://epm-downloads-uk.s3.eu-west-2.amazonaws.com"
            "https://files-uk.epm.cyberark.com"
        )
        AgentURLs = @(
            "https://agents-uk.epm.cyberark.com"
        )
    }
    "NA" = @{
        Name = "USA"
        TenantURLs = @(
            "https://login.epm.cyberark.com"
            "https://NA109.epm.cyberark.com"
            "https://NA110.epm.cyberark.com"
            "https://NA111.epm.cyberark.com"
            "https://NA112.epm.cyberark.com"
            "https://NA113.epm.cyberark.com"
            "https://NA114.epm.cyberark.com"
            "https://NA115.epm.cyberark.com"
            "https://NA116.epm.cyberark.com"
            "https://NA117.epm.cyberark.com"
            "https://NA118.epm.cyberark.com"
            "https://NA119.epm.cyberark.com"
            "https://NA120.epm.cyberark.com"
            "https://NA121.epm.cyberark.com"
            "https://NA122.epm.cyberark.com"
            "https://NA123.epm.cyberark.com"
            "https://NA128.epm.cyberark.com"
            "https://NA132.epm.cyberark.com"
            "https://NA133.epm.cyberark.com"
            "https://NA134.epm.cyberark.com"
            "https://NA135.epm.cyberark.com"
            "https://NA136.epm.cyberark.com"
            "https://NA137.epm.cyberark.com"
            "https://NA148.epm.cyberark.com"
            "https://NA156.epm.cyberark.com"
            "https://NA157.epm.cyberark.com"
            "https://NA159.epm.cyberark.com"
            "https://NA160.epm.cyberark.com"
            "https://NA161.epm.cyberark.com"
            "https://NA163.epm.cyberark.com"
            "https://NA168.epm.cyberark.com"
            "https://NA170.epm.cyberark.com"
            "https://NA171.epm.cyberark.com"
            "https://NA172.epm.cyberark.com"
            "https://NA173.epm.cyberark.com"
            "https://NA177.epm.cyberark.com"
            "https://NA180.epm.cyberark.com"
            "https://NA181.epm.cyberark.com"
            "https://NA182.epm.cyberark.com"
            "https://NA183.epm.cyberark.com"
            "https://NA184.epm.cyberark.com"
            "https://NA186.epm.cyberark.com"
            "https://NA188.epm.cyberark.com"
            "https://NA190.epm.cyberark.com"
            "https://NA193.epm.cyberark.com"
            "https://NA194.epm.cyberark.com"
            "https://NA197.epm.cyberark.com"
            "https://NA198.epm.cyberark.com"
            "https://NA199.epm.cyberark.com"
            "https://NA202.epm.cyberark.com"
            "https://NA203.epm.cyberark.com"
            "https://NA204.epm.cyberark.com"
            "https://NA206.epm.cyberark.com"
            "https://NA207.epm.cyberark.com"
            "https://NA220.epm.cyberark.com"
            "https://NA221.epm.cyberark.com"
            "https://NA222.epm.cyberark.com"
            "https://NA223.epm.cyberark.com"
            "https://NA224.epm.cyberark.com"
            "https://NA225.epm.cyberark.com"
            "https://NA226.epm.cyberark.com"
            "https://NA227.epm.cyberark.com"
            "https://NA228.epm.cyberark.com"
            "https://NA229.epm.cyberark.com"
            "https://NA230.epm.cyberark.com"
            "https://NA234.epm.cyberark.com"
            "https://NA235.epm.cyberark.com"
            "https://NA236.epm.cyberark.com"
            "https://NA237.epm.cyberark.com"
            "https://NA241.epm.cyberark.com"
            "https://NA242.epm.cyberark.com"
            "https://NA243.epm.cyberark.com"
        )
        S3URLs = @(
            "https://epm-downloads.s3.us-east-2.amazonaws.com"
            "https://files-na.epm.cyberark.com"
        )
        AgentURLs = @(
            "https://agents-na.epm.cyberark.com"
        )
    }
    "FED" = @{
        Name = "US FedRAMP"
        TenantURLs = @(
            "https://login.epm.cyberarkgov.cloud"
            "https://NA01.epm.cyberarkgov.cloud"
            "https://NA02.epm.cyberarkgov.cloud"
            "https://NA03.epm.cyberarkgov.cloud"
            "https://NA04.epm.cyberarkgov.cloud"
            "https://NA05.epm.cyberarkgov.cloud"
            "https://NA06.epm.cyberarkgov.cloud"
        )
        S3URLs = @(
            "https://epm-epmprod-us-gov-west-1-epm-downloads.s3-us-gov-west-1.amazonaws.com"
            "https://files.epm.cyberarkgov.cloud"
        )
        AgentURLs = @(
            "https://apro78z9ol93v-ats.iot.us-gov-west-1.amazonaws.com"
        )
    }
}

function Test-SSLCertificate {
    <#
    .SYNOPSIS
        Tests SSL certificate for a given URL and returns certificate details.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        
        [Parameter(Mandatory = $false)]
        [string]$UrlType = "Unknown"
    )

    $result = [PSCustomObject]@{
        URL            = $Uri
        URLType        = $UrlType
        Subject        = $null
        Issuer         = $null
        Expires        = $null
        Status         = "Unknown"
        SSLInspection  = "Unknown"
        Error          = $null
    }

    try {
        Write-Host "  Testing: $Uri" -ForegroundColor Gray
        
        $req = [Net.HttpWebRequest]::Create($Uri)
        $req.Timeout = 15000  # 15 second timeout
        
        try { 
            $null = $req.GetResponse() 
        } catch [System.Net.WebException] {
            # We still get the certificate even if the request fails
        }

        $cert = $req.ServicePoint.Certificate

        if ($cert) {
            $result.Subject = $cert.Subject
            $result.Issuer = $cert.Issuer
            $result.Expires = [DateTime]::Parse($cert.GetExpirationDateString())
            
            # Check certificate validity
            $today = Get-Date
            if ($result.Expires -lt $today) {
                $result.Status = "EXPIRED"
            } elseif ($result.Expires -lt $today.AddDays(30)) {
                $result.Status = "Expiring Soon"
            } else {
                $result.Status = "Valid"
            }

            # Detect SSL inspection based on issuer
            # Expected issuers for Idira EPM:
            # - Cloudflare, Google Trust Services for tenant URLs
            # - Amazon for S3 and agent URLs
            $knownIssuers = @(
                "Cloudflare",
                "Google Trust Services",
                "Amazon",
                "DigiCert",
                "GlobalSign",
                "Starfield"
            )
            
            $isKnownIssuer = $false
            foreach ($known in $knownIssuers) {
                if ($result.Issuer -match $known) {
                    $isKnownIssuer = $true
                    break
                }
            }
            
            if ($isKnownIssuer) {
                $result.SSLInspection = "Not Detected"
            } else {
                $result.SSLInspection = "LIKELY DETECTED"
            }
        } else {
            $result.Error = "No certificate retrieved"
            $result.Status = "Error"
        }
    } catch {
        $result.Error = $_.Exception.Message
        $result.Status = "Error"
    }

    return $result
}

function Show-RegionMenu {
    <#
    .SYNOPSIS
        Displays an interactive menu for region selection or specific server entry.
    #>
    
    # Build ordered list of regions for numbered selection
    $regionList = @(
        @{ Code = "AU"; Name = "Australia"; URLCount = $EPMRegions["AU"].TenantURLs.Count + $EPMRegions["AU"].S3URLs.Count + $EPMRegions["AU"].AgentURLs.Count }
        @{ Code = "BR"; Name = "Brazil"; URLCount = $EPMRegions["BR"].TenantURLs.Count + $EPMRegions["BR"].S3URLs.Count + $EPMRegions["BR"].AgentURLs.Count }
        @{ Code = "CA"; Name = "Canada"; URLCount = $EPMRegions["CA"].TenantURLs.Count + $EPMRegions["CA"].S3URLs.Count + $EPMRegions["CA"].AgentURLs.Count }
        @{ Code = "CH"; Name = "Switzerland"; URLCount = $EPMRegions["CH"].TenantURLs.Count + $EPMRegions["CH"].S3URLs.Count + $EPMRegions["CH"].AgentURLs.Count }
        @{ Code = "AE"; Name = "UAE"; URLCount = $EPMRegions["AE"].TenantURLs.Count + $EPMRegions["AE"].S3URLs.Count + $EPMRegions["AE"].AgentURLs.Count }
        @{ Code = "EU"; Name = "Germany/EU"; URLCount = $EPMRegions["EU"].TenantURLs.Count + $EPMRegions["EU"].S3URLs.Count + $EPMRegions["EU"].AgentURLs.Count }
        @{ Code = "IL"; Name = "Israel"; URLCount = $EPMRegions["IL"].TenantURLs.Count + $EPMRegions["IL"].S3URLs.Count + $EPMRegions["IL"].AgentURLs.Count }
        @{ Code = "IN"; Name = "India"; URLCount = $EPMRegions["IN"].TenantURLs.Count + $EPMRegions["IN"].S3URLs.Count + $EPMRegions["IN"].AgentURLs.Count }
        @{ Code = "IT"; Name = "Italy"; URLCount = $EPMRegions["IT"].TenantURLs.Count + $EPMRegions["IT"].S3URLs.Count + $EPMRegions["IT"].AgentURLs.Count }
        @{ Code = "JP"; Name = "Japan"; URLCount = $EPMRegions["JP"].TenantURLs.Count + $EPMRegions["JP"].S3URLs.Count + $EPMRegions["JP"].AgentURLs.Count }
        @{ Code = "SG"; Name = "Singapore"; URLCount = $EPMRegions["SG"].TenantURLs.Count + $EPMRegions["SG"].S3URLs.Count + $EPMRegions["SG"].AgentURLs.Count }
        @{ Code = "UK"; Name = "United Kingdom"; URLCount = $EPMRegions["UK"].TenantURLs.Count + $EPMRegions["UK"].S3URLs.Count + $EPMRegions["UK"].AgentURLs.Count }
        @{ Code = "NA"; Name = "USA (North America)"; URLCount = $EPMRegions["NA"].TenantURLs.Count + $EPMRegions["NA"].S3URLs.Count + $EPMRegions["NA"].AgentURLs.Count }
        @{ Code = "FED"; Name = "US Federal (GovCloud)"; URLCount = $EPMRegions["FED"].TenantURLs.Count + $EPMRegions["FED"].S3URLs.Count + $EPMRegions["FED"].AgentURLs.Count }
    )

    Write-Host ""
    Write-Host "  ╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║            Idira EPM SSL Inspection Tester                 ║" -ForegroundColor Cyan
    Write-Host "  ╠════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "  ║  This tool checks SSL certificates for EPM service URLs    ║" -ForegroundColor Cyan
    Write-Host "  ║  to detect if SSL inspection/decryption is occurring.      ║" -ForegroundColor Cyan
    Write-Host "  ╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  How would you like to test?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    [1] " -NoNewline -ForegroundColor White
    Write-Host "Select a region" -ForegroundColor Green
    Write-Host "        Test all URLs for a specific region"
    Write-Host ""
    Write-Host "    [2] " -NoNewline -ForegroundColor White
    Write-Host "Enter a specific server" -ForegroundColor Green
    Write-Host "        Test a single tenant server (e.g., NA123, EU140)"
    Write-Host ""
    Write-Host "  ────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    
    do {
        $modeChoice = Read-Host "  Enter selection (1 or 2)"
        $modeChoice = $modeChoice.Trim()
        
        if ($modeChoice -eq "1") {
            return Show-RegionSelectionMenu -RegionList $regionList
        } elseif ($modeChoice -eq "2") {
            return Show-SpecificServerPrompt
        }
        
        Write-Host "  Invalid selection. Please enter 1 or 2." -ForegroundColor Red
    } while ($true)
}

function Show-RegionSelectionMenu {
    <#
    .SYNOPSIS
        Displays the region selection submenu.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$RegionList
    )
    
    Write-Host ""
    Write-Host "  Select your EPM region:" -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 0; $i -lt $RegionList.Count; $i++) {
        $num = $i + 1
        $region = $RegionList[$i]
        $padding = if ($num -lt 10) { " " } else { "" }
        Write-Host "    $padding[$num] " -NoNewline -ForegroundColor White
        Write-Host "$($region.Code)" -NoNewline -ForegroundColor Green
        Write-Host " - $($region.Name) " -NoNewline
        Write-Host "($($region.URLCount) URLs)" -ForegroundColor DarkGray
    }
    
    Write-Host ""
    Write-Host "  ────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    
    do {
        $userInput = Read-Host "  Enter selection (1-14 or region code)"
        $userInput = $userInput.Trim().ToUpper()
        
        # Check if numeric input
        if ($userInput -match '^\d+$') {
            $num = [int]$userInput
            if ($num -ge 1 -and $num -le 14) {
                return @{ Type = "Region"; Value = $RegionList[$num - 1].Code }
            }
        }
        # Check if valid region code
        elseif ($EPMRegions.ContainsKey($userInput)) {
            return @{ Type = "Region"; Value = $userInput }
        }
        
        Write-Host "  Invalid selection. Please enter 1-14 or a valid region code." -ForegroundColor Red
    } while ($true)
}

function Show-SpecificServerPrompt {
    <#
    .SYNOPSIS
        Prompts user to enter a specific server name.
    #>
    
    Write-Host ""
    Write-Host "  Enter your specific EPM server:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Format: " -NoNewline -ForegroundColor Gray
    Write-Host "<Region><Number>" -ForegroundColor Cyan
    Write-Host "  Examples: NA123, EU140, AU126, UK149, NA01 (FedRAMP)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Valid region prefixes:" -ForegroundColor Gray
    Write-Host "    NA, EU, AU, BR, CA, CH, IL, IN, IT, JP, SG, UK, SVC" -ForegroundColor DarkGray
    Write-Host "    FedRAMP: NA01-NA06" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  ────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    
    do {
        $serverInput = Read-Host "  Enter server name"
        $serverInput = $serverInput.Trim().ToUpper()
        
        # Validate server format (letters followed by numbers, or special cases including FedRAMP NA01-NA06)
        if ($serverInput -match '^NA0[1-6]$' -or $serverInput -match '^(NA|EU|AU|BR|CA|CH|IL|IN|IT|JP|SG|UK|SVC)\d+$') {
            return @{ Type = "Server"; Value = $serverInput }
        }
        
        Write-Host "  Invalid server format. Please enter a valid server name (e.g., NA123, EU140, NA01)." -ForegroundColor Red
    } while ($true)
}

function Get-RegionFromServer {
    <#
    .SYNOPSIS
        Determines the region code from a server name.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServerName
    )
    
    # Check for FedRAMP servers first (NA01-NA06)
    if ($ServerName -match '^NA0[1-6]$') {
        return "FED"
    }
    # Extract the prefix from the server name
    elseif ($ServerName -match '^(NA|SVC)\d+$') {
        return "NA"
    } elseif ($ServerName -match '^EU\d+$') {
        return "EU"
    } elseif ($ServerName -match '^AU\d+$') {
        return "AU"
    } elseif ($ServerName -match '^BR\d+$') {
        return "BR"
    } elseif ($ServerName -match '^CA\d+$') {
        return "CA"
    } elseif ($ServerName -match '^CH\d+$') {
        return "CH"
    } elseif ($ServerName -match '^IL\d+$') {
        return "IL"
    } elseif ($ServerName -match '^IN\d+$') {
        return "IN"
    } elseif ($ServerName -match '^IT\d+$') {
        return "IT"
    } elseif ($ServerName -match '^JP\d+$') {
        return "JP"
    } elseif ($ServerName -match '^SG\d+$') {
        return "SG"
    } elseif ($ServerName -match '^UK\d+$') {
        return "UK"
    }
    
    return $null
}

function Test-SpecificServer {
    <#
    .SYNOPSIS
        Tests SSL certificates for a specific server and its associated regional URLs.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServerName
    )
    
    $regionCode = Get-RegionFromServer -ServerName $ServerName
    
    if (-not $regionCode) {
        Write-Host "  Could not determine region for server: $ServerName" -ForegroundColor Red
        return $null
    }
    
    $region = $EPMRegions[$regionCode]
    $results = @()
    
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "  Testing Server: $ServerName" -ForegroundColor Cyan
    Write-Host "  Region: $($region.Name) ($regionCode)" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    
    # Build the tenant URL for the specific server (FedRAMP uses different domain)
    if ($regionCode -eq "FED") {
        $tenantUrl = "https://$ServerName.epm.cyberarkgov.cloud"
    } else {
        $tenantUrl = "https://$ServerName.epm.cyberark.com"
    }
    
    # Test the specific tenant URL
    Write-Host "`n[Tenant URL - Specific Server]" -ForegroundColor Yellow
    $results += Test-SSLCertificate -Uri $tenantUrl -UrlType "Tenant"
    
    # Also test the regional login URL
    Write-Host "`n[Regional Login URL]" -ForegroundColor Yellow
    if ($regionCode -eq "FED") {
        $regionalLoginUrl = "https://login.epm.cyberarkgov.cloud"
    } else {
        $regionalLoginUrl = $region.TenantURLs | Where-Object { $_ -notmatch '\d+\.epm\.cyberark' } | Select-Object -First 1
    }
    if ($regionalLoginUrl) {
        $results += Test-SSLCertificate -Uri $regionalLoginUrl -UrlType "Tenant (Regional)"
    }
    
    # Test S3 URLs for the region
    Write-Host "`n[S3/Download URLs]" -ForegroundColor Yellow
    foreach ($url in $region.S3URLs) {
        $results += Test-SSLCertificate -Uri $url -UrlType "S3/Downloads"
    }
    
    # Test Agent URLs for the region
    Write-Host "`n[Agent Communication URLs]" -ForegroundColor Yellow
    foreach ($url in $region.AgentURLs) {
        $results += Test-SSLCertificate -Uri $url -UrlType "Agent"
    }
    
    return @{
        Results = $results
        ServerName = $ServerName
        RegionCode = $regionCode
        RegionName = $region.Name
    }
}

function Test-RegionURLs {
    <#
    .SYNOPSIS
        Tests all URLs for a specific region.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$RegionCode
    )

    if (-not $EPMRegions.ContainsKey($RegionCode)) {
        Write-Error "Invalid region code: $RegionCode"
        return
    }

    $region = $EPMRegions[$RegionCode]
    $results = @()

    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "  Testing Region: $($region.Name) ($RegionCode)" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan

    # Test Tenant URLs
    Write-Host "`n[Tenant URLs]" -ForegroundColor Yellow
    foreach ($url in $region.TenantURLs) {
        $results += Test-SSLCertificate -Uri $url -UrlType "Tenant"
    }

    # Test S3 URLs
    Write-Host "`n[S3/Download URLs]" -ForegroundColor Yellow
    foreach ($url in $region.S3URLs) {
        $results += Test-SSLCertificate -Uri $url -UrlType "S3/Downloads"
    }

    # Test Agent URLs
    Write-Host "`n[Agent Communication URLs]" -ForegroundColor Yellow
    foreach ($url in $region.AgentURLs) {
        $results += Test-SSLCertificate -Uri $url -UrlType "Agent"
    }

    return $results
}

function Format-Results {
    <#
    .SYNOPSIS
        Formats and displays the test results.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$Results,
        
        [Parameter(Mandatory = $false)]
        [string]$RegionName = ""
    )

    Write-Host "`n" -NoNewline
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  SSL INSPECTION TEST RESULTS" -ForegroundColor Cyan
    if ($RegionName) {
        Write-Host "  Region: $RegionName" -ForegroundColor Cyan
    }
    Write-Host "================================================================" -ForegroundColor Cyan

    foreach ($result in $Results) {
        Write-Host "`n--------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "URL:            " -NoNewline -ForegroundColor White
        Write-Host $result.URL -ForegroundColor Cyan
        Write-Host "Type:           " -NoNewline -ForegroundColor White
        Write-Host $result.URLType
        
        if ($result.Error) {
            Write-Host "Status:         " -NoNewline -ForegroundColor White
            Write-Host "ERROR - $($result.Error)" -ForegroundColor Red
        } else {
            Write-Host "Subject:        " -NoNewline -ForegroundColor White
            Write-Host $result.Subject
            Write-Host "Issuer:         " -NoNewline -ForegroundColor White
            Write-Host $result.Issuer
            Write-Host "Expires:        " -NoNewline -ForegroundColor White
            
            if ($result.Status -eq "EXPIRED") {
                Write-Host "$($result.Expires.ToString('yyyy-MM-dd HH:mm:ss')) [EXPIRED]" -ForegroundColor Red
            } elseif ($result.Status -eq "Expiring Soon") {
                Write-Host "$($result.Expires.ToString('yyyy-MM-dd HH:mm:ss')) [Expiring Soon]" -ForegroundColor Yellow
            } else {
                Write-Host $result.Expires.ToString('yyyy-MM-dd HH:mm:ss') -ForegroundColor Green
            }
            
            Write-Host "SSL Inspection: " -NoNewline -ForegroundColor White
            if ($result.SSLInspection -eq "LIKELY DETECTED") {
                Write-Host $result.SSLInspection -ForegroundColor Red
                Write-Host "                WARNING: Certificate issuer does not match expected Idira/Amazon/Cloudflare CA." -ForegroundColor Yellow
                Write-Host "                This may indicate SSL inspection is occurring." -ForegroundColor Yellow
            } else {
                Write-Host $result.SSLInspection -ForegroundColor Green
            }
        }
    }

    Write-Host "`n--------------------------------------------------" -ForegroundColor DarkGray
    
    # Summary
    $inspectionDetected = $Results | Where-Object { $_.SSLInspection -eq "LIKELY DETECTED" }
    $errors = $Results | Where-Object { $_.Status -eq "Error" }
    
    Write-Host "`n[SUMMARY]" -ForegroundColor Cyan
    Write-Host "Total URLs tested:     $($Results.Count)"
    Write-Host "SSL Inspection likely: " -NoNewline
    if ($inspectionDetected.Count -gt 0) {
        Write-Host "$($inspectionDetected.Count)" -ForegroundColor Red
    } else {
        Write-Host "0" -ForegroundColor Green
    }
    Write-Host "Errors:                $($errors.Count)"
    
    if ($inspectionDetected.Count -gt 0) {
        Write-Host "`n[ACTION REQUIRED]" -ForegroundColor Yellow
        Write-Host "SSL inspection was detected on the following URLs:" -ForegroundColor Yellow
        foreach ($item in $inspectionDetected) {
            Write-Host "  - $($item.URL)" -ForegroundColor Yellow
        }
        Write-Host "`nPlease configure your proxy/firewall to bypass SSL inspection for these URLs." -ForegroundColor Yellow
        Write-Host "Reference: https://docs.cyberark.com/epm/latest/en/content/installation/network-setup.htm" -ForegroundColor Gray
    }
}

# --- Main Execution ---

# Display banner
Write-Host @"

██╗██████╗ ██╗██████╗  █████╗ 
██║██╔══██╗██║██╔══██╗██╔══██╗
██║██║  ██║██║██████╔╝███████║
██║██║  ██║██║██╔══██╗██╔══██║
██║██████╔╝██║██║  ██║██║  ██║
╚═╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
      EPM SSL Inspection Tester
"@ -ForegroundColor Cyan

# Interactive loop - keep running until user exits
$continueRunning = $true

while ($continueRunning) {
    $allResults = @()
    $resultLabel = ""
    
    # Determine which region(s) to test
    if (-not $Region) {
        $selection = Show-RegionMenu
    } else {
        # If Region parameter was provided, use it directly
        $selection = @{ Type = "Region"; Value = $Region.ToUpper() }
        # Clear the parameter so subsequent loops are interactive
        $Region = $null
    }

    # Handle the selection based on type
    if ($selection.Type -eq "Server") {
        # Test specific server
        $serverName = $selection.Value
        Write-Host "`n  Testing specific server: $serverName" -ForegroundColor Yellow
        Write-Host ""
        
        $serverResult = Test-SpecificServer -ServerName $serverName
        
        if ($serverResult) {
            $allResults = $serverResult.Results
            $resultLabel = "Server: $($serverResult.ServerName) ($($serverResult.RegionName))"
        } else {
            Write-Host "  Failed to test server. Please try again." -ForegroundColor Red
            continue
        }
    } elseif ($selection.Type -eq "Region") {
        $selectedRegion = $selection.Value
        
        if ($EPMRegions.ContainsKey($selectedRegion)) {
            $urlCount = $EPMRegions[$selectedRegion].TenantURLs.Count + $EPMRegions[$selectedRegion].S3URLs.Count + $EPMRegions[$selectedRegion].AgentURLs.Count
            Write-Host "`n  Testing $($EPMRegions[$selectedRegion].Name) region ($urlCount URLs)..." -ForegroundColor Yellow
            Write-Host ""
            
            $results = Test-RegionURLs -RegionCode $selectedRegion
            $allResults += $results
            $resultLabel = "$($EPMRegions[$selectedRegion].Name) ($selectedRegion)"
        } else {
            Write-Host "`n  Invalid region code: $selectedRegion" -ForegroundColor Red
            Write-Host "  Valid region codes: $($EPMRegions.Keys -join ', ')" -ForegroundColor Yellow
            continue
        }
    }

    # Display results
    if ($allResults.Count -gt 0) {
        Format-Results -Results $allResults -RegionName $resultLabel
    }

    # Export results to CSV if requested
    Write-Host ""
    $exportChoice = Read-Host "  Export results to CSV? (Y/N)"
    if ($exportChoice -eq "Y" -or $exportChoice -eq "y") {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $safeLabel = $resultLabel -replace '[^a-zA-Z0-9]', '_'
        $exportPath = "EPM_SSL_Inspection_Results_${safeLabel}_$timestamp.csv"
        $allResults | Select-Object URL, URLType, Subject, Issuer, Expires, Status, SSLInspection, Error | 
            Export-Csv -Path $exportPath -NoTypeInformation
        Write-Host "  Results exported to: $exportPath" -ForegroundColor Green
    }

    # Ask if user wants to test another region
    Write-Host ""
    $continueChoice = Read-Host "  Test another region or server? (Y/N)"
    if ($continueChoice -ne "Y" -and $continueChoice -ne "y") {
        $continueRunning = $false
        Write-Host ""
        Write-Host "  Thank you for using the Idira EPM SSL Inspection Tester!" -ForegroundColor Cyan
        Write-Host "  Reference: https://docs.cyberark.com/epm/latest/en/content/installation/network-setup.htm" -ForegroundColor Gray
        Write-Host ""
    }
}