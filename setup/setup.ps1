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
$bga1=$config.bga1 #Break glass account 1
$bga2=$config.bga2 #Break glass account 2
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
    Import-AzAutomationRunbook -Name $mainRunbookName -Path "$mainRunbookpath\main.ps1" -Description $mainRunbookDescription -Type PowerShell -Published -ResourceGroupName $resourcegroup -AutomationAccountName $autoMationAccountName
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
# SIG # Begin signature block
# MIInswYJKoZIhvcNAQcCoIInpDCCJ6ACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAhCJGtOq4Wc7Eh
# xGSs5AHjmjjdt/ZFyIXf1KQEI7ko1aCCDYUwggYDMIID66ADAgECAhMzAAACU+OD
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGYQwghmAAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAJT44Pelt7FbswAAAAA
# AlMwDQYJYIZIAWUDBAIBBQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDu/
# MazCLj7oGEuATq3wLcJco6pgq3At+tuIUYzloPITMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQu
# Y29tIDANBgkqhkiG9w0BAQEFAASCAQBvH5F/Xf1ZsH0iOhAlWJ+obIK0yAU5VUcT
# lCZ3FcEzaLup1wqKAOxqiyRI0yiTCmoMOfPAFaLDaq9SX9glJd0qWA4U5MxEiYQe
# aJW4HFHEgBHyonm0rdJQD1svQlXTUQBWfBT/DkmxZh2Vjb49tbvcKLO8NCUP7B0J
# hO+HzYB2R4Lu5AfG3BOvhkOQ/tNCFovKsFwYFfbS4GejU0k0Vj6OU8CUAj5mLudk
# o4a8pjB+mtPjgn2yxRPcHt62oBLpkoSd61ke9//F4GAFfiHWORT6KBdbQqtrHNOh
# b0rqR89exOyvgPfI2IJnGZBHzpd9MOULb3w+Vm7avBMoTvonGFcXoYIXDDCCFwgG
# CisGAQQBgjcDAwExghb4MIIW9AYJKoZIhvcNAQcCoIIW5TCCFuECAQMxDzANBglg
# hkgBZQMEAgEFADCCAVUGCyqGSIb3DQEJEAEEoIIBRASCAUAwggE8AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIAJNI4yemNcb48ByYT2duzWNvkGpoTDx
# UfA0dJ2PJdfMAgZia1SJQ2YYEzIwMjIwNDI5MTcxNTE4LjAyN1owBIACAfSggdSk
# gdEwgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNV
# BAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1U
# aGFsZXMgVFNTIEVTTjo4OTdBLUUzNTYtMTcwMTElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZaCCEV8wggcQMIIE+KADAgECAhMzAAABqwkJ76tj
# 1OipAAEAAAGrMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwMB4XDTIyMDMwMjE4NTEyOFoXDTIzMDUxMTE4NTEyOFowgc4xCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29m
# dCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVT
# Tjo4OTdBLUUzNTYtMTcwMTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# U2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMmdS1o5dehA
# SUsscLqyx2wm/WirNUfqkGBymDItYzEnoKtkhrd7wNsJs4g+BuM3uBX81WnO270l
# krC0e1mmDqQt420Tmb8lwsjQKM6mEaNQIfXDronrVN3aw1lx9bAf7VZEA3kHFql6
# YAO3kjQ6PftA4iVHX3JVv98ntjkbtqzKeJMaNWd8dBaAD3RCliMoajTDGbyYNKTv
# xBhWILyJ8WYdJ/NBDpqPzQl+pxm6ZZVSeBQAIOubZjU0vfpECxHC5vI1ErrqapG+
# 0oBhhON+gllVklPAWZv2iv0mgjCTj7YNKX7yL2x2TvrvHVq5GPNa5fNbpy39t5cv
# iiYqMf1RZVZccdr+2vApk5ib5a4O8SiAgPSUwYGoOwbZG1onHij0ATPLkgKUfgaP
# zFfd5JZSbRl2Xg347/LjWQLR+KjAyACFb06bqWzvHtQJTND8Y0j5Y2SBnSCqV2zN
# HSVts4+aUfkUhsKS+GAXS3j5XUgYA7SMNog76Nnss5l01nEX7sHDdYykYhzuQKFr
# T70XVTZeX25tSBfy3VaczYd1JSI/9wOGqbFU52NyrlsA1qimxOhsuds7Pxo+jO3R
# jV/kC+AEOoVaXDdminsc3PtlBCVh/sgYno9AUymblSRmee1gwlnlZJ0uiHKI9q2H
# FgZWM10yPG5gVt0prXnJFi1Wxmmg+BH/AgMBAAGjggE2MIIBMjAdBgNVHQ4EFgQU
# FFvO8o1eNcSCIQZMvqGfdNL+pqowHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacb
# UzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAo
# MSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1w
# JTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggr
# BgEFBQcDCDANBgkqhkiG9w0BAQsFAAOCAgEAykuUgTc1KMszMgsHbhgjgEGv/dCH
# Ff0by99C45SR770/udCNNeqlT610Ehz13xGFU6Hci+TLUPUnhvUnSuz7xkiWRru5
# RjZZmSonEVv8npa3z1QveUfngtyi0Jd6qlSykoEVJ6tDuR1Kw9xU9yvthZWhQs/y
# myOwh+mxt0C9wbeLJ92er2vc9ly12pFxbCNDJ+mQ7v520hAvreWqZ02GOJhw0R4c
# 1iP39iNBzHOoz+DsO0sYjwhaz9HrvYMEzOD1MJdLPWfUFsZ//iTd3jzEykk02Wjn
# ZNzIe2ENfmQ/KblGXHeSe8JYqimTFxl5keMfLUELjAh0mhQ1vLCJZ20BwC4O57Eg
# 7yO/YuBno+4RrV0CD2gp4BO10KFW2SQ/MhvRWK7HbgS6Bzt70rkIeSUto7pRkHMq
# rnhubITcXddky6GtZsmwM3hvqXuStMeU1W5NN3HA8ypjPLd/bomfGx96Huw8Orft
# cQvk7thdNu4JhAyKUXUP7dKMCJfrOdplg0j1tE0aiE+pDTSQVmPzGezCL42slyPJ
# VXpu4xxE0hpACr2ua0LHv/LB6RV5C4CO4Ms/pfal//F3O+hJZe5ixevzKNkXXbxP
# Oa1R+SIrW/rHZM6RIDLTJxTGFDM1hQDyafGu9S/a7umkvilgBHNxZfk0IYE7RRWJ
# cG7oiY+FGdx1cs0wggdxMIIFWaADAgECAhMzAAAAFcXna54Cm0mZAAAAAAAVMA0G
# CSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3Jp
# dHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5MzAxODMyMjVaMHwxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFBDQSAyMDEwMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51yMo1V/YBf2xK4OK9
# uT4XYDP/XE/HZveVU3Fa4n5KWv64NmeFRiMMtY0Tz3cywBAY6GB9alKDRLemjkZr
# BxTzxXb1hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9cmmvHaus9ja+NSZk
# 2pg7uhp7M62AW36MEBydUv626GIl3GoPz130/o5Tz9bshVZN7928jaTjkY+yOSxR
# nOlwaQ3KNi1wjjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDuaRr3tpK56KTesy+uD
# RedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7vnGpF1tnYN74kpEeHT39IM9zfUGa
# RnXNxF803RKJ1v2lIH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2K26oElHovwUDo9Fz
# pk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhzPUNOwTM5TI4CvEJoLhDqhFFG
# 4tG9ahhaYQFzymeiXtcodgLiMxhy16cg8ML6EgrXY28MyTZki1ugpoMhXV8wdJGU
# lNi5UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsluq9QBXpsxREdcu+N+VLE
# hReTwDwV2xo3xwgVGD94q0W29R6HXtqPnhZyacaue7e3PmriLq0CAwEAAaOCAd0w
# ggHZMBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUCBBYEFCqnUv5kxJq+
# gpE8RjUpzxD/LwTuMB0GA1UdDgQWBBSfpxVdAF5iXYP05dJlpxtTNRnpcjBcBgNV
# HSAEVTBTMFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wEwYDVR0l
# BAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0P
# BAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9
# lJBb186aGMQwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQu
# Y29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3Js
# MFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3Nv
# ZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcnQwDQYJ
# KoZIhvcNAQELBQADggIBAJ1VffwqreEsH2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEG
# k5c9MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulmZzpTTd2YurYeeNg2
# LpypglYAA7AFvonoaeC6Ce5732pvvinLbtg/SHUB2RjebYIM9W0jVOR4U3UkV7nd
# n/OOPcbzaN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECWOKz3+SmJw7wXsFSF
# QrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsIdw2FzLixre24/LAl4FOmRsqlb30mjdAy8
# 7JGA0j3mSj5mO0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSwethQ/gpY3UA8
# x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9swFXSVRk2XPXfx5bRAGOWhmRaw2f
# pCjcZxkoJLo4S5pu+yFUa2pFEUep8beuyOiJXk+d0tBMdrVXVAmxaQFEfnyhYWxz
# /gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFRhLy/AsGConsXHRWJjXD+57XQ
# KBqJC4822rpM+Zv/Cuk0+CQ1ZyvgDbjmjJnW4SLq8CdCPSWU5nR0W2rRnj7tfqAx
# M328y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQwXEGahC0HVUzWLOhcGby
# oYIC0jCCAjsCAQEwgfyhgdSkgdEwgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0
# byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo4OTdBLUUzNTYtMTcwMTEl
# MCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsO
# AwIaAxUAW6h6/24WCo7WZz6CEVAeLztcmD6ggYMwgYCkfjB8MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIFAOYWe7wwIhgPMjAyMjA0
# MjkxODU5MDhaGA8yMDIyMDQzMDE4NTkwOFowdzA9BgorBgEEAYRZCgQBMS8wLTAK
# AgUA5hZ7vAIBADAKAgEAAgISZgIB/zAHAgEAAgIUJzAKAgUA5hfNPAIBADA2Bgor
# BgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAID
# AYagMA0GCSqGSIb3DQEBBQUAA4GBADznDbNFJ8zv53AFfZLs+yeeZdle+LVhA2YH
# f0uRIHWBR5UOadrTJDBiCg4U/1Psuvw3bIfTD5rZUVNikRnrNm3RgPGuL3qnQsHl
# dFyBdC6kBG3bYCVkbw1PNZ026dDMm0w+hdUweOBFZJheGNLpjlsGkmmXzUr7YdJQ
# haur/TfnMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTACEzMAAAGrCQnvq2PU6KkAAQAAAaswDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqG
# SIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgHUF36So7aHXF
# Huqwtavwf6nWMYLl3uQkQjB4qoDyyJwwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHk
# MIG9BCAOHK/6sIVgEVSVD3Arvk6OyQKvRxFHKyraUzbN1/AKVzCBmDCBgKR+MHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAABqwkJ76tj1OipAAEAAAGr
# MCIEIGg2yu7pRmTm8sj3qoBVoN0lKlDtsWG2culpmllr+nqGMA0GCSqGSIb3DQEB
# CwUABIICAG5kGDhTkwyMKbW4OXXAPoKryjzg9TVddem9BsaH7rVW/uf6QGasK2Uy
# 2KKr+q3lZWEFcLAwqsibrjfcQuEM4jCqpt/oht/KJbmdiAtbo63lrO8l/zmP1i7r
# ODGAey3DYBLwnGp8X9F0bKtxENLxVquOpww5KbT3LbCVl//Y7KCYj1seHJqfg3BS
# e+jJFNA0b9NGA0wokfBQ/6dPPxi+0dGl5RvTWs30YPbzg5nS7rj8j7Fifm1hKeqH
# OCRPZlaKhtGlVKFvpISoH1tY7p9W2SY+SA8bNkdzbmzhXHFTifhSUTcxoo+D2kWc
# MgIGYCTgAvDER/1oIIfjs1zZ41hoxyZuSH4cBB5AzgqbwYvaXP1VBCAlMOEEOkWB
# /RbZJYO92wposQ+M1jHhkR0f0vuUY8FJHJRHHLn+Jj9cP30UNbKWfuE/+YX5LJ/0
# 5Ml26CjkA3LoX9rz+sOq64mxkk2PFPybaJhP0fqq8URQ230Omnae4cQvmvCmFba/
# PQMQVxqEb98IX0Hh5N3Upgb3eUWsC47fHhZ70rbRo1QLObJb5ULS1Rd3ebVNBCYZ
# YOcp+65yT7B578ErKQ6ICcOiVv2d5QwGgOHmYPn+4C5LQbdga0QCRHzqplpfK4nr
# QU1nm4WWG0+QtXdXJet6av6eNCrVp+N97gAQWgkJOuZ7yBHAIXrs
# SIG # End signature block
