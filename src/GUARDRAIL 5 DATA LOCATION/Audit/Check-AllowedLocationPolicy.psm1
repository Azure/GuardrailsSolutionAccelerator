function Verify-AllowedLocationPolicy {
    param (
        [switch] $DebugData,
        [string] $ControlName,
        [string] $ItemName,
        [string] $PolicyID, 
        [string] $WorkSpaceID,
        [string] $workspaceKey,
        [string] $LogType,
        [hashtable] $msgTable,
        [Parameter(Mandatory=$true)]
        [string]
        $ReportTime,
        [Parameter(Mandatory=$true)]
        [string]
        $CBSSubscriptionName
    )

    #$PolicyID = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"

    [System.Object] $RootMG = $null
    [string] $PolicyID = $policyID
    [PSCustomObject] $MGList = New-Object System.Collections.ArrayList
    [PSCustomObject] $MGItems = New-Object System.Collections.ArrayList
    [PSCustomObject] $SubscriptionList = New-Object System.Collections.ArrayList
    [PSCustomObject] $CompliantList = New-Object System.Collections.ArrayList
    [PSCustomObject] $NonCompliantList = New-Object System.Collections.ArrayList

    $AllowedLocations = @("canada" , "canadaeast" , "canadacentral")

    try {
        $managementGroups = Get-AzManagementGroup -ErrorAction Stop
    }
    catch {
        Add-LogEntry 'Error' "Failed to execute the 'Get-AzManagementGroup' command--verify your permissions and the installion of the Az.Resources module; returned error message: $_" -workspaceGuid $WorkSpaceID -workspaceKey $WorkSpaceKey
        throw "Error: Failed to execute the 'Get-AzManagementGroup' command--verify your permissions and the installion of the Az.Resources module; returned error message: $_"
    }
    foreach ($mg in $managementGroups) {
        $MG = Get-AzManagementGroup -GroupName $mg.Name -Expand -Recurse
        $MGItems.Add($MG)
        if ($null -eq $MG.ParentId) {
            $RootMG = $MG
        }
    }
    foreach ($items in $MGItems) {
        foreach ($Children in $items.Children ) {
            foreach ($c in $Children) {
                if ($c.Type -eq "/subscriptions" -and (-not $SubscriptionList.Contains($c) -and $c.DisplayName -ne $CBSSubscriptionName)) {
                    [string]$type = "subscription"
                    $SubscriptionList.Add($c)

                    try {
                        $AssignedPolicyList = Get-AzPolicyAssignment -scope $c.Id -PolicyDefinitionId $PolicyID -ErrorAction Stop
                    }
                    catch {
                        Add-LogEntry 'Error' "Failed to execute the 'Get-AzPolicyAssignment' command for scope '$($c.id)'--verify your permissions and the installion of the Az.Resources module; returned error message: $_" -workspaceGuid $WorkSpaceID -workspaceKey $WorkSpaceKey
                        Write-Error "Error: Failed to execute the 'Get-AzPolicyAssignment' command for scope '$($c.id)'--verify your permissions and the installion of the Az.Resources module; returned error message: $_"                
                    }
                    $AssignedPolicyLocation = $AssignedPolicyList.Properties.Parameters.listOfAllowedLocations.value

                    If ($null -eq $AssignedPolicyList) {
                        $c | Add-Member -MemberType NoteProperty -Name ReportTime -Value $ReportTime -Force
                        $c | Add-Member -MemberType NoteProperty -Name Comments -Value $($msgTable.policyNotAssigned -f $type)
                        $c | Add-Member -MemberType NoteProperty -Name ComplianceStatus -Value $false
                        $c | Add-Member -MemberType NoteProperty -Name ControlName -Value $ControlName
                        $c | Add-Member -MemberType NoteProperty -Name ItemName -Value $ItemName
                        $NonCompliantList.add($c)
                    }
                    elseif (-not ([string]::IsNullOrEmpty(($AssignedPolicyList.Properties.NotScopesScope)))   ) {
                        $c | Add-Member -MemberType NoteProperty -Name ReportTime -Value $ReportTime -Force
                        $c | Add-Member -MemberType NoteProperty -Name ControlName -Value $ControlName
                        $c | Add-Member -MemberType NoteProperty -Name ItemName -Value $ItemName
                        $c | Add-Member -MemberType NoteProperty -Name "ComplianceStatus" -Value $false
                        if (-not (Test-AllowedLocation -AssignedLocations $AssignedPolicyLocation -AllowedLocations $AllowedLocations)  ) {
                            $c | Add-Member -MemberType NoteProperty -Name Comments -Value $($msgTable.excludedFromScope -f $type + $msgTable.notAllowedLocation)
                        }
                        else {
                            $c | Add-Member -MemberType NoteProperty -Name Comments -Value $($msgTable.excludedFromScope -f $type)
                        }
                        $NonCompliantList.add($c)  
                    }
                    else {
                        $c | Add-Member -MemberType NoteProperty -Name ReportTime -Value $ReportTime -Force
                        $c | Add-Member -MemberType NoteProperty -Name Comments -Value $msgTable.isCompliant
                        $c | Add-Member -MemberType NoteProperty -Name "ComplianceStatus" -Value $true
                        $c | Add-Member -MemberType NoteProperty -Name ControlName -Value $ControlName
                        $c | Add-Member -MemberType NoteProperty -Name ItemName -Value $ItemName
                        $CompliantList.add($c) 
                    }
                }
                elseif ($c.Type -like "*managementGroups*" -and (-not $MGList.Contains($c)) ) {
                    [string]$type = "Management Groups"
                    $MGList.Add($c)

                    try {
                        $AssignedPolicyList = Get-AzPolicyAssignment -scope $c.Id -PolicyDefinitionId $PolicyID -ErrorAction Stop
                    }
                    catch {
                        Add-LogEntry 'Error' "Failed to execute the 'Get-AzPolicyAssignment' command for scope '$($c.id)'--verify your permissions and the installion of the Az.Resources module; returned error message: $_" -workspaceGuid $WorkSpaceID -workspaceKey $WorkSpaceKey
                        Write-Error "Error: Failed to execute the 'Get-AzPolicyAssignment' command for scope '$($c.id)'--verify your permissions and the installion of the Az.Resources module; returned error message: $_"                
                    }

                    If ($null -eq $AssignedPolicyList) {
                        $c | Add-Member -MemberType NoteProperty -Name ReportTime -Value $ReportTime -Force
                        $c | Add-Member -MemberType NoteProperty -Name Comments -Value $($msgTable.policyNotAssigned -f $type)
                        $c | Add-Member -MemberType NoteProperty -Name "ComplianceStatus" -Value $false
                        $c | Add-Member -MemberType NoteProperty -Name ControlName -Value $ControlName
                        $c | Add-Member -MemberType NoteProperty -Name ItemName -Value $ItemName
                        $NonCompliantList.add($c)
                    }
                    elseif (-not ([string]::IsNullOrEmpty(($AssignedPolicyList.Properties.NotScopesScope)))) {
                        $c | Add-Member -MemberType NoteProperty -Name ReportTime -Value $ReportTime -Force
                        $c | Add-Member -MemberType NoteProperty -Name ControlName -Value $ControlName
                        $c | Add-Member -MemberType NoteProperty -Name ItemName -Value $ItemName
                        $c | Add-Member -MemberType NoteProperty -Name "ComplianceStatus" -Value $false
                        if (-not (Test-AllowedLocation -AssignedLocations $AssignedPolicyLocation -AllowedLocations $AllowedLocations)  ) {
                            $c | Add-Member -MemberType NoteProperty -Name Comments -Value $($msgTable.excludedFromScope -f $type + $msgTable.notAllowedLocation)
                        }
                        else {
                            $c | Add-Member -MemberType NoteProperty -Name Comments -Value $($msgTable.excludedFromScope -f $type)
                        }
                        $NonCompliantList.add($c)  
                    }
                    else {       
                        $c | Add-Member -MemberType NoteProperty -Name ReportTime -Value $ReportTime -Force
                        $c | Add-Member -MemberType NoteProperty -Name Comments -Value $msgTable.isCompliant
                        $c | Add-Member -MemberType NoteProperty -Name "ComplianceStatus" -Value $true
                        $c | Add-Member -MemberType NoteProperty -Name ControlName -Value $ControlName
                        $c | Add-Member -MemberType NoteProperty -Name ItemName -Value $ItemName
                        $CompliantList.add($c) 
                    }
                }
            }                
        }
    }


    try {
        $AssignedPolicyList = Get-AzPolicyAssignment -scope $RootMG.Id -PolicyDefinitionId $PolicyID -ErrorAction Stop
    }
    catch {
        Add-LogEntry 'Error' "Failed to execute the 'Get-AzPolicyAssignment' command for scope '$($RootMG.Id)'--verify your permissions and the installion of the Az.Resources module; returned error message: $_" -workspaceGuid $WorkSpaceID -workspaceKey $WorkSpaceKey
        Write-Error "Error: Failed to execute the 'Get-AzPolicyAssignment' command for scope '$($RootMG.Id)'--verify your permissions and the installion of the Az.Resources module; returned error message: $_"                
    }
    If ($null -eq $AssignedPolicyList) {
        $RootMG | Add-Member -MemberType NoteProperty -Name ReportTime -Value $ReportTime -Force
        $RootMG | Add-Member -MemberType NoteProperty -Name Comments -Value $msgTable.policyNotAssignedRootMG
        $RootMG | Add-Member -MemberType NoteProperty -Name "ComplianceStatus" -Value $false
        $RootMG | Add-Member -MemberType NoteProperty -Name ControlName -Value $ControlName
        $RootMG | Add-Member -MemberType NoteProperty -Name ItemName -Value $ItemName
        $NonCompliantList.add($RootMG)
    }
    elseif (-not ([string]::IsNullOrEmpty(($AssignedPolicyList.Properties.NotScopesScope)))) {
        $RootMG | Add-Member -MemberType NoteProperty -Name ReportTime -Value $ReportTime -Force
        $RootMG | Add-Member -MemberType NoteProperty -Name ControlName -Value $ControlName
        $RootMG | Add-Member -MemberType NoteProperty -Name ItemName -Value $ItemName
        $RootMG | Add-Member -MemberType NoteProperty -Name "ComplianceStatus" -Value $false
        if (-not (Test-AllowedLocation -AssignedLocations $AssignedPolicyLocation -AllowedLocations $AllowedLocations)  ) {
            $RootMG | Add-Member -MemberType NoteProperty -Name Comments -Value $($msgTable.rootMGExcluded + $msgTable.notAllowedLocation)
        }
        else {
            $RootMG | Add-Member -MemberType NoteProperty -Name Comments -Value $msgTable.rootMGExcluded
        }
        $NonCompliantList.add($RootMG)  
    }
    else {       
        $RootMG | Add-Member -MemberType NoteProperty -Name Comments -Value $msgTable.isCompliant
        $RootMG | Add-Member -MemberType NoteProperty -Name "ComplianceStatus" -Value $true
        $RootMG | Add-Member -MemberType NoteProperty -Name ControlName -Value $ControlName -Force
        $RootMG | Add-Member -MemberType NoteProperty -Name ItemName -Value $ItemName -Force
        $RootMG | Add-Member -MemberType NoteProperty -Name ReportTime -Value $ReportTime -Force
        $CompliantList.add($RootMG) 
    }
    if ($CompliantList.Count -gt 0) {
        $JsonObject = $CompliantList | convertTo-Json
        if ($DebugData) {
            "Sending Compliant data."
            "Id: $WorkSpaceID"
            "Key: $workspaceKey"
            "Body: $JsonObject"
        }
        Send-OMSAPIIngestionFile  -customerId $WorkSpaceID `
            -sharedkey $workspaceKey `
            -body $JsonObject `
            -logType $LogType `
            -TimeStampField Get-Date
    }
    if ($NonCompliantList.Count -gt 0) {
        $JsonObject = $NonCompliantList | convertTo-Json  
        if ($DebugData) {
            "Sending Non-Compliant data."
            "Id: $WorkSpaceID"
            "Key: $workspaceKey"
            "Body: $JsonObject"
        }
        Send-OMSAPIIngestionFile  -customerId $WorkSpaceID `
            -sharedkey $workspaceKey `
            -body $JsonObject `
            -logType $LogType `
            -TimeStampField Get-Date
    }
}


function Test-AllowedLocation {
    param (
        [array] $AssignedLocations,
        [array] $AllowedLocations
    )
    $IsCompliant = $true
    foreach ($AssignedLocation in $AssignedLocations) {
        if ( $AssignedLocation -notin $AllowedLocations) {
            $IsCompliant = $false
        }
    }
    return $IsCompliant 
}



# SIG # Begin signature block
# MIInpwYJKoZIhvcNAQcCoIInmDCCJ5QCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAJctLcI2GJZ0EV
# oWJRdXmInOngN2vWEl2F9uaVJ0VZt6CCDYUwggYDMIID66ADAgECAhMzAAACU+OD
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIN1A
# SgWlkoiPDZPgavjtMmH4cg8MrfCU2kbjxfZ/LINfMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQu
# Y29tIDANBgkqhkiG9w0BAQEFAASCAQBjybxs/oxvGU/5IYBFKFy5VaTZCGWjXvsM
# 1UjhmVFME/mQEv7TK1il2w9HVBF3TQu69cpEkWmgljcfIr3S+gsvhi8qgZXQ+7gH
# 2v7MeRep0kFo1kR7NDF+wjbNTkWV0QLQrT59ZLtFnRb4krYjdVWP9/eJVqHp+Uit
# 3I90d3iu8SbRCAmPojcQuxDWN66nG/OOh88tAranTWbIWDL6mqnKSMgXVHBofvIz
# aKWWLuXUxYlXcVvodKIEUb2b95key9s7RKPF51lnE53Ku7jc3nQhJ5UXywlSIjk5
# DwkcPDxoi+Mcw9TwCtV1baWXN2AIZY8GifEMd3QBgmG/BD9HOgiCoYIXADCCFvwG
# CisGAQQBgjcDAwExghbsMIIW6AYJKoZIhvcNAQcCoIIW2TCCFtUCAQMxDzANBglg
# hkgBZQMEAgEFADCCAVEGCyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEILwfyrmsRYVw8o4p02iEgYUoMPDb2rOi
# nDBsvB1zFTOXAgZigprqkD8YEzIwMjIwNjAyMjA1NTM3LjQ2OVowBIACAfSggdCk
# gc0wgcoxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNV
# BAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxl
# cyBUU1MgRVNOOjIyNjQtRTMzRS03ODBDMSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNloIIRVzCCBwwwggT0oAMCAQICEzMAAAGYdrOMxdAFoQEA
# AQAAAZgwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTAwHhcNMjExMjAyMTkwNTE1WhcNMjMwMjI4MTkwNTE1WjCByjELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFt
# ZXJpY2EgT3BlcmF0aW9uczEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046MjI2NC1F
# MzNFLTc4MEMxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Uw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDG1JWsVksp8xG4sLMnfxfi
# t3ShI+7G1MfTT+5XvQzuAOe8r5MRAFITTmjFxzoLFfmaxLvPVlmDgkDi0rqsOs9A
# l9jVwYSFVF/wWC2+B76OysiyRjw+NPj5A4cmMhPqIdNkRLCE+wtuI/wCaq3/Lf4k
# oDGudIcEYRgMqqToOOUIV4e7EdYb3k9rYPN7SslwsLFSp+Fvm/Qcy5KqfkmMX4S3
# oJx7HdiQhKbK1C6Zfib+761bmrdPLT6eddlnywls7hCrIIuFtgUbUj6KJIZn1MbY
# Y8hrAM59tvLpeGmFW3GjeBAmvBxAn7o9Lp2nykT1w9I0s9ddwpFnjLT2PK74GDSs
# xFUZG1UtLypi/kZcg9WenPAZpUtPFfO5Mtif8Ja8jXXLIP6K+b5LiQV8oIxFSBfg
# FN7/TL2tSSfQVcvqX1mcSOrx/tsgq3L6YAxI6Pl4h1zQrcAmToypEoPYNc/RlSBk
# 6ljmNyNDsX3gtK8p6c7HCWUhF+YjMgfanQmMjUYsbjdEsCyL6QAojZ0f6kteN4cV
# 6obFwcUEviYygWbedaT86OGe9LEOxPuhzgFv2ZobVr0J8hl1FVdcZFbfFN/gdjHZ
# /ncDDqLNWgcoMoEhwwzo7FAObqKaxfB5zCBqYSj45miNO5g3hP8AgC0eSCHl3rK7
# JPMr1B+8JTHtwRkSKz/+cwIDAQABo4IBNjCCATIwHQYDVR0OBBYEFG6RhHKNpsg3
# mgons7LR5YHTzeE3MB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8G
# A1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBs
# BggrBgEFBQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUy
# MDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgw
# DQYJKoZIhvcNAQELBQADggIBACT6B6F33i/89zXTgqQ8L6CYMHx9BiaHOV+wk53J
# OriCzeaLjYgRyssJhmnnJ/CdHa5qjcSwvRptWpZJPVK5sxhOIjRBPgs/3+ER0vS8
# 7IA+aGbf7NF7LZZlxWPOl/yFBg9qZ3tpOGOohQInQn5zpV23hWopaN4c49jGJHLP
# Afy9u7+ZSGQuw14CsW/XRLELHT18I60W0uKOBa5Pm2ViohMovcbpNUCEERqIO9WP
# wzIwMRRw34/LgjuslHJop+/1Ve/CfyNqweUmwepQHJrd+wTLUlgm4ENbXF6i52jF
# fYpESwLdAn56o/pj+grsd2LrAEPQRyh49rWvI/qZfOhtT2FWmzFw6IJvZ7CzT1O+
# Fc0gIDBNqass5QbmkOkKYy9U7nFA6qn3ZZ+MrZMsJTj7gxAf0yMkVqwYWZRk4brY
# 9q8JDPmcfNSjRrVfpYyzEVEqemGanmxvDDTzS2wkSBa3zcNwOgYhWBTmJdLgyiWJ
# Geqyj1m5bwNgnOw6NzXCiVMzfbztdkqOdTR88LtAJGNRjevWjQd5XitGuegSp2mM
# JglFzRwkncQau1BJsCj/1aDY4oMiO8conkmaWBrYe11QCS896/sZwSdnEUJak0qp
# nBRFB+THRIxIivCKNbxG2QRZ8dh95cOXgo0YvBN5a1p+iJ3vNwzneU2AIC7z3rrI
# bN2fMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG9w0B
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
# VQQLEx1UaGFsZXMgVFNTIEVTTjoyMjY0LUUzM0UtNzgwQzElMCMGA1UEAxMcTWlj
# cm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUA8ywe/iF5
# M8fIU2aT6yQ3vnPpV5OggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMDANBgkqhkiG9w0BAQUFAAIFAOZDgpswIhgPMjAyMjA2MDMwMjQwMjdaGA8y
# MDIyMDYwNDAyNDAyN1owdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA5kOCmwIBADAK
# AgEAAgIQ5AIB/zAHAgEAAgIRzzAKAgUA5kTUGwIBADA2BgorBgEEAYRZCgQCMSgw
# JjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3
# DQEBBQUAA4GBACfHwIMnSSSvgPkAv6rnF32GShAUVQnOmogvLvclg57NlnbaW2O/
# PcDfs4g5z2++90jdzsgIDwBbf3a1Wbqs2LNrWdlCrmHDIbEOC44horS5PLPIVbgK
# dCg29Z8TslJ9/JvcbFfzOH3buYcr/AaKNGxLryu5EnYlfBTS6OSw960lMYIEDTCC
# BAkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEm
# MCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGYdrOM
# xdAFoQEAAQAAAZgwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsq
# hkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQg6blE+LR4tgA0Io1KfDlhjnu0Ut0u
# S/K6jgXMAsVapx0wgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCC/ps4GOTn/
# 9wO1NhHM9Qfe0loB3slkw1FF3r+bh21WxDCBmDCBgKR+MHwxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFBDQSAyMDEwAhMzAAABmHazjMXQBaEBAAEAAAGYMCIEIJ4axjloQ5p0
# VbPlKgc4CNy2mvXunK02I9OcFuwSRTHFMA0GCSqGSIb3DQEBCwUABIICAAD9j2vS
# nSsEfXUaQ7p/yDOftiPK0NzEmy9IvtoGefyi8nPhq7j/XInYZcvb25U9Hl208xbQ
# NQfZ023VoGV10i71PvSWE0qykiuq7stCZM/XtEo2nmSqmwthrSs4FkospG3mfmXH
# h1J6HSulQVFyI5FAg59RSO1UUT6sE94N3h5IdYIHEEDUajr+3kHsuahtzfdr7M2i
# n69ujYM6zSDPx8I/wrMcuXkBVMYFOyxPmjLUrU+DiQbQnVnvAB0m+IIyNxmsGJTn
# qbv3fLhgnEVBZ/r4tpibFSagl6b4EUbb5CAxNjuyVwh9Y22QTRHYoZpU2xzTrN0P
# mpcd/kim+dYvKxni+Picv6f53p9FSB2YCDxCPFPK490CTZ25pf4Ee7CRC5BqDx6R
# sAfYMOPtVz3ftySUyedTQyxYoHc80ciKQgwJYsQp7ePo4ITpZA1TQ/54yTemIUUi
# yCa62ZAj8NBVB5UaqrMMtIEMKsVzzpv52+2BX+MKDc5czsm3FXEqw+Ot5x5f1idP
# xcjzK/f9IO12yQdQZS2RE6rFaEiVL6QpKtXh8FIu2C66bW6B182Bi1e4jrDiGXap
# 0XZFzNK3EluwKY+5ng+msNzI5/zJd6UeVa6vrOY8NGr6NQtfN2ifSCY1I/+wGFiG
# Z+sKFgNKYuJJ12+SaVnCYNm3isWR+BwEofwp
# SIG # End signature block
