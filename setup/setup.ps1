param (
        [Parameter(Mandatory=$true)]
        [string]
        $configFilePath,
        [Parameter(Mandatory=$true)]
        [string]
        $userId,
        [Parameter(Mandatory=$false)]
        [string]
        $existingKeyVaultName,
        [Parameter(Mandatory=$false)]
        [string]
        $existingKeyVaultRG,
        [Parameter(Mandatory=$false)]
        [string]
        $existingWorkspaceName,
        [Parameter(Mandatory=$false)]
        [string]
        $existingWorkSpaceRG,
        [Parameter(Mandatory=$false)]
        [switch]
        $skipDeployment
    )
#region Configuration and initialization
# test
#Configuration Variables
<<<<<<< HEAD
$version='1.0'
$releaseDate='2002-05-06'
=======
>>>>>>> 90f025b360a6dcb00cdffa6cdf8d2892a3a6f256
$randomstoragechars=-join ((97..122) | Get-Random -Count 4 | ForEach-Object {[char]$_})
Write-Output "Reading Config file:"
try {
    $config=get-content $configFilePath | convertfrom-json
}
catch {
    "Error reading config file."
    break
}
$tenantIDtoAppend="-"+$($env:ACC_TID).Split("-")[0]
$keyVaultName=$config.keyVaultName+$tenantIDtoAppend
$resourcegroup=$config.resourcegroup+$tenantIDtoAppend
$region=$config.region
$storageaccountName="$($config.storageaccountName)$randomstoragechars"
$logAnalyticsworkspaceName=$config.logAnalyticsworkspaceName+$tenantIDtoAppend
$autoMationAccountName=$config.autoMationAccountName+$tenantIDtoAppend
$keyVaultRG=$resourcegroup #initially, same RG.
$logAnalyticsWorkspaceRG=$resourcegroup #initially, same RG.
$deployKV='true'
$deployLAW='true'
$bga1=$config.FirstBreakGlassAccountUPN #Break glass account 1
$bga2=$config.SecondBreakGlassAccountUPN #Break glass account 2
$PBMMPolicyID=$config.PBMMPolicyID
$AllowedLocationPolicyId=$config.AllowedLocationPolicyId
$DepartmentNumber=$config.DepartmentNumber

#Other Variables
$mainRunbookName="main"
$mainRunbookPath='.\'
$mainRunbookDescription="Guardrails Main Runbook"

#Tests if logged in:
$subs = Get-AzSubscription -ErrorAction SilentlyContinue
if(-not($subs))
{
    Connect-AzAccount
    $subs = Get-AzSubscription -ErrorAction SilentlyContinue
}
if ($subs.count -gt 1)
{
    Write-output "More than one subscription detected. Current subscription $((get-azcontext).Name)"
    Write-output "Please select subscription for deployment or Enter to keep current one:"
    $i=1
    $subs | ForEach-Object {Write-output "$i - $($_.Name) - $($_.SubscriptionId)";$i++}
    [int]$selection=Read-Host "Select Subscription number: (1 - $($i-1))"
}
else { $selection=0}
if ($selection -ne 0)
{
    if ($selection -gt 0 -and $selection -le ($i-1))  { 
        Select-AzSubscription -SubscriptionObject $subs[$selection-1]
    }
    else {
        Write-output "Invalid selection. ($selection)"
        break
    }
}
else {
    Write-host "Keeping current subscription."
}
#region Let's deal with existing stuff...
# Keyvault first
if (!([string]::IsNullOrEmpty($existingKeyVaultName)))
{
    Write-Output "Will try to use an existing Keyvault."
    $keyVaultName=$existingKeyVaultName
    $keyVaultRG=$existingKeyVaultRG
    $deployKV='false'
}
#log analytics now...
if (!([string]::IsNullOrEmpty($existingWorkspaceName)))
{
    Write-Output "Will try to use an existing Log Analytics workspace."
    $logAnalyticsworkspaceName=$existingWorkspaceName
    $logAnalyticsWorkspaceRG=$existingWorkSpaceRG
    $deployLAW='false' #it will be passed to bicep.
}
#endregion
#Storage verification
if ((Get-AzStorageAccountNameAvailability -Name $storageaccountName).NameAvailable -eq $false)
{
    Write-Error "Storage account $storageaccountName not available."
    break
}
if ($storageaccountName.Length -gt 24 -or $storageaccountName.Length -lt 3)
{
    Write-Error "Storage account name must be between 3 and 24 lowercase characters."
    break
}
#endregion
#region keyvault verification
$kvContent=((Invoke-AzRest -Uri "https://management.azure.com/subscriptions/$((Get-AzContext).Subscription.Id)/providers/Microsoft.KeyVault/checkNameAvailability?api-version=2021-11-01-preview" `
-Method Post -Payload "{""name"": ""$keyVaultName"",""type"": ""Microsoft.KeyVault/vaults""}").Content | ConvertFrom-Json).NameAvailable
if (!($kvContent))
{
    write-output "Error: keyvault name $keyVaultName is not available."
    break
}
#endregion
#before deploying anything, check if current user can be found.
$begin=get-date
Write-Verbose "Adding current user as a Keyvault administrator (for setup)."
if ($userId -eq "")
{
    $currentUserId=(get-azaduser -UserPrincipalName (Get-AzAccessToken).UserId).Id 
}
else
{
    $currentUserId=(get-azaduser -UserPrincipalName $userId).Id
}
if ($null -eq $currentUserId)
{
    Write-Error "Error: no current user could be found in current Tenant. Context: $((Get-AzAccessToken).UserId). Override specified: $userId."
    break;
}
#region  Template Deployment
Write-Output "Creating bicep parameters file for this deployment."
$parameterTemplate=get-content .\parameters_template.json
$parameterTemplate=$parameterTemplate.Replace("%kvName%",$keyVaultName)
$parameterTemplate=$parameterTemplate.Replace("%location%",$region)
$parameterTemplate=$parameterTemplate.Replace("%storageAccountName%",$storageaccountName)
$parameterTemplate=$parameterTemplate.Replace("%logAnalyticsWorkspaceName%",$logAnalyticsworkspaceName)
$parameterTemplate=$parameterTemplate.Replace("%automationAccountName%",$autoMationAccountName)
$parameterTemplate=$parameterTemplate.Replace("%subscriptionId%",(Get-AzContext).Subscription.Id)
$parameterTemplate=$parameterTemplate.Replace("%PBMMPolicyID%",$PBMMPolicyID)
$parameterTemplate=$parameterTemplate.Replace("%deployKV%",$deployKV)
$parameterTemplate=$parameterTemplate.Replace("%deployLAW%",$deployLAW)
$parameterTemplate=$parameterTemplate.Replace("%AllowedLocationPolicyId%",$AllowedLocationPolicyId)
$parameterTemplate=$parameterTemplate.Replace("%DepartmentNumber%",$DepartmentNumber)
$parameterTemplate=$parameterTemplate.Replace("%CBSSubscriptionName%",$config.CBSSubscriptionName)
$parameterTemplate=$parameterTemplate.Replace("%SecurityLAWResourceId%",$config.SecurityLAWResourceId)
$parameterTemplate=$parameterTemplate.Replace("%HealthLAWResourceId%",$config.HealthLAWResourceId)
<<<<<<< HEAD
$parameterTemplate=$parameterTemplate.Replace("%version%",$version)
$parameterTemplate=$parameterTemplate.Replace("%releasedate%",$releaseDate)
#writes the file
=======
>>>>>>> 90f025b360a6dcb00cdffa6cdf8d2892a3a6f256
$parameterTemplate | out-file .\parameters.json -Force
#endregion

#region bicep deployment
Write-Verbose "Creating $resourceGroup in $region location."
try {
    New-AzResourceGroup -Name $resourceGroup -Location $region
}
catch { Write-error "Error creating resource group. "}
Write-Output "Deploying solution through bicep."
try { 
    New-AzResourceGroupDeployment -ResourceGroupName $resourcegroup -Name "guardraildeployment$(get-date -format "ddmmyyHHmmss")" `
    -TemplateParameterFile .\parameters.json -TemplateFile .\guardrails.bicep -WarningAction SilentlyContinue
}
catch {
    Write-error "Error deploying solution to Azure."
}
#endregion
#Add current user as a Keyvault administrator (for setup)
try {$kv=Get-AzKeyVault -ResourceGroupName $keyVaultRG -VaultName $keyVaultName} catch {"Error fetching KV object.";break}
try {New-AzRoleAssignment -ObjectId $currentUserId -RoleDefinitionName "Key Vault Administrator" -Scope $kv.ResourceId}catch {"Error assigning permissions to KV.";break}
Write-Output "Sleeping 30 seconds to allow for permissions to be propagated."
Start-Sleep -Seconds 30
#region Secret Setup
# Adds keyvault secret user permissions to the Automation account
Write-Verbose "Adding automation account Keyvault Secret User."
try {
    New-AzRoleAssignment -ObjectId (Get-AzAutomationAccount -AutomationAccountName $autoMationAccountName -ResourceGroupName $resourceGroup).Identity.PrincipalId -RoleDefinitionName "Key Vault Secrets User" -Scope $kv.ResourceId
}
catch 
{
    "Error assigning permissions to Automation account (for keyvault)."
    break
}

Write-Verbose "Adding workspacekey secret to keyvault."
try {
    $workspaceKey=(Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $logAnalyticsWorkspaceRG -Name $logAnalyticsworkspaceName).PrimarySharedKey
    $secretvalue = ConvertTo-SecureString $workspaceKey -AsPlainText -Force 
    $secret = Set-AzKeyVaultSecret -VaultName $keyVaultName -Name "WorkSpaceKey" -SecretValue $secretvalue
}
catch {"Error adding WS secret to KV.";break}
#endregion

#region Import main runbook
Write-Verbose "Importing Runbook." #only one for now, as a template.
try {
<<<<<<< HEAD
    Import-AzAutomationRunbook -Name $mainRunbookName -Path "$mainRunbookpath\main.ps1" -Description $mainRunbookDescription -Type PowerShell -Published `
    -ResourceGroupName $resourcegroup -AutomationAccountName $autoMationAccountName -Tags @{version=$newversion}
=======
    Import-AzAutomationRunbook -Name $mainRunbookName -Path "$mainRunbookpath\main.ps1" -Description $mainRunbookDescription -Type PowerShell -Published -ResourceGroupName $resourcegroup -AutomationAccountName $autoMationAccountName
>>>>>>> 90f025b360a6dcb00cdffa6cdf8d2892a3a6f256
    #Create schedule
    New-AzAutomationSchedule -ResourceGroupName $resourcegroup -AutomationAccountName $autoMationAccountName -Name "GR-Hourly" -StartTime (get-date).AddHours(1) -HourInterval 1
    #Register
    Register-AzAutomationScheduledRunbook -Name $mainRunbookName -ResourceGroupName $resourcegroup -AutomationAccountName $autoMationAccountName -ScheduleName "GR-Hourly"
}
catch {
    "Error importing Runbook."
    break
}
#endregion

#region Other secrects
#Breakglass accounts and UPNs
try {
    $secretvalue = ConvertTo-SecureString $bga1 -AsPlainText -Force 
    $secret = Set-AzKeyVaultSecret -VaultName $keyVaultName -Name "BGA1" -SecretValue $secretvalue
    $secretvalue = ConvertTo-SecureString $bga2 -AsPlainText -Force 
    $secret = Set-AzKeyVaultSecret -VaultName $keyVaultName -Name "BGA2" -SecretValue $secretvalue
#endregion

#region Assign permissions
    $GraphAppId="00000003-0000-0000-c000-000000000000"
    Write-Output "Adding Permissions to Automation Account - Managed Identity"
    import-module AzureAD.Standard.Preview
    AzureAD.Standard.Preview\Connect-AzureAD -Identity -TenantID $env:ACC_TID
    $MSI = (Get-AzureADServicePrincipal -Filter "displayName eq '$autoMationAccountName'")
    #Start-Sleep -Seconds 10
    $graph = Get-AzureADServicePrincipal -Filter "appId eq '$GraphAppId'"
    $appRoleIds=@("Organization.Read.All", "User.Read.All", "UserAuthenticationMethod.Read.All","Policy.Read.All")
    foreach ($approleidName in $appRoleIds)
    {
        Write-Output "Adding permission to $approleidName"
        $approleid=($graph.AppRoles | Where-Object {$_.Value -eq $approleidName}).Id
        if ($null -ne $approleid)
        {
            try {
                New-AzureAdServiceAppRoleAssignment -ObjectId $MSI.ObjectId -PrincipalId $MSI.ObjectId -ResourceId $graph.ObjectId -Id $approleid
            }
            catch {
                "Error assigning permissions $approleid to $approleidName"
            }
        }
        else {
            Write-Output "App Role Id $approleid Not found... :("
        }
    }
}
catch {
    "Error assigning permissions to graph API."
    break 
}
#endregion
try {
    Write-Output "Assigning reader access to the Automation Account Managed Identity for MG: $($rootmg.DisplayName)"
    $rootmg=get-azmanagementgroup | ? {$_.Id.Split("/")[4] -eq (Get-AzContext).Tenant.Id}
    $AAId=(Get-AzAutomationAccount -ResourceGroupName $resourcegroup -Name $autoMationAccountName).Identity.PrincipalId
    New-AzRoleAssignment -ObjectId $AAId -RoleDefinitionName Reader -Scope $rootmg.Id
    New-AzRoleAssignment -ObjectId $AAId -RoleDefinitionName "Reader and Data Access" -Scope (Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageaccountName).Id
}
catch {
    "Error assigning root management group permissions."
    break
}
Write-Output "Waiting 60 seconds to allow for management group permissions to be applied."
Start-Sleep -Seconds 60
try {
    Start-AzAutomationRunbook -Name "main" -AutomationAccountName $autoMationAccountName -ResourceGroupName $resourcegroup
}
catch { 
    "Error starting runbook."
}
$timetaken=((get-date)-$begin) 
"Time to deploy: $([Math]::Round($timetaken.TotalMinutes,0)) Minutes."

<<<<<<< HEAD

# SIG # Begin signature block
# MIInogYJKoZIhvcNAQcCoIInkzCCJ48CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAvK2KkFKfqmguV
# lEidXb+lUYDucQqmjPRX1n4nOJnmEaCCDYUwggYDMIID66ADAgECAhMzAAACU+OD
# 3pbexW7MAAAAAAJTMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjEwOTAyMTgzMzAwWhcNMjIwOTAxMTgzMzAwWjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDLhxHwq3OhH+4J+SX4qS/VQG8HybccH7tnG+BUqrXubfGuDFYPZ29uCuHfQlO1
# lygLgMpJ4Geh6/6poQ5VkDKfVssn6aA1PCzIh8iOPMQ9Mju3sLF9Sn+Pzuaie4BN
# rp0MuZLDEXgVYx2WNjmzqcxC7dY9SC3znOh5qUy2vnmWygC7b9kj0d3JrGtjc5q5
# 0WfV3WLXAQHkeRROsJFBZfXFGoSvRljFFUAjU/zdhP92P+1JiRRRikVy/sqIhMDY
# +7tVdzlE2fwnKOv9LShgKeyEevgMl0B1Fq7E2YeBZKF6KlhmYi9CE1350cnTUoU4
# YpQSnZo0YAnaenREDLfFGKTdAgMBAAGjggGCMIIBfjAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUlZpLWIccXoxessA/DRbe26glhEMw
# VAYDVR0RBE0wS6RJMEcxLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEWMBQGA1UEBRMNMjMwMDEyKzQ2NzU5ODAfBgNVHSMEGDAW
# gBRIbmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDEx
# XzIwMTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIB
# AKVY+yKcJVVxf9W2vNkL5ufjOpqcvVOOOdVyjy1dmsO4O8khWhqrecdVZp09adOZ
# 8kcMtQ0U+oKx484Jg11cc4Ck0FyOBnp+YIFbOxYCqzaqMcaRAgy48n1tbz/EFYiF
# zJmMiGnlgWFCStONPvQOBD2y/Ej3qBRnGy9EZS1EDlRN/8l5Rs3HX2lZhd9WuukR
# bUk83U99TPJyo12cU0Mb3n1HJv/JZpwSyqb3O0o4HExVJSkwN1m42fSVIVtXVVSa
# YZiVpv32GoD/dyAS/gyplfR6FI3RnCOomzlycSqoz0zBCPFiCMhVhQ6qn+J0GhgR
# BJvGKizw+5lTfnBFoqKZJDROz+uGDl9tw6JvnVqAZKGrWv/CsYaegaPePFrAVSxA
# yUwOFTkAqtNC8uAee+rv2V5xLw8FfpKJ5yKiMKnCKrIaFQDr5AZ7f2ejGGDf+8Tz
# OiK1AgBvOW3iTEEa/at8Z4+s1CmnEAkAi0cLjB72CJedU1LAswdOCWM2MDIZVo9j
# 0T74OkJLTjPd3WNEyw0rBXTyhlbYQsYt7ElT2l2TTlF5EmpVixGtj4ChNjWoKr9y
# TAqtadd2Ym5FNB792GzwNwa631BPCgBJmcRpFKXt0VEQq7UXVNYBiBRd+x4yvjqq
# 5aF7XC5nXCgjbCk7IXwmOphNuNDNiRq83Ejjnc7mxrJGMIIHejCCBWKgAwIBAgIK
# YQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEw
# OTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYD
# VQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+la
# UKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc
# 6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4D
# dato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+
# lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nk
# kDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6
# A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmd
# X4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL
# 5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zd
# sGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3
# T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS
# 4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRI
# bmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
# BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBD
# uRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEF
# BQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1h
# cnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkA
# YwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn
# 8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7
# v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0b
# pdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/
# KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvy
# CInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBp
# mLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJi
# hsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYb
# BL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbS
# oqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sL
# gOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtX
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGXMwghlvAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAJT44Pelt7FbswAAAAA
# AlMwDQYJYIZIAWUDBAIBBQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHx9
# B1ClZmQZWqqcd3IV2ibHWo6+xcqwnpicmWzlfOciMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQu
# Y29tIDANBgkqhkiG9w0BAQEFAASCAQA5DltmciIYoferbv9dObxF8srgRmsjLK0x
# ofF+Or8OCYeMgscPPJeP9s3YsqIJ4Bo2dDK7GlCxtN+IgXvImC05kztGcM73PzH7
# 23nBMeOqH90e4V42+3xhXMDxpNlrKl2NvpaVT1JSomG8zdlYWgm4GUy7CFBo5Q76
# 0loRqTwZmK6Gr3HnTd7Oiay0os7hlCUgllo2VOyRh0l9m7RnoBgge3etXjMMpLb8
# J4IEhie+LTKcGjockNV1k10B42jxNLAiU0NxrgxXJlNsZx0yRPebF/zugEp4QkzW
# 8yQcHFZDYKU+jm9Dph+c54AsUjoK8fqqYVAHcqeBjFDR2k1w6/3KoYIW+zCCFvcG
# CisGAQQBgjcDAwExghbnMIIW4wYJKoZIhvcNAQcCoIIW1DCCFtACAQMxDzANBglg
# hkgBZQMEAgEFADCCAU8GCyqGSIb3DQEJEAEEoIIBPgSCATowggE2AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEILkzsowbRo5s9gfj36jCE/9CSqHrnDJb
# RcykHnIrXn3QAgZiacMRdnoYETIwMjIwNTA0MjA0NTA4LjJaMASAAgH0oIHQpIHN
# MIHKMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQL
# ExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMg
# VFNTIEVTTjpENkJELUUzRTctMTY4NTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgU2VydmljZaCCEVQwggcMMIIE9KADAgECAhMzAAABnv3CLdgxWraxAAEA
# AAGeMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MB4XDTIxMTIwMjE5MDUyMFoXDTIzMDIyODE5MDUyMFowgcoxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkQ2QkQtRTNF
# Ny0xNjg1MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA7ulcpUh1w/A2vF5FTSKg4MFq
# U64S+V1wWsNmc3q5trK8VfjaS/2b+6VQEjv0wxoQBDHMGU8cmo7fCOL2eA55xfUw
# +LT+hBOUMdS0EKGQI6ueVB/aqqXNZ8ESTQZUIvlnQFeyIho0AXvCflmFd8rw6pRG
# BQuVTHvDrAe8jjKRawCGatw4T6UyyTNS0XTRFQLRhZS0+QWwcNxRuhIH0Leg4nwW
# LbGaroTwGhEfTyACxUMQNd/PooTUWSTCVDIV2GgEuqC0TeqWGQw6F8uKqnBhniDb
# EQUWfdUzepUIGnfAp2vqh9LQ0LEEiUH7++JyXYM5CKb8/w571BTWfb6podjsTZ/N
# qV+Jy7swGQj+Ps5hRmDwJaOsnJ03PWPFzbvF1SWL56PLmGIoEXUZtgGCH8NOA2BY
# VERPYZHJCiIcY6hETUcQNGXh01BwObemUt8UziTloHgeVtz0YbgEMoSE4xmlEFAI
# Esl8w86zmpDU1W44+/l/DhrBbUfDmD8wXu5d9Ui77nTTqvEsYdlQPlqBpnc4X/lu
# yZiBBgLaP//bvB1LZ6DcySv3cEtjGLnJ4ppTq8Sla56vY79YaYJhz6G1h55y4QIF
# 5x+Eo2m8j5BdQmXfCNgywueiOMHlqXK7afk3Yab8ARb1ouqJ07NbkhYOFAQKLTlS
# Y3VzSvtNSVWRe58bNXECAwEAAaOCATYwggEyMB0GA1UdDgQWBBRo0z6D0XWOlz7U
# JEk66IfZZGW7rTAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBfBgNV
# HR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Ny
# bC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmwwbAYI
# KwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAy
# MDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0G
# CSqGSIb3DQEBCwUAA4ICAQBUuVWOoZnPBh9g9fL/kk0APgPoE9XbhN8rjZ9Zh+NU
# y6rs1TS1tNwMwL7rnGHmtVWorUROVGGyM8VLFfRvLE6123YnM3lRuuiKS7pZYeCM
# an5/scxmzzmVlE+sALYF6txXzBmPZO96qPyEObIaE6HjIQZhy1noOd/rQXLvEs6H
# EhyU4nlnL+SppwLaCa2uUpg3WXRQQs9HD9yFKuJHnTdENioSqzA0QHg/wgs2tg1/
# AY/bUXj8nE5737EnAnOVbMQzQmp56vLVSfh0Gs0VSvADVtlDA4Fet4u0ihm9/rJS
# iP2PdqLjK0xYWouoeKwqI80rELSUEwnJyNEEw6Hsbc5mi7JrSrt4xdgMofIBXnfi
# kQ4g4bTXMmaCZvn5qmioUyIvYLj6Hne8L5+c3Xvd2a+kVwU7Vy9HZUdBTMP8D0FS
# Yy1RGhJ2FpymR/ZVPF2SVfsTplhQRWZHfkZ1Tlt2VuXgRrC3rswwgGpq7sqLcODw
# 9+k+nmBib+WL619YkWAA68VwlGIna2SWNrNCFWRYnKhoKeRbWGJwDKRO7criI9qO
# MvqJdW8t5UFejm9D+EZyuoJ7hAlgX5lko3rzn6/tNppLHlvKERBwJvcvV33HVHEO
# e7222rvPgEImvMBkHDV6cQJ6Cw8CfkQMnA5aXt3tmIWvZ17mM3FTJPdq/2yiNH8h
# jjCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZIhvcNAQEL
# BQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNV
# BAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDEwMB4X
# DTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIyNVowfDELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgUENBIDIwMTAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDk4aZM
# 57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXIyjVX9gF/bErg4r25PhdgM/9cT8dm
# 95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjoYH1qUoNEt6aORmsHFPPFdvWGUNzB
# RMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1yaa8dq6z2Nr41JmTamDu6GnszrYBb
# fowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v3byNpOORj7I5LFGc6XBpDco2LXCO
# Mcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pGve2krnopN6zL64NF50ZuyjLVwIYw
# XE8s4mKyzbnijYjklqwBSru+cakXW2dg3viSkR4dPf0gz3N9QZpGdc3EXzTdEonW
# /aUgfX782Z5F37ZyL9t9X4C626p+Nuw2TPYrbqgSUei/BQOj0XOmTTd0lBw0gg/w
# EPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlMjgK8QmguEOqEUUbi0b1qGFphAXPK
# Z6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJNmSLW6CmgyFdXzB0kZSU2LlQ+QuJYfM2
# BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AFemzFER1y7435UsSFF5PAPBXbGjfH
# CBUYP3irRbb1Hode2o+eFnJpxq57t7c+auIurQIDAQABo4IB3TCCAdkwEgYJKwYB
# BAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIEFgQUKqdS/mTEmr6CkTxGNSnPEP8v
# BO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMFwGA1UdIARVMFMwUQYM
# KwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTATBgNVHSUEDDAKBggrBgEF
# BQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvXzpoYxDBW
# BgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYIKwYBBQUH
# AQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# L2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDANBgkqhkiG9w0BAQsF
# AAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL/Klv6lwUtj5OR2R4sQaTlz0xM7U518Jx
# Nj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZnOlNN3Zi6th542DYunKmCVgADsAW+
# iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1bSNU5HhTdSRXud2f8449xvNo32X2
# pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4rPf5KYnDvBewVIVCs/wMnosZiefw
# C2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU6ZGyqVvfSaN0DLzskYDSPeZKPmY7
# T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDFNLB62FD+CljdQDzHVG2dY3RILLFO
# Ry3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/HltEAY5aGZFrDZ+kKNxnGSgkujhL
# mm77IVRrakURR6nxt67I6IleT53S0Ex2tVdUCbFpAUR+fKFhbHP+CrvsQWY9af3L
# wUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKiexcdFYmNcP7ntdAoGokLjzbaukz5
# m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9JZTmdHRbatGePu1+oDEzfbzL6Xu/OHBE
# 0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6FwZvKhggLLMIICNAIB
# ATCB+KGB0KSBzTCByjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEmMCQGA1UE
# CxMdVGhhbGVzIFRTUyBFU046RDZCRC1FM0U3LTE2ODUxJTAjBgNVBAMTHE1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMVAAIVwjmQWw8Q
# PweU3oukX/NC/RoXoIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTAwDQYJKoZIhvcNAQEFBQACBQDmHNMFMCIYDzIwMjIwNTA0MTgyNTA5WhgPMjAy
# MjA1MDUxODI1MDlaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIFAOYc0wUCAQAwBwIB
# AAICFkgwBwIBAAICEmgwCgIFAOYeJIUCAQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYK
# KwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkqhkiG9w0BAQUF
# AAOBgQATLmVi0GzHhhhl7BMDZqE8G7takLf16eGZWHmSBvkFxigcJWnl3QBK14HR
# bjCurKIEIqSBWzIcAqVkaMfsg4dyoYRSJinDkusBZ6E5eUPSmB1VEXe5zu15GbSQ
# iFFfl726UkJCwywAxlBdaV33anClko+CkUJMpmvkg5tvOS8GFzGCBA0wggQJAgEB
# MIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAABnv3CLdgxWrax
# AAEAAAGeMA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcN
# AQkQAQQwLwYJKoZIhvcNAQkEMSIEIO8bRPiORKd1t6keKbx19iVPD1j0juFtEwdf
# uZyIyaHhMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQgDsVWMiL+XI9PqWZC
# bqyfsgq6tEXuV4K5H0rVDv1vPBkwgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFt
# cCBQQ0EgMjAxMAITMwAAAZ79wi3YMVq2sQABAAABnjAiBCB4pFF09AxuoxScH5QK
# ccsQYEYN+RPIsP7woGgzvboxADANBgkqhkiG9w0BAQsFAASCAgC8bcm5rdw3XnX8
# tCFNY09piUy2Vf7XgDcAwIPMqc00cF3a8EG6c3ZcaxhheAGW5Sm9fJzSEBpo541q
# Q6rso94CEfiUuh0X/SJhJDpgHkVAV1sPWX4ZWUHWuGsnQz/0qzX4HqNXE6XhpfWj
# /EYB4VCGEdVjcwNzjjRkWPpUrnXBXynx8JrgtuVOJPXmv1CyHg8YCX3mdWbuj0Uw
# WlH2QmJuO7EZtTsrx0bnxMR6uPv5uHrc5A95LFvu+mZhUCMgv6abwgcVkrurvn9k
# 8yDqyqWf0R1t/flyOl3wj6wNvNXNgq4o4fdTq6VHO2Rom2BfK/T2aTxM4uB5fGQF
# cNjkGcyxdTu8uXTOYmq2mzNe5w4mr6NlFYAjFsIETmnzPQ/EhdeoUXYqSRAhZuiL
# GvxF4fdupF04CuPPX9gi8md+EFj+NVHWonM1t+b7OZVOHJyn3eHr3GeVOsP6l0CJ
# A4w6iHcZla2XPOy7Tf/Q5GLo79Tl6JkgwRNC9ffbcSjhIEA1aF4dfsZc5+Q+AJb/
# XR4QIqtS/pjkSMTi+NJLDnhB8CshEK6s2xyw/1A/EhGuAArYWohGUjg8ISlM9pSV
# K74ff0St4hFM6vb4YzEkQW0HErW3Cdw7RxOS+LMKcfelwiHvPudW0BSj596dq1m3
# XOilgryBbWnuK6xZnox6tHBQkVan1Q==
# SIG # End signature block
=======

# SIG # Begin signature block
# MIInogYJKoZIhvcNAQcCoIInkzCCJ48CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAvK2KkFKfqmguV
# lEidXb+lUYDucQqmjPRX1n4nOJnmEaCCDYUwggYDMIID66ADAgECAhMzAAACU+OD
# 3pbexW7MAAAAAAJTMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjEwOTAyMTgzMzAwWhcNMjIwOTAxMTgzMzAwWjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDLhxHwq3OhH+4J+SX4qS/VQG8HybccH7tnG+BUqrXubfGuDFYPZ29uCuHfQlO1
# lygLgMpJ4Geh6/6poQ5VkDKfVssn6aA1PCzIh8iOPMQ9Mju3sLF9Sn+Pzuaie4BN
# rp0MuZLDEXgVYx2WNjmzqcxC7dY9SC3znOh5qUy2vnmWygC7b9kj0d3JrGtjc5q5
# 0WfV3WLXAQHkeRROsJFBZfXFGoSvRljFFUAjU/zdhP92P+1JiRRRikVy/sqIhMDY
# +7tVdzlE2fwnKOv9LShgKeyEevgMl0B1Fq7E2YeBZKF6KlhmYi9CE1350cnTUoU4
# YpQSnZo0YAnaenREDLfFGKTdAgMBAAGjggGCMIIBfjAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUlZpLWIccXoxessA/DRbe26glhEMw
# VAYDVR0RBE0wS6RJMEcxLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEWMBQGA1UEBRMNMjMwMDEyKzQ2NzU5ODAfBgNVHSMEGDAW
# gBRIbmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDEx
# XzIwMTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIB
# AKVY+yKcJVVxf9W2vNkL5ufjOpqcvVOOOdVyjy1dmsO4O8khWhqrecdVZp09adOZ
# 8kcMtQ0U+oKx484Jg11cc4Ck0FyOBnp+YIFbOxYCqzaqMcaRAgy48n1tbz/EFYiF
# zJmMiGnlgWFCStONPvQOBD2y/Ej3qBRnGy9EZS1EDlRN/8l5Rs3HX2lZhd9WuukR
# bUk83U99TPJyo12cU0Mb3n1HJv/JZpwSyqb3O0o4HExVJSkwN1m42fSVIVtXVVSa
# YZiVpv32GoD/dyAS/gyplfR6FI3RnCOomzlycSqoz0zBCPFiCMhVhQ6qn+J0GhgR
# BJvGKizw+5lTfnBFoqKZJDROz+uGDl9tw6JvnVqAZKGrWv/CsYaegaPePFrAVSxA
# yUwOFTkAqtNC8uAee+rv2V5xLw8FfpKJ5yKiMKnCKrIaFQDr5AZ7f2ejGGDf+8Tz
# OiK1AgBvOW3iTEEa/at8Z4+s1CmnEAkAi0cLjB72CJedU1LAswdOCWM2MDIZVo9j
# 0T74OkJLTjPd3WNEyw0rBXTyhlbYQsYt7ElT2l2TTlF5EmpVixGtj4ChNjWoKr9y
# TAqtadd2Ym5FNB792GzwNwa631BPCgBJmcRpFKXt0VEQq7UXVNYBiBRd+x4yvjqq
# 5aF7XC5nXCgjbCk7IXwmOphNuNDNiRq83Ejjnc7mxrJGMIIHejCCBWKgAwIBAgIK
# YQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEw
# OTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYD
# VQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+la
# UKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc
# 6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4D
# dato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+
# lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nk
# kDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6
# A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmd
# X4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL
# 5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zd
# sGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3
# T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS
# 4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRI
# bmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
# BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBD
# uRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEF
# BQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1h
# cnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkA
# YwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn
# 8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7
# v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0b
# pdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/
# KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvy
# CInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBp
# mLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJi
# hsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYb
# BL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbS
# oqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sL
# gOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtX
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGXMwghlvAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAJT44Pelt7FbswAAAAA
# AlMwDQYJYIZIAWUDBAIBBQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHx9
# B1ClZmQZWqqcd3IV2ibHWo6+xcqwnpicmWzlfOciMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQu
# Y29tIDANBgkqhkiG9w0BAQEFAASCAQA5DltmciIYoferbv9dObxF8srgRmsjLK0x
# ofF+Or8OCYeMgscPPJeP9s3YsqIJ4Bo2dDK7GlCxtN+IgXvImC05kztGcM73PzH7
# 23nBMeOqH90e4V42+3xhXMDxpNlrKl2NvpaVT1JSomG8zdlYWgm4GUy7CFBo5Q76
# 0loRqTwZmK6Gr3HnTd7Oiay0os7hlCUgllo2VOyRh0l9m7RnoBgge3etXjMMpLb8
# J4IEhie+LTKcGjockNV1k10B42jxNLAiU0NxrgxXJlNsZx0yRPebF/zugEp4QkzW
# 8yQcHFZDYKU+jm9Dph+c54AsUjoK8fqqYVAHcqeBjFDR2k1w6/3KoYIW+zCCFvcG
# CisGAQQBgjcDAwExghbnMIIW4wYJKoZIhvcNAQcCoIIW1DCCFtACAQMxDzANBglg
# hkgBZQMEAgEFADCCAU8GCyqGSIb3DQEJEAEEoIIBPgSCATowggE2AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEILkzsowbRo5s9gfj36jCE/9CSqHrnDJb
# RcykHnIrXn3QAgZiacMRdnoYETIwMjIwNTA0MjA0NTA4LjJaMASAAgH0oIHQpIHN
# MIHKMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQL
# ExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMg
# VFNTIEVTTjpENkJELUUzRTctMTY4NTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgU2VydmljZaCCEVQwggcMMIIE9KADAgECAhMzAAABnv3CLdgxWraxAAEA
# AAGeMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MB4XDTIxMTIwMjE5MDUyMFoXDTIzMDIyODE5MDUyMFowgcoxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkQ2QkQtRTNF
# Ny0xNjg1MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA7ulcpUh1w/A2vF5FTSKg4MFq
# U64S+V1wWsNmc3q5trK8VfjaS/2b+6VQEjv0wxoQBDHMGU8cmo7fCOL2eA55xfUw
# +LT+hBOUMdS0EKGQI6ueVB/aqqXNZ8ESTQZUIvlnQFeyIho0AXvCflmFd8rw6pRG
# BQuVTHvDrAe8jjKRawCGatw4T6UyyTNS0XTRFQLRhZS0+QWwcNxRuhIH0Leg4nwW
# LbGaroTwGhEfTyACxUMQNd/PooTUWSTCVDIV2GgEuqC0TeqWGQw6F8uKqnBhniDb
# EQUWfdUzepUIGnfAp2vqh9LQ0LEEiUH7++JyXYM5CKb8/w571BTWfb6podjsTZ/N
# qV+Jy7swGQj+Ps5hRmDwJaOsnJ03PWPFzbvF1SWL56PLmGIoEXUZtgGCH8NOA2BY
# VERPYZHJCiIcY6hETUcQNGXh01BwObemUt8UziTloHgeVtz0YbgEMoSE4xmlEFAI
# Esl8w86zmpDU1W44+/l/DhrBbUfDmD8wXu5d9Ui77nTTqvEsYdlQPlqBpnc4X/lu
# yZiBBgLaP//bvB1LZ6DcySv3cEtjGLnJ4ppTq8Sla56vY79YaYJhz6G1h55y4QIF
# 5x+Eo2m8j5BdQmXfCNgywueiOMHlqXK7afk3Yab8ARb1ouqJ07NbkhYOFAQKLTlS
# Y3VzSvtNSVWRe58bNXECAwEAAaOCATYwggEyMB0GA1UdDgQWBBRo0z6D0XWOlz7U
# JEk66IfZZGW7rTAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBfBgNV
# HR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Ny
# bC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmwwbAYI
# KwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAy
# MDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0G
# CSqGSIb3DQEBCwUAA4ICAQBUuVWOoZnPBh9g9fL/kk0APgPoE9XbhN8rjZ9Zh+NU
# y6rs1TS1tNwMwL7rnGHmtVWorUROVGGyM8VLFfRvLE6123YnM3lRuuiKS7pZYeCM
# an5/scxmzzmVlE+sALYF6txXzBmPZO96qPyEObIaE6HjIQZhy1noOd/rQXLvEs6H
# EhyU4nlnL+SppwLaCa2uUpg3WXRQQs9HD9yFKuJHnTdENioSqzA0QHg/wgs2tg1/
# AY/bUXj8nE5737EnAnOVbMQzQmp56vLVSfh0Gs0VSvADVtlDA4Fet4u0ihm9/rJS
# iP2PdqLjK0xYWouoeKwqI80rELSUEwnJyNEEw6Hsbc5mi7JrSrt4xdgMofIBXnfi
# kQ4g4bTXMmaCZvn5qmioUyIvYLj6Hne8L5+c3Xvd2a+kVwU7Vy9HZUdBTMP8D0FS
# Yy1RGhJ2FpymR/ZVPF2SVfsTplhQRWZHfkZ1Tlt2VuXgRrC3rswwgGpq7sqLcODw
# 9+k+nmBib+WL619YkWAA68VwlGIna2SWNrNCFWRYnKhoKeRbWGJwDKRO7criI9qO
# MvqJdW8t5UFejm9D+EZyuoJ7hAlgX5lko3rzn6/tNppLHlvKERBwJvcvV33HVHEO
# e7222rvPgEImvMBkHDV6cQJ6Cw8CfkQMnA5aXt3tmIWvZ17mM3FTJPdq/2yiNH8h
# jjCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZIhvcNAQEL
# BQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNV
# BAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDEwMB4X
# DTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIyNVowfDELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgUENBIDIwMTAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDk4aZM
# 57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXIyjVX9gF/bErg4r25PhdgM/9cT8dm
# 95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjoYH1qUoNEt6aORmsHFPPFdvWGUNzB
# RMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1yaa8dq6z2Nr41JmTamDu6GnszrYBb
# fowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v3byNpOORj7I5LFGc6XBpDco2LXCO
# Mcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pGve2krnopN6zL64NF50ZuyjLVwIYw
# XE8s4mKyzbnijYjklqwBSru+cakXW2dg3viSkR4dPf0gz3N9QZpGdc3EXzTdEonW
# /aUgfX782Z5F37ZyL9t9X4C626p+Nuw2TPYrbqgSUei/BQOj0XOmTTd0lBw0gg/w
# EPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlMjgK8QmguEOqEUUbi0b1qGFphAXPK
# Z6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJNmSLW6CmgyFdXzB0kZSU2LlQ+QuJYfM2
# BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AFemzFER1y7435UsSFF5PAPBXbGjfH
# CBUYP3irRbb1Hode2o+eFnJpxq57t7c+auIurQIDAQABo4IB3TCCAdkwEgYJKwYB
# BAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIEFgQUKqdS/mTEmr6CkTxGNSnPEP8v
# BO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMFwGA1UdIARVMFMwUQYM
# KwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTATBgNVHSUEDDAKBggrBgEF
# BQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvXzpoYxDBW
# BgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYIKwYBBQUH
# AQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# L2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDANBgkqhkiG9w0BAQsF
# AAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL/Klv6lwUtj5OR2R4sQaTlz0xM7U518Jx
# Nj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZnOlNN3Zi6th542DYunKmCVgADsAW+
# iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1bSNU5HhTdSRXud2f8449xvNo32X2
# pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4rPf5KYnDvBewVIVCs/wMnosZiefw
# C2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU6ZGyqVvfSaN0DLzskYDSPeZKPmY7
# T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDFNLB62FD+CljdQDzHVG2dY3RILLFO
# Ry3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/HltEAY5aGZFrDZ+kKNxnGSgkujhL
# mm77IVRrakURR6nxt67I6IleT53S0Ex2tVdUCbFpAUR+fKFhbHP+CrvsQWY9af3L
# wUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKiexcdFYmNcP7ntdAoGokLjzbaukz5
# m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9JZTmdHRbatGePu1+oDEzfbzL6Xu/OHBE
# 0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6FwZvKhggLLMIICNAIB
# ATCB+KGB0KSBzTCByjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEmMCQGA1UE
# CxMdVGhhbGVzIFRTUyBFU046RDZCRC1FM0U3LTE2ODUxJTAjBgNVBAMTHE1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMVAAIVwjmQWw8Q
# PweU3oukX/NC/RoXoIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTAwDQYJKoZIhvcNAQEFBQACBQDmHNMFMCIYDzIwMjIwNTA0MTgyNTA5WhgPMjAy
# MjA1MDUxODI1MDlaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIFAOYc0wUCAQAwBwIB
# AAICFkgwBwIBAAICEmgwCgIFAOYeJIUCAQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYK
# KwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkqhkiG9w0BAQUF
# AAOBgQATLmVi0GzHhhhl7BMDZqE8G7takLf16eGZWHmSBvkFxigcJWnl3QBK14HR
# bjCurKIEIqSBWzIcAqVkaMfsg4dyoYRSJinDkusBZ6E5eUPSmB1VEXe5zu15GbSQ
# iFFfl726UkJCwywAxlBdaV33anClko+CkUJMpmvkg5tvOS8GFzGCBA0wggQJAgEB
# MIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAABnv3CLdgxWrax
# AAEAAAGeMA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcN
# AQkQAQQwLwYJKoZIhvcNAQkEMSIEIO8bRPiORKd1t6keKbx19iVPD1j0juFtEwdf
# uZyIyaHhMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQgDsVWMiL+XI9PqWZC
# bqyfsgq6tEXuV4K5H0rVDv1vPBkwgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFt
# cCBQQ0EgMjAxMAITMwAAAZ79wi3YMVq2sQABAAABnjAiBCB4pFF09AxuoxScH5QK
# ccsQYEYN+RPIsP7woGgzvboxADANBgkqhkiG9w0BAQsFAASCAgC8bcm5rdw3XnX8
# tCFNY09piUy2Vf7XgDcAwIPMqc00cF3a8EG6c3ZcaxhheAGW5Sm9fJzSEBpo541q
# Q6rso94CEfiUuh0X/SJhJDpgHkVAV1sPWX4ZWUHWuGsnQz/0qzX4HqNXE6XhpfWj
# /EYB4VCGEdVjcwNzjjRkWPpUrnXBXynx8JrgtuVOJPXmv1CyHg8YCX3mdWbuj0Uw
# WlH2QmJuO7EZtTsrx0bnxMR6uPv5uHrc5A95LFvu+mZhUCMgv6abwgcVkrurvn9k
# 8yDqyqWf0R1t/flyOl3wj6wNvNXNgq4o4fdTq6VHO2Rom2BfK/T2aTxM4uB5fGQF
# cNjkGcyxdTu8uXTOYmq2mzNe5w4mr6NlFYAjFsIETmnzPQ/EhdeoUXYqSRAhZuiL
# GvxF4fdupF04CuPPX9gi8md+EFj+NVHWonM1t+b7OZVOHJyn3eHr3GeVOsP6l0CJ
# A4w6iHcZla2XPOy7Tf/Q5GLo79Tl6JkgwRNC9ffbcSjhIEA1aF4dfsZc5+Q+AJb/
# XR4QIqtS/pjkSMTi+NJLDnhB8CshEK6s2xyw/1A/EhGuAArYWohGUjg8ISlM9pSV
# K74ff0St4hFM6vb4YzEkQW0HErW3Cdw7RxOS+LMKcfelwiHvPudW0BSj596dq1m3
# XOilgryBbWnuK6xZnox6tHBQkVan1Q==
# SIG # End signature block
>>>>>>> 90f025b360a6dcb00cdffa6cdf8d2892a3a6f256
