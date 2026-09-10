# DISCLAIMER:
# This is a sample script provided for educational purposes only.
# Use this script at your own risk. The author assumes no liability for any damages or issues caused by its use.

# This script identifies and removes stale endpoint agents from CyberArk EPM based on their last connection date.
# Endpoints that haven't connected in more than the specified number of days will be deleted.


# Script starts here...

#==============================================================================
# INTERACTIVE CONFIGURATION
#==============================================================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  EPM Stale Endpoint Cleanup Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Prompt for Set ID
$setId = Read-Host "Enter your EPM Set ID"
if ([string]::IsNullOrWhiteSpace($setId)) {
    Write-Host "Set ID is required. Exiting." -ForegroundColor Red
    exit 1
}

# Prompt for number of days
Write-Host ""
Write-Host "Enter the number of days to use as the stale threshold." -ForegroundColor Yellow
Write-Host "Endpoints that have not connected in more than this many days will be deleted." -ForegroundColor Gray
$daysInput = Read-Host "Number of days (e.g., 30, 60, 90)"

# Validate days input
if (-not [int]::TryParse($daysInput, [ref]$null)) {
    Write-Host "Invalid input. Please enter a valid number." -ForegroundColor Red
    exit 1
}
$staleDays = [int]$daysInput

if ($staleDays -lt 1) {
    Write-Host "Number of days must be at least 1." -ForegroundColor Red
    exit 1
}

$cutoffDate = (Get-Date).AddDays(-$staleDays)
Write-Host ""
Write-Host "Cutoff date: $($cutoffDate.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
Write-Host "Endpoints last connected BEFORE this date will be marked for deletion." -ForegroundColor Gray

# Prompt for which date field to use
Write-Host ""
Write-Host "Select which date field to use for determining stale endpoints:" -ForegroundColor Yellow
Write-Host "  [1] Last Connected (recommended - when endpoint last communicated with EPM)"
Write-Host "  [2] Install Time (when the agent was first installed)"
Write-Host ""
$dateFieldChoice = Read-Host "Enter choice (1 or 2)"

switch ($dateFieldChoice) {
    "1" { 
        $dateFieldLegacy = "LastConnection"
        $dateFieldModern = "lastConnected"
        $dateFieldDisplay = "Last Connected"
    }
    "2" { 
        $dateFieldLegacy = "InstallTime"
        $dateFieldModern = "installTime"
        $dateFieldDisplay = "Install Time"
    }
    default {
        Write-Host "Invalid choice. Using Last Connected." -ForegroundColor Yellow
        $dateFieldLegacy = "LastConnection"
        $dateFieldModern = "lastConnected"
        $dateFieldDisplay = "Last Connected"
    }
}

# Prompt for authentication method
Write-Host ""
Write-Host "Select Authentication Method:" -ForegroundColor Yellow
Write-Host "  [1] Legacy EPM Authentication (username/password)"
Write-Host "  [2] Modern OAuth2 via CyberArk Identity (ISPSS)"
Write-Host ""
$authChoice = Read-Host "Enter choice (1 or 2)"

#==============================================================================
# AUTHENTICATION
#==============================================================================

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")

switch ($authChoice) {
    "1" {
        #----------------------------------------------------------------------
        # Legacy EPM Direct Authentication
        #----------------------------------------------------------------------
        Write-Host ""
        Write-Host "--- Legacy EPM Authentication ---" -ForegroundColor Yellow
        
        # Prompt for EPM dispatcher URL
        Write-Host ""
        Write-Host "Select EPM Cloud Environment:" -ForegroundColor Yellow
        Write-Host "  [1] Commercial (login.epm.cyberark.com)"
        Write-Host "  [2] US Government (login.epm.cyberarkgov.cloud)"
        Write-Host "  [3] Custom URL"
        $envChoice = Read-Host "Enter choice (1, 2, or 3)"
        
        switch ($envChoice) {
            "1" { $epmDispatcherUrl = "https://login.epm.cyberark.com" }
            "2" { $epmDispatcherUrl = "https://login.epm.cyberarkgov.cloud" }
            "3" { $epmDispatcherUrl = Read-Host "Enter custom EPM dispatcher URL (e.g., https://login.epm.cyberark.com)" }
            default {
                Write-Host "Invalid choice. Using commercial cloud." -ForegroundColor Yellow
                $epmDispatcherUrl = "https://login.epm.cyberark.com"
            }
        }
        
        # Prompt for credentials securely
        $epmLoginUserName = Read-Host "Enter EPM username"
        $epmSecurePassword = Read-Host "Enter EPM password" -AsSecureString
        $epmLoginPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($epmSecurePassword))
        
        $epmLoginApplicationID = Read-Host "Enter Application ID (optional, press Enter to skip)"
        if ([string]::IsNullOrWhiteSpace($epmLoginApplicationID)) {
            $epmLoginApplicationID = "PowerShell-EPM-Script"
        }
        
        Write-Host ""
        Write-Host "Authenticating via Legacy EPM authentication..." -ForegroundColor Cyan
        
        $body = @"
{
  "Username": "$epmLoginUserName",
  "Password": "$epmLoginPassword",
  "ApplicationID": "$epmLoginApplicationID"
}
"@
        try {
            $authResponse = Invoke-RestMethod "$epmDispatcherUrl/EPM/API/Auth/EPM/Logon" -Method 'POST' -Headers $headers -Body $body
            $loginToken = $authResponse.EPMAuthenticationResult
            $serverInstance = $authResponse.ManagerURL
            $headers.Add("Authorization", "basic $loginToken")
            Write-Host "EPM authentication successful!" -ForegroundColor Green
            
            if ($authResponse.IsPasswordExpired) {
                Write-Host "Warning: Your password has expired. Please update it soon." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "EPM authentication failed: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
        finally {
            # Clear password from memory
            $epmLoginPassword = $null
            [System.GC]::Collect()
        }
    }
    
    "2" {
        #----------------------------------------------------------------------
        # Modern OAuth2 via CyberArk Identity (ISPSS)
        #----------------------------------------------------------------------
        Write-Host ""
        Write-Host "--- OAuth2 via CyberArk Identity (ISPSS) ---" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Prerequisites:" -ForegroundColor Cyan
        Write-Host "  - A service user created in Identity Administration"
        Write-Host "  - A custom EPM API web app configured in Identity"
        Write-Host "  - The service user bound to the web app"
        Write-Host "  - The service user assigned to an EPM role with API permissions"
        Write-Host ""
        
        # Prompt for Identity settings
        $identitySubdomain = Read-Host "Enter Identity tenant subdomain (e.g., 'abc1234' from abc1234.id.cyberark.cloud)"
        $identityAppAlias = Read-Host "Enter OAuth app alias (configured in Identity Administration)"
        $identityServiceUser = Read-Host "Enter service user (e.g., svc-epm-api@mycompany.cyberark.cloud)"
        $identitySecurePassword = Read-Host "Enter service user password" -AsSecureString
        $identityServicePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($identitySecurePassword))
        
        $epmServerName = Read-Host "Enter EPM server name (subdomain from EPM console URL, e.g., 'mycompany' from mycompany.epm.cyberark.com)"
        
        Write-Host ""
        Write-Host "Authenticating via OAuth2 (client credentials flow)..." -ForegroundColor Cyan
        
        # Build the OAuth token endpoint URL
        $tokenUrl = "https://$identitySubdomain.id.cyberark.cloud/oauth2/token/$identityAppAlias"
        
        # Create Basic auth header for OAuth request (Base64 encoded credentials)
        $credentialPair = "$identityServiceUser`:$identityServicePassword"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credentialPair))
        
        $oauthHeaders = @{
            "Authorization" = "Basic $encodedCredentials"
            "Content-Type" = "application/x-www-form-urlencoded"
        }
        
        $oauthBody = "grant_type=client_credentials"
        
        try {
            $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method 'POST' -Headers $oauthHeaders -Body $oauthBody
            $accessToken = $tokenResponse.access_token
            
            # Set the EPM server instance URL and Bearer token header
            $serverInstance = "https://$epmServerName.epm.cyberark.com"
            $headers.Add("Authorization", "Bearer $accessToken")
            
            Write-Host "OAuth2 authentication successful!" -ForegroundColor Green
            Write-Host "Token expires in $($tokenResponse.expires_in) seconds" -ForegroundColor Gray
        }
        catch {
            Write-Host "OAuth2 authentication failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host ""
            Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
            Write-Host "  - Verify the Identity subdomain is correct"
            Write-Host "  - Verify the app alias matches the web app configuration"
            Write-Host "  - Verify the service user credentials"
            Write-Host "  - Ensure the service user is bound to the web app in the Tokens tab"
            Write-Host "  - Ensure the service user is assigned to an EPM role"
            exit 1
        }
        finally {
            # Clear password from memory
            $identityServicePassword = $null
            $encodedCredentials = $null
            [System.GC]::Collect()
        }
    }
    
    default {
        Write-Host "Invalid choice. Please run the script again and select 1 or 2." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Connected to EPM server: $serverInstance" -ForegroundColor Gray
Write-Host ""

#==============================================================================
# API VERSION SELECTION
#==============================================================================

Write-Host "Select API Version:" -ForegroundColor Yellow
Write-Host "  [1] Legacy Computers API (deprecated, for older EPM versions)"
Write-Host "  [2] Modern Endpoints API (recommended for EPM v25.4+)"
Write-Host ""
$apiChoice = Read-Host "Enter choice (1 or 2)"

switch ($apiChoice) {
    "1" {
        #======================================================================
        # LEGACY COMPUTERS API
        #======================================================================
        Write-Host ""
        Write-Host "Using Legacy Computers API..." -ForegroundColor Yellow
        Write-Host "Note: This API is deprecated and will be removed in a future version." -ForegroundColor Gray
        Write-Host ""
        
        # Get Computer list using legacy API
        # Legacy API supports up to 2500 per page
        $pageSize = 2500
        $offset = 0
        $pageNumber = 1
        $computersURI = "$serverInstance/EPM/API/Sets/$setId/Computers?limit=$pageSize"
        $computersList = [System.Collections.ArrayList]::new()
        
        do {
            Write-Host "Getting computers: currently on page $pageNumber"
            $apiResult = $null
            try {
                $apiResult = Invoke-RestMethod -Uri $computersURI -Method 'GET' -Headers $headers
                [void]$computersList.AddRange($apiResult.Computers)
                if ($apiResult.Computers.Count -eq $pageSize) {
                    $offset += $pageSize
                    $computersURI = "$serverInstance/EPM/API/Sets/$setId/Computers?limit=$pageSize&offset=$offset"
                }
                $pageNumber++
            }
            catch {
                Write-Host "Error retrieving computers: $($_.Exception.Message)" -ForegroundColor Red
                exit 1
            }
        }
        while ($apiResult.Computers.Count -eq $pageSize)
        
        Write-Host "Total computers retrieved: $($computersList.Count)" -ForegroundColor Gray
        Write-Host ""
        
        # Find Stale Computers based on date field
        Write-Host "Analyzing stale endpoints (older than $staleDays days based on $dateFieldDisplay)..." -ForegroundColor Cyan
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        $result = [System.Collections.ArrayList]::new()
        $processedCount = 0
        $totalCount = $computersList.Count
        
        foreach ($computer in $computersList) {
            $dateValue = $computer.$dateFieldLegacy
            
            # Handle null or empty date values
            if (-not [string]::IsNullOrWhiteSpace($dateValue)) {
                try {
                    $endpointDate = [datetime]$dateValue
                    if ($endpointDate -lt $cutoffDate) {
                        [void]$result.Add($computer)
                    }
                }
                catch {
                    # Skip endpoints with invalid date formats
                }
            }
            else {
                # Include endpoints with no date as stale (never connected)
                [void]$result.Add($computer)
            }
            
            # Progress indicator every 10000 records
            $processedCount++
            if ($processedCount % 10000 -eq 0) {
                Write-Host "  Processed $processedCount of $totalCount computers..." -ForegroundColor Gray
            }
        }
        
        $stopwatch.Stop()
        Write-Host "  Analysis complete in $([math]::Round($stopwatch.Elapsed.TotalSeconds, 2)) seconds." -ForegroundColor Gray
        Write-Host "  Found $($result.Count) stale endpoint(s) to remove." -ForegroundColor Gray
        Write-Host ""
        
        # Delete Stale Computers using legacy API
        if ($result.Count -gt 0) {
            Write-Host "============================================" -ForegroundColor Yellow
            Write-Host "  STALE COMPUTERS FOUND" -ForegroundColor Yellow
            Write-Host "============================================" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Found $($result.Count) computer(s) with $dateFieldDisplay older than $staleDays days:" -ForegroundColor Cyan
            Write-Host "Cutoff date: $($cutoffDate.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
            Write-Host ""
            
            # Display the computers that will be deleted in a formatted table
            $headerLine = "  {0,-30} {1,-40} {2,-25}" -f "COMPUTER NAME", "AGENT ID", $dateFieldDisplay.ToUpper()
            $separatorLine = "  {0,-30} {1,-40} {2,-25}" -f ("-" * 30), ("-" * 40), ("-" * 25)
            Write-Host $headerLine -ForegroundColor White
            Write-Host $separatorLine -ForegroundColor White
            
            # Limit display to first 100 if there are many
            $displayLimit = 100
            $displayCount = 0
            foreach ($computer in $result) {
                if ($displayCount -ge $displayLimit) {
                    Write-Host "  ... and $($result.Count - $displayLimit) more stale endpoints (display limited to $displayLimit)" -ForegroundColor Gray
                    break
                }
                $dateValue = $computer.$dateFieldLegacy
                if ([string]::IsNullOrWhiteSpace($dateValue)) { $dateValue = "(never)" }
                $dataLine = "  {0,-30} {1,-40} {2,-25}" -f $computer.ComputerName, $computer.AgentId, $dateValue
                Write-Host $dataLine -ForegroundColor Gray
                $displayCount++
            }
            
            Write-Host ""
            Write-Host "============================================" -ForegroundColor Red
            Write-Host "  WARNING" -ForegroundColor Red
            Write-Host "============================================" -ForegroundColor Red
            Write-Host "This action will permanently remove $($result.Count) stale computer(s) from EPM." -ForegroundColor Red
            Write-Host "The EPM agent will NOT be uninstalled from the machines." -ForegroundColor Yellow
            Write-Host ""
            
            $confirmation = Read-Host "Do you want to proceed with deletion? Type 'yes' to confirm"
            
            if ($confirmation -ne "yes") {
                Write-Host ""
                Write-Host "Operation cancelled by user." -ForegroundColor Yellow
                exit 0
            }
            
            Write-Host ""
            Write-Host "Starting deletion process..." -ForegroundColor Cyan
            Write-Host ""
            
            $computersBaseURI = "$serverInstance/EPM/API/Sets/$setId/Computers"
            $totalDeleted = 0
            $totalErrors = 0
            $currentRecord = 0
            
            foreach ($record in $result) {
                $currentRecord++
                $deleteComputerURI = "$computersBaseURI/$($record.AgentId)"
                Write-Host "[$currentRecord/$($result.Count)] Deleting: $($record.ComputerName)..." -ForegroundColor Cyan
                
                try {
                    $deleteResponse = Invoke-RestMethod -Uri $deleteComputerURI -Method 'DELETE' -Headers $headers
                    $totalDeleted++
                    Write-Host "  [OK] Deleted successfully" -ForegroundColor Green
                }
                catch {
                    $totalErrors++
                    Write-Host "  [ERROR] Failed to delete: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                # Pause for 6 seconds to stay within API limits (20 calls per 2 mins)
                if ($currentRecord -lt $result.Count) {
                    Start-Sleep -Seconds 6
                }
            }
            
            Write-Host ""
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host "  DELETION COMPLETE" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  Total computers deleted: $totalDeleted" -ForegroundColor Green
            if ($totalErrors -gt 0) {
                Write-Host "  Total errors: $totalErrors" -ForegroundColor Yellow
            }
            Write-Host ""
        }
        else {
            Write-Host ""
            Write-Host "============================================" -ForegroundColor Green
            Write-Host "  NO STALE ENDPOINTS FOUND" -ForegroundColor Green
            Write-Host "============================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "No computers with $dateFieldDisplay older than $staleDays days found in Set ID: $setId" -ForegroundColor Gray
            Write-Host "Total computers scanned: $($computersList.Count)" -ForegroundColor Gray
            Write-Host ""
        }
    }
    
    "2" {
        #======================================================================
        # MODERN ENDPOINTS API
        #======================================================================
        Write-Host ""
        Write-Host "Using Modern Endpoints API..." -ForegroundColor Green
        Write-Host ""
        
        # Get Endpoint list using new Endpoints API
        # Note: Endpoints API has a max limit of 1000 per request
        $pageSize = 1000
        $offset = 0
        $pageNumber = 1
        $endpointsURI = "$serverInstance/EPM/API/Sets/$setId/Endpoints/search?limit=$pageSize"
        $endpointsList = [System.Collections.ArrayList]::new()
        $searchBody = @{ "filter" = "connectionStatus IN Disconnected, NeverConnected" } | ConvertTo-Json
        
        do {
            Write-Host "Getting endpoints: currently on page $pageNumber"
            $apiResult = $null
            try {
                $apiResult = Invoke-RestMethod -Uri $endpointsURI -Method 'POST' -Headers $headers -Body $searchBody
                if ($apiResult.Endpoints) {
                    [void]$endpointsList.AddRange($apiResult.Endpoints)
                }
                if ($apiResult.Endpoints.Count -eq $pageSize) {
                    $offset += $pageSize
                    $endpointsURI = "$serverInstance/EPM/API/Sets/$setId/Endpoints/search?limit=$pageSize&offset=$offset"
                }
                $pageNumber++
            }
            catch {
                Write-Host "Error retrieving endpoints: $($_.Exception.Message)" -ForegroundColor Red
                exit 1
            }
        }
        while ($apiResult.Endpoints.Count -eq $pageSize)
        
        Write-Host "Total endpoints retrieved: $($endpointsList.Count)" -ForegroundColor Gray
        Write-Host ""
        
        $endpointsDeleteURI = "$serverInstance/EPM/API/Sets/$setId/Endpoints/delete"
        
        # Find Stale Endpoints based on date field
        Write-Host "Analyzing stale endpoints (older than $staleDays days based on $dateFieldDisplay)..." -ForegroundColor Cyan
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        $result = [System.Collections.ArrayList]::new()
        $processedCount = 0
        $totalCount = $endpointsList.Count
        
        foreach ($endpoint in $endpointsList) {
            $isStale = $false
            
#            if ($dateFieldModern -eq "lastConnected" -and $endpoint.connectionStatus -eq "Connected") {
#                # Endpoint is currently connected - ignore lastConnected entirely, not stale
#                $isStale = $false
#            }
#            else {
                # Endpoint is disconnected (or we're evaluating a different date field) - use the date value
                $dateValue = $endpoint.$dateFieldModern
                
                # Handle null or empty date values
                if (-not [string]::IsNullOrWhiteSpace($dateValue)) {
                    try {
                        $endpointDate = [datetime]$dateValue
                        if ($endpointDate -lt $cutoffDate) {
                            $isStale = $true
                        }
                    }
                    catch {
                        # Skip endpoints with invalid date formats
                    }
                }
                else {
                    # Include endpoints with no date as stale (never connected)
                    $isStale = $true
                }
#            }
            
            if ($isStale) {
                [void]$result.Add($endpoint)
            }
            
            # Progress indicator every 10000 records
            $processedCount++
            if ($processedCount % 10000 -eq 0) {
                Write-Host "  Processed $processedCount of $totalCount endpoints..." -ForegroundColor Gray
            }
        }
        
        $stopwatch.Stop()
        Write-Host "  Analysis complete in $([math]::Round($stopwatch.Elapsed.TotalSeconds, 2)) seconds." -ForegroundColor Gray
        Write-Host "  Found $($result.Count) stale endpoint(s) to remove." -ForegroundColor Gray
        Write-Host ""
        
        # Delete Stale Endpoints using new Endpoints/delete API with batch processing
        if ($result.Count -gt 0) {
            Write-Host "============================================" -ForegroundColor Yellow
            Write-Host "  STALE ENDPOINTS FOUND" -ForegroundColor Yellow
            Write-Host "============================================" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Found $($result.Count) endpoint(s) with $dateFieldDisplay older than $staleDays days:" -ForegroundColor Cyan
            Write-Host "Cutoff date: $($cutoffDate.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
            Write-Host ""
            
            # Display the endpoints that will be deleted in a formatted table
            $headerLine = "  {0,-30} {1,-40} {2,-25}" -f "ENDPOINT NAME", "ENDPOINT ID", $dateFieldDisplay.ToUpper()
            $separatorLine = "  {0,-30} {1,-40} {2,-25}" -f ("-" * 30), ("-" * 40), ("-" * 25)
            Write-Host $headerLine -ForegroundColor White
            Write-Host $separatorLine -ForegroundColor White
            
            # Limit display to first 100 if there are many
            $displayLimit = 100
            $displayCount = 0
            foreach ($endpoint in $result) {
                if ($displayCount -ge $displayLimit) {
                    Write-Host "  ... and $($result.Count - $displayLimit) more stale endpoints (display limited to $displayLimit)" -ForegroundColor Gray
                    break
                }
                $dateValue = $endpoint.$dateFieldModern
                if ([string]::IsNullOrWhiteSpace($dateValue)) { $dateValue = "(never)" }
                $dataLine = "  {0,-30} {1,-40} {2,-25}" -f $endpoint.name, $endpoint.id, $dateValue
                Write-Host $dataLine -ForegroundColor Gray
                $displayCount++
            }
            
            Write-Host ""
            Write-Host "============================================" -ForegroundColor Red
            Write-Host "  WARNING" -ForegroundColor Red
            Write-Host "============================================" -ForegroundColor Red
            Write-Host "This action will permanently remove $($result.Count) stale endpoint(s) from EPM." -ForegroundColor Red
            Write-Host "The EPM agent will NOT be uninstalled from the machines." -ForegroundColor Yellow
            Write-Host ""
            
            $confirmation = Read-Host "Do you want to proceed with deletion? Type 'yes' to confirm"
            
            if ($confirmation -ne "yes") {
                Write-Host ""
                Write-Host "Operation cancelled by user." -ForegroundColor Yellow
                exit 0
            }
            
            Write-Host ""
            Write-Host "Starting deletion process..." -ForegroundColor Cyan
            Write-Host ""
            
            # Process in batches to stay within API limits (max 10 per batch to build reasonable filter strings)
            $batchSize = 10
            $batches = [System.Collections.ArrayList]::new()
            for ($i = 0; $i -lt $result.Count; $i += $batchSize) {
                $endIndex = [Math]::Min($i + $batchSize - 1, $result.Count - 1)
                $batch = [System.Collections.ArrayList]::new()
                for ($j = $i; $j -le $endIndex; $j++) {
                    [void]$batch.Add($result[$j])
                }
                [void]$batches.Add($batch)
            }
            
            $totalDeleted = 0
            $totalErrors = 0
            $batchNumber = 1
            foreach ($batch in $batches) {
                # Build filter with OR conditions for each endpoint ID
                $filterConditions = $batch | ForEach-Object { "id EQ `"$($_.id)`"" }
                $filter = $filterConditions -join " OR "
                
                $deleteBody = @{
                    "filter" = $filter
                    "returnIds" = $true
                    "force" = $false
                    "includeAll" = $false
                } | ConvertTo-Json
                
                Write-Host "Processing batch $batchNumber of $($batches.Count) - Deleting $($batch.Count) endpoint(s)..." -ForegroundColor Cyan
                foreach ($endpoint in $batch) {
                    Write-Host "  - $($endpoint.name)" -ForegroundColor Gray
                }
                
                try {
                    $deleteResponse = Invoke-RestMethod -Uri $endpointsDeleteURI -Method 'POST' -Headers $headers -Body $deleteBody
                    
                    # Process response - check appliedIds and statuses
                    if ($deleteResponse.appliedIds) {
                        $totalDeleted += $deleteResponse.appliedIds.Count
                        Write-Host "  [OK] Successfully queued $($deleteResponse.appliedIds.Count) endpoint(s) for deletion" -ForegroundColor Green
                    }
                    
                    # Report any errors from statuses
                    if ($deleteResponse.statuses) {
                        $deleteResponse.statuses.PSObject.Properties | ForEach-Object {
                            if ($_.Name -ne "OK" -and $_.Value -gt 0) {
                                $totalErrors += $_.Value
                                Write-Host "  [WARN] $($_.Value) endpoint(s) returned status: $($_.Name)" -ForegroundColor Yellow
                            }
                        }
                    }
                }
                catch {
                    $totalErrors += $batch.Count
                    Write-Host "  [ERROR] Failed to delete batch: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                # Pause between batches to respect API rate limits (20 calls per 2 mins)
                if ($batchNumber -lt $batches.Count) {
                    Write-Host "  Waiting 6 seconds before next batch (API rate limit)..." -ForegroundColor Gray
                    Start-Sleep -Seconds 6
                }
                $batchNumber++
                Write-Host ""
            }
            
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host "  DELETION COMPLETE" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  Total endpoints processed: $totalDeleted" -ForegroundColor Green
            if ($totalErrors -gt 0) {
                Write-Host "  Total errors: $totalErrors" -ForegroundColor Yellow
            }
            Write-Host ""
        }
        else {
            Write-Host ""
            Write-Host "============================================" -ForegroundColor Green
            Write-Host "  NO STALE ENDPOINTS FOUND" -ForegroundColor Green
            Write-Host "============================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "No endpoints with $dateFieldDisplay older than $staleDays days found in Set ID: $setId" -ForegroundColor Gray
            Write-Host "Total endpoints scanned: $($endpointsList.Count)" -ForegroundColor Gray
            Write-Host ""
        }
    }
    
    default {
        Write-Host "Invalid choice. Please run the script again and select 1 or 2." -ForegroundColor Red
        exit 1
    }
}
