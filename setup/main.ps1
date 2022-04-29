Disable-AzContextAutosave

#region Parameters 
$CtrName1 = "GUARDRAIL 1: PROTECT ROOT / GLOBAL ADMINS ACCOUNT"
$CtrName2 = "GUARDRAIL 2: MANAGEMENT OF ADMINISTRATIVE PRIVILEGES"
$CtrName3 = "GUARDRAIL 3: CLOUD CONSOLE ACCESS"
$CtrName4 = "GUARDRAIL 4: ENTERPRISE MONITORING ACCOUNTS"
$CtrName5 = "GUARDRAIL 5: DATA LOCATION"
$CtrName6 = "GUARDRAIL 6: PROTECTION OF DATA-AT-REST"
$CtrName7 = "GUARDRAIL 7: PROTECTION OF DATA-IN-TRANSIT"
$CtrName8 = "GUARDRAIL 8: NETWORK SEGMENTATION AND SEPARATION"
$CtrName9 = "GUARDRAIL 9: NETWORK SECURITY SERVICES"
$CtrName10 = "GUARDRAIL 10: CYBER DEFENSE SERVICES"
$CtrName11 = "GUARDRAIL 11: LOGGING AND MONITORING"
$CtrName12 = "GUARDRAIL 12: CONFIGURATION OF CLOUD MARKETPLACES"

$WorkSpaceID=Get-AutomationVariable -Name "WorkSpaceID" 
$LogType=Get-AutomationVariable -Name "LogType" 
$KeyVaultName=Get-AutomationVariable -Name "KeyVaultName" 
$GuardrailWorkspaceIDKeyName=Get-AutomationVariable -Name "GuardrailWorkspaceIDKeyName" 
$StorageAccountName=Get-AutomationVariable -Name "StorageAccountName" 
$ContainerName=Get-AutomationVariable -Name "ContainerName" 
$PBMMPolicyID=Get-AutomationVariable -Name "PBMMPolicyID"
$ResourceGroupName=Get-AutomationVariable -Name "ResourceGroupName"
$AllowedLocationPolicyId=Get-AutomationVariable -Name "AllowedLocationPolicyId"
$DepartmentNumber=Get-AutomationVariable -Name "DepartmentNumber"
$CBSSubscriptionName =Get-AutomationVariable -Name "CBSSubscriptionName"
$SecurityLAWResourceId=Get-AutomationVariable -Name "SecurityLAWResourceId"
$HealthLAWResourceId=Get-AutomationVariable -Name "HealthLAWResourceId"
#Set-AzAutomationVariable -Name LatestReportTime -Value (get-date).tostring("dd-MM-yyyy-hh:mm:ss") -Encrypted $false #-ResourceGroupName Guardrails-6eb08c2c -AutomationAccountName Guardrails-6eb08c2c
$ReportTime=(get-date).tostring("dd-MM-yyyy-hh:mm:ss")
#$=Get-AutomationVariable -Name "" 
#endregion Parameters 

# Connects to Azure using the Automation Account's managed identity
Connect-AzAccount -Identity
$SubID = (Get-AzContext).Subscription.Id
$tenantID = (Get-AzContext).Tenant.Id

[String] $WorkspaceKey = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $GuardrailWorkspaceIDKeyName -AsPlainText 
# Gets a token for the current sessions (Automation account's MI that can be used by the modules.)
[String] $GraphAccessToken = (Get-AzAccessToken -ResourceTypeName MSGraph).Token
# Grabs the secrets below from the Vault.
$BGA1=Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name BGA1 -AsPlainText 
$BGA2=Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name BGA2 -AsPlainText 

#region Guardrail module 1
"Check-ProcedureDocument 1"
Check-ProcedureDocument -StorageAccountName $StorageAccountName -ContainerName $ContainerName `
    -ResourceGroupName $ResourceGroupName -SubscriptionID $SubID `
    -DocumentName "BreakGlassAccountProcedure.txt" -ControlName $CtrName1 -ItemName "Break Glass account Procedure" `
    -LogType $LogType -WorkSpaceID  $WorkSpaceID -WorkspaceKey $WorkspaceKey

"Get-BreakGlassAccounts"
Get-BreakGlassAccounts -token $GraphAccessToken  -ControlName $CtrName1 -ItemName "Break Glass account Creation" `
    -FirstBreakGlassUPN $BGA1 -SecondBreakGlassUPN $BGA2 `
    -LogType $LogType -WorkSpaceID  $WorkSpaceID -WorkspaceKey $WorkspaceKey                
"Get-ADLicenseType"
Get-ADLicenseType -Token $GraphAccessToken -ControlName $CtrName1 -ItemName "AD License Type" `
    -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey 
"Get-UserAuthenticationMethod"
Get-UserAuthenticationMethod -token $GraphAccessToken -ControlName $CtrName1 -ItemName "MFA Enforcement" `
    -FirstBreakGlassEmail   $BGA1 `
    -SecondBreakGlassEmail  $BGA2 `
    -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey 
"Get-BreakGlassAccountLicense"
Get-BreakGlassAccountLicense -token $GraphAccessToken -ControlName $CtrName1 -ItemName "Microsoft 365 E5 Assignment" `
    -FirstBreakGlassUPN  $BGA1 `
    -SecondBreakGlassUPN  $BGA2 `
    -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey 
"Check-ProcedureDocument 2"
Check-ProcedureDocument -StorageAccountName $StorageAccountName -ContainerName $ContainerName `
    -ResourceGroupName $ResourceGroupName -SubscriptionID $SubID `
    -DocumentName "ConfirmBreakGlassAccountResponsibleIsNotTechnical.txt" -ControlName $CtrName1 -ItemName "Responsibility of break glass accounts must be with someone not-technical, director level or above" `
    -LogType $LogType -WorkSpaceID  $WorkSpaceID -WorkspaceKey $WorkspaceKey
"Get-BreakGlassOwnerinformation"
Get-BreakGlassOwnerinformation  -token $GraphAccessToken -ControlName $CtrName1 -ItemName "Break Glass Account Owners Contact information" `
    -FirstBreakGlassUPNOwner $BGA1 `
    -SecondBreakGlassUPNOwner $BGA2 `
    -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey 
#endregion Guardrail module 1
"Check-Policy"
Check-Policy -Token    $GraphAccessToken   -AADPrivRolesPolicyName "ABCPrivateRole" -AzureMFAPolicyName "ABCPrivateRole" 
"Check-ADDeletedUsers"
Check-ADDeletedUsers -Token $GraphAccessToken -ControlName $CtrName2 -ItemName "Remove deprecated accounts" `
    -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey
"Check-ExternalUsers"    
Check-ExternalUsers -Token $GraphAccessToken -ControlName $CtrName2 -ItemName "Remove External accounts" `
    -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey
"Check-MonitorAccountCreation"
Check-MonitorAccountCreation -Token $GraphAccessToken -DepartmentNumner $DepartmentNumber -ControlName $CtrName4 -ItemName "Monitor Account Creation" `
    -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey
"Verify-PBMMPolicy"
#Verify-PBMMPolicy -ControlName $CtrName5  -ItemName "PBMMPolicy Compliance" -PolicyID $PBMMPolicyID -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $workspaceKey$CtrName6 = "GUARDRAIL 6: PROTECTION OF DATA-AT-REST"
$ItemName6="PROTECTION OF DATA-AT-REST"
$ItemName7="PROTECTION OF DATA-IN-TRANSIT"
Verify-PBMMPolicy -ControlName $CtrName5 -ItemName "PBMMPolicy Compliance" `
-CtrName6 $CtrName6 -ItemName6 $ItemName6 `
-CtrName7 $CtrName7 -ItemName7 $ItemName7 `
-PolicyID $PBMMPolicyID -LogType $LogType `
-WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey
"Verify-AllowedLocationPolicy"
Verify-AllowedLocationPolicy -ControlName $CtrName5 -ItemName "AllowedLocationPolicy" -PolicyID $AllowedLocationPolicyId -LogType $LogType -WorkSpaceID $WorkSpaceID -workspaceKey $workspaceKey
#Guardrail module 8
"Get-SubnetComplianceInformation" 
Get-SubnetComplianceInformation -ControlName $CtrName8 -WorkSpaceID $WorkSpaceID -workspaceKey $WorkspaceKey
#Guardrail module 9
"Get-VnetComplianceInformation"
Get-VnetComplianceInformation -ControlName $CtrName9 -WorkSpaceID $WorkSpaceID -workspaceKey $WorkspaceKey 
#Guradrail modul 10
"Check-CBSSensors"
Check-CBSSensors -SubscriptionName $CBSSubscriptionName  -TenantID $TenantID -ControlName $CtrName10 `
                 -WorkSpaceID $WorkSpaceID -workspaceKey $WorkspaceKey -LogType $LogType
#Guardrail Module 11
"Check-LoggingAndMonitoring"
Check-LoggingAndMonitoring -SecurityLAWResourceId $SecurityLAWResourceId `
-HealthLAWResourceId $HealthLAWResourceId `
-LogType $LogType `
-WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey `
-ControlName $CtrName11 `
-ReportTime $ReportTime 
#Guardrail module 12 
"Check-PrivateMarketPlaceCreaion"
Check-PrivateMarketPlaceCreaion -ControlName $Ctrname12  -WorkSpaceID $WorkSpaceID -workspaceKey $WorkspaceKey -LogType $LogType
#Confirm-CloudConsoleAccess -token $token.access_token -PolicyName 

# SIG # Begin signature block
# MIInpwYJKoZIhvcNAQcCoIInmDCCJ5QCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDeMQ8vpZyUFwl7
# Rme9AlxAJ5LzYVulDyKFj/MITpScPKCCDYUwggYDMIID66ADAgECAhMzAAACU+OD
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGXgwghl0AgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAJT44Pelt7FbswAAAAA
# AlMwDQYJYIZIAWUDBAIBBQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJiF
# TCPDCGisQBEtosWdzVP9BtJjzrfBqdtlEfDNw+wFMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQu
# Y29tIDANBgkqhkiG9w0BAQEFAASCAQDGCcHrfKH4lwl5Yuxxo6qLRbCodb8xzBLc
# ysQPHCB/UY+pzYhfBOOXT13RHIhuyA/FFFVruQuJDJJPzhedK/ajaDhG17R1anSF
# /zyc9zBhXC5PvSnyS4dwDsBWQ9zu4ot0lz/doBuqKVb3Yt4EPKlVEHP9UfblCIE/
# oeqTIX7iMyi7N8odKPOlMe0SG72fraQn18nD12wBb35583gt99dP+diS5rlegrQy
# 61VpU5jCmFrtaqIoeIljHBVKSDCLFNWHAuRiiruI9Akti/hludRt/iyq9cZstpUm
# ytclhymTIZDaeviaMQCYzszY9tllWvi/sseAdh9d/JxCaZFBaX8GoYIXADCCFvwG
# CisGAQQBgjcDAwExghbsMIIW6AYJKoZIhvcNAQcCoIIW2TCCFtUCAQMxDzANBglg
# hkgBZQMEAgEFADCCAVEGCyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIO99CAnlCo+WHVTeohcX3VyuWyTA/i3A
# F+Zvfb8evB9OAgZiacBcjxoYEzIwMjIwNDI5MTc0NTQyLjUyNlowBIACAfSggdCk
# gc0wgcoxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNV
# BAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxl
# cyBUU1MgRVNOOjNCQkQtRTMzOC1FOUExMSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNloIIRVzCCBwwwggT0oAMCAQICEzMAAAGd/onl+Xu7TMAA
# AQAAAZ0wDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTAwHhcNMjExMjAyMTkwNTE5WhcNMjMwMjI4MTkwNTE5WjCByjELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFt
# ZXJpY2EgT3BlcmF0aW9uczEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046M0JCRC1F
# MzM4LUU5QTExJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Uw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDgEWh60BxJFuR+mlFuFCtG
# 3mR2XHNCfPMTXcp06YewAtS1bbGzK7hDC1JRMethcmiKM/ebdCcG6v6k4lQyLlSa
# HmHkIUC5pNEtlutzpsVN+jo+Nbdyu9w0BMh4KzfduLdxbda1VztKDSXjE3eEl5Of
# +5hY3pHoJX9Nh/5r4tc4Nvqt9tvVcYeIxpchZ81AK3+UzpA+hcR6HS67XA8+cQUB
# 1fGyRoVh1sCu0+ofdVDcWOG/tcSKtJch+eRAVDe7IRm84fPsPTFz2dIJRJA/PUaZ
# R+3xW4Fd1ZbLNa/wMbq3vaYtKogaSZiiCyUxU7mwoA32iyTcGHC7hH8MgZWVOEBu
# 7CfNvMyrsR8Quvu3m91Dqsc5gZHMxvgeAO9LLiaaU+klYmFWQvLXpilS1iDXb/82
# +TjwGtxEnc8x/EvLkk7Ukj4uKZ6J8ynlgPhPRqejcoKlHsKgxWmD3wzEXW1a09d1
# L2Io004w01i31QAMB/GLhgmmMIE5Z4VI2Jlh9sX2nkyh5QOnYOznECk4za9cIdMK
# P+sde2nhvvcSdrGXQ8fWO/+N1mjT0SIkX41XZjm+QMGR03ta63pfsj3g3E5a1r0o
# 9aHgcuphW0lwrbBA/TGMo5zC8Z5WI+Rwpr0MAiDZGy5h2+uMx/2+/F4ZiyKauKXq
# d7rIl1seAYQYxKQ4SemB0QIDAQABo4IBNjCCATIwHQYDVR0OBBYEFNbfEI3hKujM
# nF4Rgdvay4rZG1XkMB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8G
# A1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBs
# BggrBgEFBQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUy
# MDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgw
# DQYJKoZIhvcNAQELBQADggIBAIbHcpxLt2h0LNJ334iCNZYsta2Eant9JUeipweb
# FIwQMij7SIQ83iJ4Y4OL5YwlppwvF516AhcHevYMScY6NAXSAGhp5xYtkEckeV6g
# Nbcp3C4I3yotWvDd9KQCh7LdIhpiYCde0SF4N5JRZUHXIMczvNhe8+dEuiCnS1sW
# iGPUFzNJfsAcNs1aBkHItaSxM0AVHgZfgK8R2ihVktirxwYG0T9o1h0BkRJ3PfuJ
# F+nOjt1+eFYYgq+bOLQs/SdgY4DbUVfrtLdEg2TbS+siZw4dqzM+tLdye5XGyJlK
# BX7aIs4xf1Hh1ymMX24YJlm8vyX+W4x8yytPmziNHtshxf7lKd1Pm7t+7UUzi8QB
# hby0vYrfrnoW1Kws+z34uoc2+D2VFxrH39xq/8KbeeBpuL5++CipoZQsd5QO5Ni8
# 1nBlwi/71JsZDEomso/k4JioyvVAM2818CgnsNJnMZZSxM5kyeRdYh9IbjGdPddP
# Vcv0kPKrNalPtRO4ih0GVkL/a4BfEBtXDeEUIsM4A00QehD+ESV3I0UbW+b4NTmb
# RcjnVFk5t6nuK/FoFQc5N4XueYAOw2mMDhAoFE+2xtTHk2ewd9xGkbFDl2b6u/Fb
# hsUb5+XoP0PdJ3FTNP6G/7Vr4sIOxar4PpY674aQCiMSywwtIWOoqRS/OP/rSjF9
# E/xfMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG9w0B
# AQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAG
# A1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAw
# HhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1T
# dGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOTh
# pkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az/1xP
# x2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V29YZQ
# 3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oaezOt
# gFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkNyjYt
# cI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7KMtXA
# hjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRfNN0S
# idb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SUHDSC
# D/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoYWmEB
# c8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5C4lh
# 8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8Fdsa
# N8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TASBgkr
# BgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1Kc8Q
# /y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUwUzBR
# BgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3Nv
# ZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsG
# AQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAP
# BgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjE
# MFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kv
# Y3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEF
# BQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
# a2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3DQEB
# CwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEztTnX
# wnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJWAAOw
# Bb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G82jf
# ZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/AyeixmJ
# 5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI95ko+
# ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1jdEgs
# sU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZKCS6
# OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xBZj1p
# /cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuPNtq6
# TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvpe784
# cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAs4wggI3
# AgEBMIH4oYHQpIHNMIHKMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYD
# VQQLEx1UaGFsZXMgVFNTIEVTTjozQkJELUUzMzgtRTlBMTElMCMGA1UEAxMcTWlj
# cm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAt+lDSRX9
# 2KFyij71Jn20CoSyyuCggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMDANBgkqhkiG9w0BAQUFAAIFAOYVkEQwIhgPMjAyMjA0MjkwNjE0MjhaGA8y
# MDIyMDQzMDA2MTQyOFowdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA5hWQRAIBADAK
# AgEAAgISgwIB/zAHAgEAAgIRfDAKAgUA5hbhxAIBADA2BgorBgEEAYRZCgQCMSgw
# JjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3
# DQEBBQUAA4GBAC+DGa+Y3a7n1+YJtw4ZhD86O/auKoAVpXeSghgLWeGni7dmXaTd
# wboTbyIPUkFz5W2CTlc1tsBoDtl6c3R3KXlgSXFz+lA/BkavWkUR/zsRANB+nLLe
# UPNSpec/b/lUQPv9k6FJSBK/8hQOp8vtnCdxMLKqxHx8M7yz654zHefTMYIEDTCC
# BAkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEm
# MCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGd/onl
# +Xu7TMAAAQAAAZ0wDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsq
# hkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgcGy+FlMii1lHUcGM6MVdygZ6687j
# 2Vu9lgZUl8YkXvowgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCD1HmOt4Iqg
# T4A0n4JblX/fzFLyEu4OBDOb+mpMlYdFoTCBmDCBgKR+MHwxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFBDQSAyMDEwAhMzAAABnf6J5fl7u0zAAAEAAAGdMCIEIF9MXaWVkdni
# zZF4ObafKE2eB2KWE7Y3VvgYjM3Vt4/kMA0GCSqGSIb3DQEBCwUABIICAJ60ZTiB
# yXx3u24U1ElxQGiaqp4HQ8TcodxgScUtVG3edfpCiqZi0KDjp1AryVG0tQOP2U1K
# HWKmNlfTQUFOcrq3Q05oAsjwizrY7OBVOFVNroN0k31/uIiMDa89PdIhUARX1eQi
# 5TXafvIg9q8jysTgjNwqFuzizdRmIoPF1m1rkboK+n0NzFEOYIRJOQ438ed9xYMK
# 6ocGYqjtPnvXE3QvuGtZOOJ7jqYARtd2FVfwxYbd/Oh+oNB4uEgRJaSX6dPXi9eO
# 93IUOHc2fcK3NEKffkyDLXys7MjqD4Ek4XsS66nOXaAYgUaUhXqwvM8UwJG3s6HL
# SLByCfEqvPb39viq/nArvlkKkCbG28n7LPJb6SSxfDTBshOLYv1/5IHRp77n6tKL
# Pw0UwAL4SgApF9dEB8j4eXv1xZApWEl695aSQLPB6xg2S6bOFXgTT/8G9650T16g
# Z+EhvlQG1FzCf5Ub5Ten45vCAaoahqOZ+PW5Z0NVRo8qCym9WmxLBAmYaVwhU811
# tSJOYhlyAPeDvDaH0Ft1VtWZAytxXec09+ceqDSHjCUtL6C9aqKb+cStAA1vcpiR
# BEf6p/sbAcJyj2dmvSd7XfampbGOXxyVkAzUdRb64DPANKz6Mq+CH3u/gyVbW/Xj
# /+EoxHfDwJey94SIgK5b1dCB/jpspmBs/uHG
# SIG # End signature block
