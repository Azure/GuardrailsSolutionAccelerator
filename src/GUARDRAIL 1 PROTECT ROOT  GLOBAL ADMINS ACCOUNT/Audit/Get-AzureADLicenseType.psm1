<#
.SYNOPSIS
   
The module will look for a P2 equivalent licensing, Once the solution find any of the following "String Id", the check mark status will be changed from (❌) to (✔️).

Product name: AZURE ACTIVE DIRECTORY PREMIUM P2, String ID: AAD_PREMIUM_P2
Product name: ENTERPRISE MOBILITY + SECURITY E5, String ID: EMSPREMIUM
Product name: Microsoft 365 E5, String ID: SPE_E5
.DESCRIPTION
    The module will look for a P2 equivalent licensing, Once the solution find any of the following "String Id", the check mark status will be changed from (❌) to (✔️).

Product name: AZURE ACTIVE DIRECTORY PREMIUM P2, String ID: AAD_PREMIUM_P2
Product name: ENTERPRISE MOBILITY + SECURITY E5, String ID: EMSPREMIUM
Product name: Microsoft 365 E5, String ID: SPE_E5
.PARAMETER Name
        token : auth token 
        ControlName :-  GUARDRAIL 1 PROTECT ROOT  GLOBAL ADMINS ACCOUNT
        ItemName, 
        WorkSpaceID : Workspace ID to ingest the logs 
        WorkSpaceKey: Workspace Key for the Workdspace 
        LogType: GuardrailsCompliance, it will show in log Analytics search as GuardrailsCompliance_CL
#>

function Get-ADLicenseType {
    
 param (
     [string] $token, 
     [string] $ControlName,
     [string] $WorkSpaceID, 
     [string] $workspaceKey, 
     [string] $LogType,
     [string] $ItemName
)
    $ADLicenseType  = "N/A"
    $IsCompliant = $false
    $apiUrl = "https://graph.microsoft.com/v1.0/subscribedSkus"
    $Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $apiUrl -Method Get
    $subscribedSkus = $Data.Value
    $servicePlans=  $subscribedSkus.servicePlans
    #https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference
    foreach ($servicePlan in $servicePlans) {
        if(($servicePlan.servicePlanName -eq "AAD_PREMIUM_P2") -or`
           ($servicePlan.servicePlanName -eq "EMSPREMIUM")-or`
           ($servicePlan.servicePlanName -eq "SPE_E5")){
            $IsCompliant = $true
            $ADLicenseType  = $servicePlan.servicePlanName
        }
    }

    $PsObject = [PSCustomObject]@{
        ComplianceStatus= $IsCompliant
        ControlName = $ControlName
        ADLicenseType = $ADLicenseType
        ItemName= $ItemName
     }
     $JsonObject = convertTo-Json -inputObject $PsObject 

     Send-OMSAPIIngestionFile  -customerId $WorkSpaceID `
                               -sharedkey $workspaceKey `
                               -body $JsonObject `
                               -logType $LogType `
                               -TimeStampField Get-Date 

}

# SIG # Begin signature block
# MIInsAYJKoZIhvcNAQcCoIInoTCCJ50CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAQcRSYdetmqLWP
# CJPhTfx+PQZJzWFohtvcAPPN9Q+8j6CCDYUwggYDMIID66ADAgECAhMzAAACU+OD
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGYEwghl9AgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAJT44Pelt7FbswAAAAA
# AlMwDQYJYIZIAWUDBAIBBQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINK8
# q1H4QnlIcjumICsT18bzo2iaiS16QJLNRwxufSrAMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQu
# Y29tIDANBgkqhkiG9w0BAQEFAASCAQC4A1+9NzGzEOBzSVZf5BMBwpFK8qX4UXaV
# H+d8L77GC823EbxxB4aUI/QOIp3o67k7zAdYYGfvLNrw/syesQPME05KDIO6EqdZ
# FLr4Ye7PKLOcUbZNzYp1MLNsxQqV+HNYyyDKJXGdIPlpn3+V21OIWotvSo3cdGmI
# bIfnIjelmxyojtSGok3gexw82OwRVcuoRtemxRq7v6Ocnf/qpJTh5VWsD/QYdXAw
# nM/qayu+zXzZGYSDFyO5kCd2Dwy23209GKKdG8R/LxR501AQyqR5NSKMyUMJbZ6f
# NEC1PWzsPeQgyPOJDisFvHuBJzXZMFwbib3CPtCtLWXDrM0euPGSoYIXCTCCFwUG
# CisGAQQBgjcDAwExghb1MIIW8QYJKoZIhvcNAQcCoIIW4jCCFt4CAQMxDzANBglg
# hkgBZQMEAgEFADCCAVUGCyqGSIb3DQEJEAEEoIIBRASCAUAwggE8AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIHo0NGE8UiS+aVAKlmnuzHYHaZ8tDf9I
# M4PTthbLVZPCAgZia0fpYicYEzIwMjIwNTEzMDUyNTUwLjA5M1owBIACAfSggdSk
# gdEwgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNV
# BAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1U
# aGFsZXMgVFNTIEVTTjpGN0E2LUUyNTEtMTUwQTElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZaCCEVwwggcQMIIE+KADAgECAhMzAAABpQDeCMRA
# B3FOAAEAAAGlMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwMB4XDTIyMDMwMjE4NTExOVoXDTIzMDUxMTE4NTExOVowgc4xCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29m
# dCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVT
# TjpGN0E2LUUyNTEtMTUwQTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# U2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALqxhuggaki8
# wuoOMMd7rsEQnmAhtV8iU1Y0itsHq30TdCXJDmvZjaZ8yvOHYFVhTyD1b5JGJtwZ
# jWz1fglCqsx5qBxP1Wx1CZnsQ1tiRsRWQc12VkETmkY8x46MgHsGyAmhPPpsgRnk
# lGai7HqQFB31x/Qjkx7rbAlr6PblB4tOmaR1nKxl4VIgstDwfneKaoEEw4iN/xTd
# ztZjwyGiY5hNp6beetkcizgJFO3/yRHYh0gtk+bREhrmIgbarrrgbz7MsnA7tlKv
# GcO9iHc6+2symrAVy3CzQ4IMNPFcTTx8wTZ+kpv6lFs1eG8xlfsu2NDWKshrMlKH
# 2JpYzWAW1fCOD5irXsE4LOvixZQvbneQE6+iGfIQwabj+fRdouAU2AiE+iaNsIDa
# pdKab8WLxz6VPRbEL+M6MFkcsoiuKHHoshCp7JhmZ9iM0yrEx2XebOha/XQ342Ks
# RGs2h02gpX6wByyT8eD3MJVIxSRm4MLIilvWcpd9N3rooawbLU6gdk7goKWS69+w
# 2jtouXCEYt6IPfZq8ldi0L/CwYbtv7mbHmIZ9Oc0JEJc6b9gcVDfoPiemMKcz15B
# Lepyx7npQ2MiDKIscOqKhXuZI+PZerNOHhi/vsy2/Fj9lB6kJrMYSfV0F2frvBSB
# XMB7xjv8pgqX5QXUe8nTxb4UfJ0cDAvBAgMBAAGjggE2MIIBMjAdBgNVHQ4EFgQU
# X6aPAwCXrq6tcO773FkXS2ipGt8wHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacb
# UzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAo
# MSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1w
# JTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggr
# BgEFBQcDCDANBgkqhkiG9w0BAQsFAAOCAgEAlpsLF+UwMKKER2p0WJno4G6GGGnf
# g3qjDdaHc5uvXYtG6KmHrqAf/YqHkmNotSr6ZEEnlGCJYR7W3uJ+5bpvj03wFqGe
# fvQsKIR2+q6TrzozvP4NsodWTT5SVp/C6TEDGuLC9mOQKA4tyL40HTW7txb0cAdf
# gnyHFoI/BsZo/FaXezQ8hO4xUjhDpyNNeJ6WYvX5NC+Hv9nmTyzjqyEg/L2cXAOm
# xEWvfPAQ1lfxvrtUwG75jGeUaewkhwtzanCnP3l6YjwJFKB6n7/TXtrfik1xY1kg
# ev1JwQ5aUdPxwSdDmGE4XTN2s6pPOi8IO199Of6AEvh41eDxRz+11VUcpuGn7tJU
# eSTUSHsvzQ8ECOj5w77Mv55/F8hWu07egnG8SrWj5+TFxNPCpx/AFNvzz+odTRTZ
# d4LWuomcMHUmLFiUGOAdetF6SofHG5EcFn0DTD1apBZzCP8xsGQcZgwVqo7ov23/
# uIJlMCLAyTYZV9ITCP09ciUJbKBVCQNrGEnQ/XLFO9mysyyDRrvHhU5uGPdXz4Jt
# 2/ZN7JQYRuVNSuCpNwoK0Jr1s6ciDvHEeLyiczxoIe9GH3SyfbHx6v/phI+iE3DW
# o1TCK75EL6pt6k5i36/kn2uSVXdTH44ZVkh3/ihV3vEws78uGlvsiMcrKBgpo3Hd
# cjDHiHoWsUf4GIwwggdxMIIFWaADAgECAhMzAAAAFcXna54Cm0mZAAAAAAAVMA0G
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
# oYICzzCCAjgCAQEwgfyhgdSkgdEwgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0
# byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpGN0E2LUUyNTEtMTUwQTEl
# MCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsO
# AwIaAxUAs8lw20WzmxDKiN1Lhh7mZWXutKiggYMwgYCkfjB8MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIFAOYoOsowIhgPMjAyMjA1
# MTMwNjAyNTBaGA8yMDIyMDUxNDA2MDI1MFowdDA6BgorBgEEAYRZCgQBMSwwKjAK
# AgUA5ig6ygIBADAHAgEAAgIHoTAHAgEAAgIReDAKAgUA5imMSgIBADA2BgorBgEE
# AYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYag
# MA0GCSqGSIb3DQEBBQUAA4GBAH0ETN1K4yDbsX5OFrmP5wvaaUORapjErKn7ISEw
# r/zcpjki4LNgabHTJZxhcchp1TjK1Yb7NA9uDGRb3ZzOh4lt0CYOTZ43/rqHR4tq
# 56IqkZ8S+2EcGDupMpvK+UNREO5RZoz0xk7p68AkIbi0Mcz6LeUrX+8fn5+NfeTv
# iTLoMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAC
# EzMAAAGlAN4IxEAHcU4AAQAAAaUwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3
# DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQg4taF6n/Un+PlIkn1
# U3CSUiV0wN0TyjWTNgVZPRMT5u8wgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9
# BCC4CjhxfmYEsaCt2AU83Khh+6JHlyk3B70vfMHMlBLcXDCBmDCBgKR+MHwxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAABpQDeCMRAB3FOAAEAAAGlMCIE
# IJlG18959JM5IsZ4qn4XWHRqcc5kNg8q0zVlUFuNEqCxMA0GCSqGSIb3DQEBCwUA
# BIICAFk1OZTcXKuUWpLC6JFijWAG6q/rjDNk8lB1aR58ymHHsNHl4D+WL8tXfMAh
# tbpNiDbrRdUBxh5bBIDuVdJn5IpEphdDqN6zYoleANIvuekL9IE9mwLuf7izTRpe
# Ot4jZ8V+8k4FSpGuuUtY+/90FpSVwtUXP3M+01ZZ/U0nozc4t53VctyGOnReNBJb
# xltsI3W/oMUBTzOBiE2Q+oVEhcIIFcicsA65pUVvpXi4gTSRSR7OCIOQqTyEDrnG
# FbjhxJMaIQYq2A9bFKH7jH7UdCDVBJU0UtyScKpR8Pyp3fIR1CiR+0+R7z6Oa/eu
# 4u87YLctVbft4tZpmDvRTxAuJcOmFjMRGBUjobR8ljDc2R6qKppN4f/oSWogK7cr
# FeKmTD91cWyk1P72f46HBFy9QYN9dPhIbA6EiLm4OhRS8aT9ExhANwjbC2dkmdQG
# 6kdPtvpeqj0lScW66BqnYY5bPyeOQikV1bcIMc9pJDCwmGT3S+q353YqNxcwASc4
# gGXXguAADE9ycwTNmnUVzWTgaz/fh/dBhpaYhCbgYAVrH2Zfs5sxDgucpGlZnZXa
# mR2KvTh6Bd+qf/OSp5FyTyOhYw9SP2UoohiLfvQ9mjMhppPDXEGUOsBGRET3BtZo
# iLNWuseW9B3BsWg3GHjOmFsyiR0MHdtmOmJsw6EpOJ85svd6
# SIG # End signature block
