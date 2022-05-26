#Future Params:
#Security
function get-apiLinkedServicesData {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $subscriptionId,
        [Parameter(Mandatory=$true)]
        [string]
        $resourceGroup,
        [Parameter(Mandatory=$true)]
        [string]
        $LAWName
    )
    $token=(Get-AzAccessToken).Token
    $apiUrl="https://management.azure.com/subscriptions/$subscriptionId/resourcegroups/$resourceGroup/providers/Microsoft.OperationalInsights/workspaces/$LAWName/linkedServices?api-version=2020-08-01"
    $Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $apiUrl -Method Get
    return $Data
}
function get-tenantDiagnosticsSettings {
    #AadGraph, AnalysisServices, Arm, Attestation, Batch, DataLake, KeyVault, MSGraph, OperationalInsights, ResourceManager, Storage, Synapse
    $token=(Get-AzAccessToken -ResourceTypeName Arm).Token

    #$apiUrl="https://graph.microsoft.com/beta/auditLogs/directoryAudits"
    $apiUrl = "https://management.azure.com/providers/microsoft.aadiam/diagnosticSettings?api-version=2017-04-01-preview"
    $Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $apiUrl -Method Get
    return $data.value.properties
}
function Check-LoggingAndMonitoring {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $SecurityLAWResourceId,
        [Parameter(Mandatory=$true)]
        [string]
        $HealthLAWResourceId,
        [Parameter(Mandatory=$true)]
        [string]
        $ControlName,
        [Parameter(Mandatory=$true)]
        [string]
        $WorkSpaceID,
        [Parameter(Mandatory=$true)]
        [string]
        $workspaceKey,
        [Parameter(Mandatory=$true)]
        [string]
        $LogType="GuardrailsCompliance",
        [Parameter(Mandatory=$true)]
        [string]
        $ReportTime
    )
    $ItemName1="SecurityMonitoring"
    $ItemName2="HealthMonitoring"
    $ItemName3="DefenderMonitoring"
    #Code
    $Subscription=$SecurityLAWResourceId.Split("/")[2]
    $LAWRG=$SecurityLAWResourceId.Split("/")[4]
    $LAWName=$SecurityLAWResourceId.Split("/")[8]
    $HealthLAWRG=$SecurityLAWResourceId.Split("/")[4]
    $HealthLAWName=$SecurityLAWResourceId.Split("/")[8]
    
    $IsCompliant=$true
    #LAW exists and has the proper retention
    $Comment1="The specified Log Analytics Workspace for Security monitoring has not been found."
    $Comment2="Retention not set to 730 days."
    $Comment3="WorkSpace not configured to ingest activity Logs."
    $Comment4="Required solutions not present in the Log Analytics Workspace."
    $Comment5="No linked automation account has been found."
    $Comment6="Tenant Diagnostics settings are not pointing to the provided log analysitcs workspace."
    $Comment7="Workspace set in tenant config but not all required log types are enabled (Audit and signin)."
    $Comment8="The specified Log Analytics Workspace for Health monitoring has not been found."
    $Comment9="Retention not set to at least90 days."
    $Comment10="Required solutions not present in the Health Log Analytics Workspace."
    $Comment11=""
    $Comment12=""
    $Comment13=""
    Select-AzSubscription -Subscription $Subscription
    $LAW=Get-AzOperationalInsightsWorkspace -Name $LAWName -ResourceGroupName $LAWRG
    if ($LAW -eq $null)
    {
        $IsCompliant=$false
        $Comments=$Comment1 # "The specified Log Analytics Workspace has not been found."
    }
    else {
        # Test linked automation account
        $LinkedServices=get-apiLinkedServicesData -subscriptionId $Subscription `
            -resourceGroup $LAWRG `
            -LAWName $LAWName
        if (($LinkedServices.value.properties.resourceId | Where-Object {$_ -match "automationAccounts"}).count -lt 1)
        {
            $IsCompliant=$false
            $Comments+=$Comment5 #"No linked automation account has been found."
        }
        #Test Retention Days
        $Retention=$LAW.retentionInDays
        if ($Retention -ne 730)
        {
            $IsCompliant=$false
            $Comments+=$Comment2 # "Retention not set to 730 days."
        }
        #Verify presense of the Activity Logs as a source
        $ActivityLogDS=Get-AzOperationalInsightsDataSource -Workspace $LAW -Kind AzureActivityLog
        If ($ActivityLogDS -eq $null)
        {
            $IsCompliant=$false
            $Comments+=$Comment3 # "WorkSpace not configured to ingest activity Logs."
        }
        # Tests for required Solutions
        $enabledSolutions=(Get-AzOperationalInsightsIntelligencePack -ResourceGroupName $LAW.ResourceGroupName -WorkspaceName $LAW.Name| Where-Object {$_.Enabled -eq "True"}).Name
        if ($enabledSolutions -notcontains "Updates" -or $enabledSolutions -notcontains "AntiMalware")
        {
            $IsCompliant=$false
            $Comments+=$Comment4 # "Required solutions not present in the Log Analytics Workspace."
        }
        # Tenant Diagnostics configuration. Needs Graph API...
        $tenantWS=get-tenantDiagnosticsSettings
        if ($SecurityLAWResourceId -notin $tenantWS.workspaceId)
        {
            $IsCompliant=$false
            $Comments+=$Comment6 # "Tenant Diagnostics settings are not pointing to the provided log analysitcs workspace."
        }
        else {
            #Workspace is there but need to check if logs are enabled.
            $enabledLogs=(($p| ? {$_.workspaceId -eq $wsid}).logs | ? {$_.enabled -eq $true}).category
            if ("AuditLogs" -notin $enabledLogs -or "SignInLogs" -notin $enabledLogs)
            {
                $IsCompliant=$false
                $Comments+=$Comment7 # "Workspace set in tenant config but not all required log types are enabled (Audit and signin)."
            }
        }
        #Blueprint redirection
        # Sentinel, not sure how to detect this.
        if ($IsCompliant)
        {
            $Comments="The Logs and Monitoring is compliant for Security."
        }
        $object = [PSCustomObject]@{ 
            ComplianceStatus = $IsCompliant
            Comments = $Comments
            ItemName = $ItemName1
            ControlName = $ControlName
            ReportTime = $ReportTime
        }
        $JSON= ConvertTo-Json -inputObject $object

        Send-OMSAPIIngestionFile  -customerId $WorkSpaceID `
        -sharedkey $workspaceKey `
        -body $JSON `
        -logType $LogType `
        -TimeStampField Get-Date 
        $IsCompliant=$true
    }
    #
    #Health
    #
    $IsCompliant=$true
    $Comments=""
    $HSubscription=$SecurityLAWResourceId.Split("/")[2]
    if ($Subscription -ne $HSubscription)
    {
        Select-AzSubscription -Subscription $HSubscription
    }
    $LAW=Get-AzOperationalInsightsWorkspace -Name $HealthLAWName -ResourceGroupName $HealthLAWRG
    if ($LAW -eq $null)
    {
        $IsCompliant=$false
        $Comments+=$Comment8 # "The specified Log Analytics Workspace for Health monitoring has not been found."
    }
    else {
        $LinkedServices=get-apiLinkedServicesData -subscriptionId $HSubscription `
        -resourceGroup $LAW.ResourceGroupName `
        -LAWName $LAW.Name
        if (($LinkedServices.value.properties.resourceId | Where-Object {$_ -match "automationAccounts"}).count -lt 1)
        {
            $IsCompliant=$false
            $Comments+=$Comment5 #"No linked automation account has been found."
        }
        $Retention=$LAW.retentionInDays
        if ($Retention -lt 90)
        {
            $IsCompliant=$false
            $Comments+=$Comment9 # "Retention not set to at least90 days."
        }
        #Checks required solutions
        $enabledSolutions=(Get-AzOperationalInsightsIntelligencePack -ResourceGroupName $LAW.ResourceGroupName -WorkspaceName $LAW.Name| Where-Object {$_.Enabled -eq "True"}).Name
        if ($enabledSolutions -notcontains "AgentHealthAssessment")
        {
            $IsCompliant=$false
            $Comments+=$Comment10 # "Required solutions not present in the Health Log Analytics Workspace."
        }
        #Tenant...No information on how to detect it.
        #Blueprint
    }
    if ($IsCompliant)
    {
        $Comments="The environment is compliant."
    }
    $object = [PSCustomObject]@{ 
        ComplianceStatus = $IsCompliant
        Comments = $Comments
        ItemName = $ItemName2
        ControlName = $ControlName
        ReportTime = $ReportTime        
    }
    $JSON= ConvertTo-Json -inputObject $object

    Send-OMSAPIIngestionFile  -customerId $WorkSpaceID `
    -sharedkey $workspaceKey `
    -body $JSON `
    -logType $LogType `
    -TimeStampField Get-Date 
    #
    # Defender for cloud detection.
    #
    $IsCompliant=$true
    $Comments=""
    $sublist=Get-AzSubscription | Where-Object {$_.State -eq 'Enabled'}
    # This will look for specific Defender for Cloud, on a per subscription basis.
    foreach ($sub in $sublist)
    {
        Select-AzSubscription -SubscriptionObject $sub
        $ContactInfo=Get-AzSecurityContact
        if ($ContactInfo.Email -ne $null -or $ContactInfo.Phone -eq $null)
        {
            $IsCompliant=$false
            $Comments="Subscription $($sub.Name) is missing Contact Information."
        }
        if ((Get-AzSecurityPricing | Select-Object PricingTier | Where-Object {$_.PricingTier -eq 'Free'}).Count -gt 0)
        {
            $IsCompliant=$false
            $Comments+="Not all princing plan options are set to Standard for subscription $($sub.Name)"
        }
    }
    if ($IsCompliant)
    {
        $Comments="The Logs and Monitoring is compliant for Security."
    }
    $object = [PSCustomObject]@{ 
        ComplianceStatus = $IsCompliant
        Comments = $Comments
        ItemName = $ItemName3
        ControlName = $ControlName
        ReportTime = $ReportTime
    }
    $JSON= ConvertTo-Json -inputObject $object

    Send-OMSAPIIngestionFile  -customerId $WorkSpaceID `
    -sharedkey $workspaceKey `
    -body $JSON `
    -logType $LogType `
    -TimeStampField Get-Date 
    $IsCompliant=$true
}
# SIG # Begin signature block
# MIInsgYJKoZIhvcNAQcCoIInozCCJ58CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB/ProoKptT7Gyz
# sveakorxsEGTAK+wtR58K9/RTZ1hVKCCDYUwggYDMIID66ADAgECAhMzAAACU+OD
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGYMwghl/AgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAJT44Pelt7FbswAAAAA
# AlMwDQYJYIZIAWUDBAIBBQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIhi
# +zTRWfeSnnMytHNBFgo70uWMm6c+MIEA5VYJgDSyMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQu
# Y29tIDANBgkqhkiG9w0BAQEFAASCAQCvDSTMeRppKSy3ZKYDWYFYjj/ElkkOreLF
# jNRqRy9bruCXKTyNJL0lUpVndtQQi3K/kJCzvJjGaEekkBS8uxBPxUsucJqpuZcD
# bNu4MH9ivsL//tvv//1frmnYwNjLXfFmCIMsjwJZOVaVsOc0NviyDrwWfF+tfe5o
# PPW9NzIcipx74VKOAo8nCXpsJxu7wGxWwsfDykElJIH37cOe1lsirJIWdfTysR/U
# /4tBqBYXH3NrNit0Ko7rAbUbfhVSyln6cIJVRPMv8+j+T1/4tuGCyewc3LCOfe6e
# L5RZ7Z/ya0zEFXuZQH11K7m+gT9QIXMmMKKqyRHi8XDURa0Bzq2voYIXCzCCFwcG
# CisGAQQBgjcDAwExghb3MIIW8wYJKoZIhvcNAQcCoIIW5DCCFuACAQMxDzANBglg
# hkgBZQMEAgEFADCCAVQGCyqGSIb3DQEJEAEEoIIBQwSCAT8wggE7AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIPysHpdlWCRoPXwJmZvp9bw0X85ymsJl
# 7KXGSz5tC3ksAgZiazXeqWMYEjIwMjIwNTEzMDUyNjUzLjExWjAEgAIB9KCB1KSB
# 0TCBzjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEpMCcGA1UE
# CxMgTWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRvIFJpY28xJjAkBgNVBAsTHVRo
# YWxlcyBUU1MgRVNOOjc4ODAtRTM5MC04MDE0MSUwIwYDVQQDExxNaWNyb3NvZnQg
# VGltZS1TdGFtcCBTZXJ2aWNloIIRXzCCBxAwggT4oAMCAQICEzMAAAGoVfBhqcww
# GFwAAQAAAagwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENB
# IDIwMTAwHhcNMjIwMzAyMTg1MTIzWhcNMjMwNTExMTg1MTIzWjCBzjELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEpMCcGA1UECxMgTWljcm9zb2Z0
# IE9wZXJhdGlvbnMgUHVlcnRvIFJpY28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNO
# Ojc4ODAtRTM5MC04MDE0MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAo9ptysAuJdfy
# mPJelww3z0pO9yaUCIPDilT4d6NmGJtR6j8dTL4/1XFaEJfuiB54o8nrvv4t5V09
# 0bmFO8YOBK6jfD4BybNxdnZAIZSBRF4tQpuauvTpsHTGG+1nCh6WHG0+SMkWxtMa
# 1K35XsThUKM91ipBn+I3QCtdeaBsR9XILBL6Ha6igGEzlRxs+iC2vlWmB3NtQzj+
# ta6mYVWM8HVqyff7C/toEIryP1BQmuhjjLWmZlJ/RK4YxZjtybZy+tt2bteV2WOp
# F0db4JAAHgSqI6qC6Z9H5pKmjlPvkobT6ewGSOUZKxTUGLXmnis/zylmdKinvcZ6
# b0ZY7YZEvA/XlgScqxzPGEZj5nw0RrRDAwyJWWSx09Tsnmor2DEBCM4nOohInOEj
# BBa0QuqAmgfCSpPF6beCtjsHsM7NBOdCkpagvQdZH0qoi9oLuL1eU+/657z2P17t
# +YHieHWG6XMQnNfpExT1MckyVs7o6s/c00QolbyOKkKfLwfV+69K4V+4Hu374or2
# DZzY0q7kTNKzWco2q2Xgo7dTPJcta9NEM7gPk9VA51rS2qNL8BahSvEoLlk+WQsT
# 5g+xLkb4T9UKAJqCE/IFmwc0rvAeVJ//bq6EucqnpdEAiuiIRiX/nJbSZKGO+cBE
# +vQYiVKbQqupLAKNHlyRZPWwpoRvzDcCAwEAAaOCATYwggEyMB0GA1UdDgQWBBQ2
# x9vj4vhS62U2H8zGMaSPSQsi1TAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtT
# NRnpcjBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20v
# cGtpb3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgx
# KS5jcmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAl
# MjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsG
# AQUFBwMIMA0GCSqGSIb3DQEBCwUAA4ICAQBxO4JLZGqqZ/aY+vo5TJ2GZTH6bq+k
# Q+zNaKglduexFufLracX1hdMq5I1YfVAV/Jz/Y3dhMSniETxi2FgqAMz8dSFRERf
# dZPAax5i64N5LFZElYKisAcXWTBDMgqCtRzcb65XACYb8QjUQtETEDh+3HQSGt/n
# 1ombs6eCfSVNJKIpR64YD4zLqgKL9XwRPHP55uW9AA1qW0mAZ+mm5ZdhPiOKxAoR
# O+gmMG/nH4EDSgQW7uAZp4wORmOc7m91/od4qd4guz1m/AhaSBhCLZl6jNvGCUbl
# jATGiLF6TGtFMNnAyiQhjFeZxyxxDTFeaH4je+juFX1kwpNr09rPmd7hxzw53DVP
# 7rbiYHRZpb0cATWGiMHoJt+6d21X+PDGZ0qHXmmUlec3XIzs4v3bgeoCImKwdqek
# 4QnhSb1veEVRcTa4Qkv1pi4iCSxVgirU/b2tHhfuXPe4QkfoI6SgTr5Rxq43olgW
# CE30jwlEFYCEdfgZAeWeCx1+1YsuINkzKeWBEJnORgjbg31zH4PfrtjByWo1joJm
# 4CDPDLXa5FgVBqxgdgrWGnPJO24j8DYHxwb4czpfWN/Z324BHAfr6EuQ+23f/k0G
# Utek6XmJnJGUGLuINeRY1reO4Z8sAnchIPI2HvK74fjJBjJGz8xWsKRZQmz0SK8s
# qw0nYH8iM2tK1jCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJ
# KoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0
# eSAyMDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIyNVowfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXIyjVX9gF/bErg4r25
# PhdgM/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjoYH1qUoNEt6aORmsH
# FPPFdvWGUNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1yaa8dq6z2Nr41JmTa
# mDu6GnszrYBbfowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v3byNpOORj7I5LFGc
# 6XBpDco2LXCOMcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pGve2krnopN6zL64NF
# 50ZuyjLVwIYwXE8s4mKyzbnijYjklqwBSru+cakXW2dg3viSkR4dPf0gz3N9QZpG
# dc3EXzTdEonW/aUgfX782Z5F37ZyL9t9X4C626p+Nuw2TPYrbqgSUei/BQOj0XOm
# TTd0lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlMjgK8QmguEOqEUUbi
# 0b1qGFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJNmSLW6CmgyFdXzB0kZSU
# 2LlQ+QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AFemzFER1y7435UsSF
# F5PAPBXbGjfHCBUYP3irRbb1Hode2o+eFnJpxq57t7c+auIurQIDAQABo4IB3TCC
# AdkwEgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIEFgQUKqdS/mTEmr6C
# kTxGNSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMFwGA1Ud
# IARVMFMwUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTATBgNVHSUE
# DDAKBggrBgEFBQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8E
# BAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo0T2U
# kFvXzpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5j
# b20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcmww
# WgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDANBgkq
# hkiG9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL/Klv6lwUtj5OR2R4sQaT
# lz0xM7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZnOlNN3Zi6th542DYu
# nKmCVgADsAW+iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1bSNU5HhTdSRXud2f
# 8449xvNo32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4rPf5KYnDvBewVIVC
# s/wMnosZiefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU6ZGyqVvfSaN0DLzs
# kYDSPeZKPmY7T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDFNLB62FD+CljdQDzH
# VG2dY3RILLFORy3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/HltEAY5aGZFrDZ+k
# KNxnGSgkujhLmm77IVRrakURR6nxt67I6IleT53S0Ex2tVdUCbFpAUR+fKFhbHP+
# CrvsQWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKiexcdFYmNcP7ntdAo
# GokLjzbaukz5m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9JZTmdHRbatGePu1+oDEz
# fbzL6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6FwZvKh
# ggLSMIICOwIBATCB/KGB1KSB0TCBzjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEpMCcGA1UECxMgTWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRv
# IFJpY28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjc4ODAtRTM5MC04MDE0MSUw
# IwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4D
# AhoDFQBsuvzEn0EHisvhiDnxfUtnmJB3LKCBgzCBgKR+MHwxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBBQUAAgUA5igoyTAiGA8yMDIyMDUx
# MzA0NDYwMVoYDzIwMjIwNTE0MDQ0NjAxWjB3MD0GCisGAQQBhFkKBAExLzAtMAoC
# BQDmKCjJAgEAMAoCAQACAhtxAgH/MAcCAQACAhSyMAoCBQDmKXpJAgEAMDYGCisG
# AQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMB
# hqAwDQYJKoZIhvcNAQEFBQADgYEAzDXUCQzWheR67BilBwepHSlBgWzlOJQmNdCy
# DAMGMgL+tcXS6ZEdi7jnSGi/ZIIa9jxj/IOEBjPqrL63TJOdaeZvZT+a5wdJbPAU
# PVm0+4C/nxBjf43oqhy67zt2NTtoRQP+iiwBaCq/xO50rVL0Okv6Sw53snPQRcXr
# oyVVApoxggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MAITMwAAAahV8GGpzDAYXAABAAABqDANBglghkgBZQMEAgEFAKCCAUowGgYJKoZI
# hvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCBa6oDK2Ajo+Yhm
# N8gY1rGRT19DuW9BlbWzCL9rHDZqWzCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQw
# gb0EIHT+yx0AywfCc3CF8UFc+UWdG9aEepJf1gtTEEOXXGWmMIGYMIGApH4wfDEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWlj
# cm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGoVfBhqcwwGFwAAQAAAagw
# IgQgPNOij99Zmv+Sut/Rx3MkoYBQUAOIEnZrarSuzzMggCswDQYJKoZIhvcNAQEL
# BQAEggIAWljnlb24BOUA0l/gNzOmN15NTBl58k806s9FPr1jSvqKNKIvl8SmTpnY
# OZJTgiUbo7CtTGVDgoLepqb1EIpfoEVDrL/D0N1ghdMpIH6/8Sa6sJ55LdwwBBnY
# n/8EgnHuNnlH+d7AckRXWy2PQz7j+382MTVunqU3vrFVqBsRM+C5sIxP2IWGDFEb
# m40MLler/H3DPnk40KjNgmkNMQMB8dAD4njDMga4ohE10XiZoS8VDm34f//JyHU0
# bPcL6gxIwZVYgDaYt96gyiM/bD6OQssgVgXQH03Osorr/sQoDywZgQGtMRNBBUhh
# Ak95+vuK3SdelCGhiZBjkKMXddO/VYGftWM0inggTgJhpWKz6vwtqHMepvOH1yOy
# Q80mpqG1gcok+hWMFYaP4C3faEc+dcCX9YDy4VYXYBS+gosAaOlgNclAkBl+aLfx
# dF6yMZRPXqo40XLLwf6qwHqZrQOA5duab2qxxRuOtoNqsrFrcJQRELTfvll9ayxp
# uwjRI4BFu1ZdWfsE3IiPhVf73NhUYxxT2GiuadWcavQrfOQpkzHtANNgCM9+0Kco
# Xcwt60ILCK9JnmAe5oX1UBTAWCkw76ZYRrlhHk8Z0kT/1A4R8m7YLd5Sh4+7tWYH
# OAwhA48X8xl1gmLX64D/uSjCmGwsiM7JvDwv/iIGxahlrO7Y/TI=
# SIG # End signature block
