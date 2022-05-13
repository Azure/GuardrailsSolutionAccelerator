function new-customObject {
    param (
        [string] $Type,
        [string] $Id,
        [string] $Name,
        [string] $DisplayName,
        [string] $CtrlName,
        [bool] $ComplianceStatus,
        [string] $Comments,
        [string] $ItemName,
        [string] $test
    )
    $tempObject=[PSCustomObject]@{ 
        Type = $Type
        Id= $Id
        Name = $Name
        DisplayName = $DisplayName
        ComplianceStatus = $ComplianceStatus
        Comments = $Comments
        ItemName = $ItemName
        ControlName = $CtrlName
    }
    return $tempObject
}
function update-object 
{
    param (
        [Object] $object, [string] $comments, [string] $ControlName, [string] $ItemName, [bool] $ComplianceStatus
    )

    $object | Add-Member -MemberType NoteProperty -Name Comments -Value $comments
    $object | Add-Member -MemberType NoteProperty -Name "ComplianceStatus" -Value $ComplianceStatus
    $object | Add-Member -MemberType NoteProperty -Name ControlName -Value $ControlName -Force   
    $object | Add-Member -MemberType NoteProperty -Name ItemName -Value $ItemName -Force
    return $object
}
function Test-ExemptionExists {
    param (
        [object] $object, [string] $ControlName, [string] $ItemName, [string] $ScopeId, [array] $requiredPolicyExemptionIds
    )
    $newObject=new-customObject -Type $object.Type -Name $object.Name -DisplayName $object.DisplayName `
    -Id $object.Id -ComplianceStatus $true -Comments "" -ItemName $ItemName `
    -CtrlName $ControlName
    $exemptionsIds=(Get-AzPolicyExemption -Scope $ScopeId).Properties.PolicyDefinitionReferenceIds
    if ($null -ne $exemptionsIds)
    {
        foreach ($exemptionId in $exemptionsIds)
        {
            if ($exemptionId -in $requiredPolicyExemptionIds)
            {
                $newObject.ComplianceStatus=$false
                $newObject.Comments+="Exemption for $exemptionId found."
            }
        }
    }
    else {
        $newObject.Comments="No exemptions found."
    }
    return $newObject
}

function Verify-PBMMPolicy {
    param (
            [string] $ControlName, [string] $CtrName6, [string] $CtrName7,
            [string]$ItemName,[string]$ItemName6, [string]$ItemName7, [string] $PolicyID, `
            [string] $WorkSpaceID, [string] $workspaceKey, [string] $LogType
    )
    [System.Object] $RootMG = $null
    [string] $PolicyID = $policyID
    [PSCustomObject] $MGList = New-Object System.Collections.ArrayList
    [PSCustomObject] $MGItems = New-Object System.Collections.ArrayList
    [PSCustomObject] $SubscriptionList = New-Object System.Collections.ArrayList
    [PSCustomObject] $CompliantList = New-Object System.Collections.ArrayList
    [PSCustomObject] $NonCompliantList = New-Object System.Collections.ArrayList
    [string] $Comment1 = "The Policy or Initiative is not assigned on the "
    [string] $Comment2 = " is excluded from the scope of the assignment"
    [string] $Comment3 = "Compliant"
    [string] $Comment4 = "The Policy or Initiative is not assigned on the Root Management Groups"
    [string] $Comment5="This Root Management Groups is excluded from the scope of the assignment"
    [string] $Comment6="PBMM Initiative is not applied."

    $gr6RequiredPolicies=@("TransparentDataEncryptionOnSqlDatabasesShouldBeEnabled","DiskEncryptionShouldBeAppliedOnVirtualMachines")
    $gr7RequiredPolicies=@("FunctionAppShouldOnlyBeAccessibleOverHttps","WebApplicationShouldOnlyBeAccessibleOverHttps", "ApiAppShouldOnlyBeAccessibleOverHttps", "OnlySecureConnectionsToYourRedisCacheShouldBeEnabled","SecureTransferToStorageAccountsShouldBeEnabled")
    
    #Code Starts
    foreach ($mg in Get-AzManagementGroup) {
        $MG = Get-AzManagementGroup -GroupName $mg.Name -Expand -Recurse
        $MGItems.Add($MG)
        if ($null -eq $MG.ParentId) {
            $RootMG = $MG
        }
    }
    foreach ($items in $MGItems) {
        foreach ($Children in $items.Children ) {
            foreach ($c in $Children) {
                Write-Output "Children: $($c.DisplayName)"
                if ($c.Type -eq "/subscriptions" -and (-not $SubscriptionList.Contains($c))) {
                    [string]$type = "subscription"
                    $SubscriptionList.Add($c)
                    $AssignedPolicyList = Get-AzPolicyAssignment -scope $c.Id -PolicyDefinitionId $PolicyID
                    If ($null -eq $AssignedPolicyList) {
                        $c=new-customObject -Type $c.Type -Id $c.Id -Name $c.Name `
                        -DisplayName $c.DisplayName `
                        -ComplianceStatus $false `
                        -Comments "$Comment1$type" `
                        -ItemName $ItemName `
                        -CtrlName $ControlName
                        $NonCompliantList.add($c)
                        # the lines below create an entry for modules 6 and 7
                        $GR6Object = new-customObject -Type $c.Type -Id $c.Id -Name $c.Name `
                            -DisplayName $c.DisplayName -ComplianceStatus $false `
                            -Comments $Comment6 `
                            -ItemName $ItemName6 `
                            -CtrlName $CtrName6
                        $NonCompliantList.add($GR6Object)
                        $GR7Object = new-customObject -Type $c.Type -Id $c.Id -Name $c.Name `
                            -DisplayName $c.DisplayName `
                            -ComplianceStatus $false `
                            -Comments $Comment6 `
                            -ItemName $ItemName7 `
                            -CtrlName $CtrName7
                        $NonCompliantList.add($GR7Object)
                    }
                    elseif (-not ([string]::IsNullOrEmpty(($AssignedPolicyList.Properties.NotScopesScope)))) {
                        $c=new-customObject -Type $c.Type -Id $c.Id -Name $c.Name `
                        -DisplayName $c.DisplayName `
                        -ComplianceStatus $false `
                        -Comments "$Comment1$type" `
                        -ItemName $ItemName `
                        -CtrlName $ControlName
                        $NonCompliantList.add($c)  
                        # the lines below create an entry for modules 6 and 7
                        $GR6Object = new-customObject -Type $c.Type -Id $c.Id -Name $c.Name `
                            -DisplayName $c.DisplayName -ComplianceStatus $false `
                            -Comments $Comment6 `
                            -ItemName $ItemName6 `
                            -CtrlName $CtrName6
                        $NonCompliantList.add($GR6Object)
                        $GR7Object = new-customObject -Type $c.Type -Id $c.Id -Name $c.Name `
                            -DisplayName $c.DisplayName `
                            -ComplianceStatus $false `
                            -Comments $Comment6 `
                            -ItemName $ItemName7 `
                            -CtrlName $CtrName7
                        $NonCompliantList.add($GR7Object)
                    }
                    else {
                        $c=new-customObject -Type $c.Type -Id $c.Id -Name $c.Name `
                        -DisplayName $c.DisplayName `
                        -ComplianceStatus $true `
                        -CtrlName $ControlName `
                        -Comments $Comment3 `
                        -ItemName $ItemName `
                        -Test $ControlName
                        $CompliantList.add($c) # it has PBMM, fine, but has anything been exempted and is related to GR6 or GR7?
                        #At this point the PBMM Initiative has been found and is applied at that scope.
                        #The funcion tests and updates the object with the proper status and control name.
                        $c2=Test-ExemptionExists -object $c -ControlName $CtrName6 -ItemName $ItemName6 -ScopeId $c.Id -requiredPolicyExemptionIds $gr6RequiredPolicies
                        if ($c2.ComplianceStatus)
                        {
                            $CompliantList.add($c2)
                        }
                        else {
                            $NonCompliantList.add($c2) 
                        }
                        $c3=Test-ExemptionExists -object $c -ControlName $CtrName7 -ItemName $ItemName7 -ScopeId $c.Id -requiredPolicyExemptionIds $gr7RequiredPolicies
                        if ($c3.ComplianceStatus)
                        {
                            $CompliantList.add($c3)
                        }
                        else {
                            $NonCompliantList.add($c3) 
                        }
                    }
                }
                elseif ($c.Type -like "*managementGroups*" -and (-not $MGList.Contains($c)) ) {
                    [string]$type = "Management Groups"
                    $MGList.Add($c)
                    $AssignedPolicyList = Get-AzPolicyAssignment -scope $C.Id -PolicyDefinitionId $PolicyID
                    If ($null -eq $AssignedPolicyList) {
                        $c=new-customObject -Type $c.Type -Id $c.Id -Name $c.Name -DisplayName $c.DisplayName `
                        -CtrlName $ControlName -ComplianceStatus $false -ItemName $ItemName -Comments "$Comment1$type"
                        $NonCompliantList.add($c)
                        # the lines below create an entry for modules 6 and 7
                        $GR6Object=new-customObject -Type $c.Type -Id $c.Id -Name $c.Name `
                        -DisplayName $c.DisplayName `
                        -ComplianceStatus $false `
                        -Comments $Comment6 `
                        -ItemName $ItemName6 `
                        -CtrlName $CtrName6
                        $NonCompliantList.add($GR6Object)
                        $GR7Object=new-customObject -Type $c.Type -Id $c.Id -Name $c.Name `
                        -DisplayName $c.DisplayName `
                        -ComplianceStatus $false `
                        -Comments $Comment6 `
                        -ItemName $ItemName7 `
                        -CtrlName $CtrName7
                        $NonCompliantList.add($GR7Object)
                    }
                    elseif (-not ([string]::IsNullOrEmpty(($AssignedPolicyList.Properties.NotScopesScope)))) {
                        $c=new-customObject -Type $c.Type -Id $c.Id -Name $c.Name -DisplayName $c.DisplayName `
                        -CtrlName $ControlName -ComplianceStatus $false -ItemName $ItemName -Comments "$type$Comment2"
                        $NonCompliantList.add($c)
                        # the lines below create an entry for modules 6 and 7
                        $GR6Object=new-customObject -Type $c.Type -Id $c.Id -Name $c.Name `
                        -DisplayName $c.DisplayName `
                        -ComplianceStatus $false `
                        -Comments $Comment6 `
                        -ItemName $ItemName6 `
                        -CtrlName $CtrName6
                        $NonCompliantList.add($GR6Object)
                        $GR7Object=new-customObject -Type $c.Type -Id $c.Id -Name $c.Name `
                        -DisplayName $c.DisplayName -ComplianceStatus $false `
                        -Comments $Comment6 `
                        -ItemName $ItemName7 `
                        -CtrlName $CtrName7
                        $NonCompliantList.add($GR7Object)
                    }
                    else {       
                        $c=new-customObject -Type $c.Type -Id $c.Id -Name $c.Name -DisplayName $c.DisplayName `
                        -CtrlName $ControlName -ComplianceStatus $true -ItemName $ItemName -Comments $Comment3
                        $CompliantList.add($c)
                        # it has PBMM, fine, but has anything been exempted and is related to GR6 or GR7?
                        #At this point the PBMM Initiative has been found and is applied at that scope.
                        #The funcion tests and updates the object with the proper status and control name.
                        $c2=Test-ExemptionExists -object $c -ControlName $CtrName6 -ItemName $ItemName6 -ScopeId $c.Id -requiredPolicyExemptionIds $gr6RequiredPolicies
                        if ($c2.ComplianceStatus)
                        {
                            $CompliantList.add($c2)
                        }
                        else {
                            $NonCompliantList.add($c2) 
                        }
                        $c3=Test-ExemptionExists -object $c -ControlName $CtrName7 -ItemName $ItemName7 -ScopeId $c.Id -requiredPolicyExemptionIds $gr7RequiredPolicies
                        if ($c3.ComplianceStatus)
                        {
                            $CompliantList.add($c3)
                        }
                        else {
                            $NonCompliantList.add($c3) 
                        } 
                    }
                }
            }                
        }
    }
    $AssignedPolicyList = Get-AzPolicyAssignment -scope $RootMG.Id -PolicyDefinitionId $PolicyID
    If ($null -eq $AssignedPolicyList) {
        Write-Output "RootMG: $($RootMG.DisplayName)"
        $RootMG2=new-customObject -Type $RootMG.Type -Id $RootMG.Id -Name $RootMG.Name -DisplayName $RootMG.DisplayName `
        -comments $Comment4 -CtrlName $ControlName -ComplianceStatus $false -ItemName $ItemName
        $NonCompliantList.add($RootMG2)
        # the lines below create an entry for modules 6 and 7
        $GR6Object=new-customObject -Type $RootMG.Type -Id $RootMG.Id -Name $RootMG.Name -DisplayName $RootMG.DisplayName `
        -ComplianceStatus $false -Comments $Comment6 -ItemName $ItemName6 `
        -CtrlName $CtrName6
        $NonCompliantList.add($GR6Object)
        $GR7Object=new-customObject -Type $RootMG.Type -Id $RootMG.Id -Name $RootMG.Name -DisplayName $RootMG.DisplayName `
        -ComplianceStatus $false -Comments $Comment6 -ItemName $ItemName7 `
        -CtrlName $CtrName7
        $NonCompliantList.add($GR7Object)
    }
    elseif (-not ([string]::IsNullOrEmpty(($AssignedPolicyList.Properties.NotScopesScope)))) {
        $RootMG2=new-customObject -Type $RootMG.Type -Id $RootMG.Id -Name $RootMG.Name -DisplayName $RootMG.DisplayName `
        -comments $Comment5 -CtrlName $ControlName -ComplianceStatus $false -ItemName $ItemName
        $NonCompliantList.add($RootMG2)
        # the lines below create an entry for modules 6 and 7
        $GR6Object=new-customObject -Type $RootMG.Type -Id $RootMG.Id -Name $RootMG.Name -DisplayName $RootMG.DisplayName `
        -ComplianceStatus $false -Comments $Comment6 -ItemName $ItemName6 `
        -CtrlName $CtrName6
        $NonCompliantList.add($GR6Object)
        $GR7Object=new-customObject -Type $RootMG.Type -Id $RootMG.Id -Name $RootMG.Name -DisplayName $RootMG.DisplayName `
        -ComplianceStatus $false -Comments $Comment6 -ItemName $ItemName7 `
        -CtrlName $CtrName7
        $NonCompliantList.add($GR7Object)
    }
    else {       
        $RootMG1=new-customObject -Type $RootMG.Type -Id $RootMG.Id -Name $RootMG.Name -DisplayName $RootMG.DisplayName `
        -comments $Comment3 -CtrlName $ControlName -ComplianceStatus $true -ItemName $ItemName
        $CompliantList.add($RootMG1) 
        # add detection of exemptions
        $RootMG2=Test-ExemptionExists -object $RootMG -ControlName $CtrName6 -ItemName $ItemName6 -ScopeId $RootMG -requiredPolicyExemptionIds $gr6RequiredPolicies
        if ($RootMG2.ComplianceStatus)
        {
            $CompliantList.add($RootMG2)
        }
        else {
            $NonCompliantList.add($RootMG2) 
        }
        $RootMG3=Test-ExemptionExists -object $RootMG -ControlName $CtrName7 -ItemName $ItemName6 -ScopeId $RootMG.Id -requiredPolicyExemptionIds $gr7RequiredPolicies
        if ($RootMG3.ComplianceStatus)
        {
            $CompliantList.add($RootMG3)
        }
        else {
            $NonCompliantList.add($RootMG3) 
        }
    }
    #$CompliantList
    "Compliant list"
    $CompliantList | convertto-json -Depth 3
    if ($CompliantList.Count -gt 0)
    {
        $JsonObject = $CompliantList | convertTo-Json -Depth 3
        #"Compliant List"
        #$JsonObject
        Send-OMSAPIIngestionFile  -customerId $WorkSpaceID `
        -sharedkey $workspaceKey `
        -body $JsonObject `
        -logType $LogType `
        -TimeStampField Get-Date
    }
    "Non compliant list"
    $NonCompliantList | ConvertTo-Json -Depth 3
    if ($NonCompliantList.Count -gt 0)
    {
        $JsonObject = $NonCompliantList | convertTo-Json -Depth 3 
        #"NonCompliant List"
        #$NonCompliantList
        #"Json"
        #$JsonObject
        Send-OMSAPIIngestionFile  -customerId $WorkSpaceID `
            -sharedkey $workspaceKey `
            -body $JsonObject `
            -logType $LogType `
            -TimeStampField Get-Date
    }
}

# SIG # Begin signature block
# MIInswYJKoZIhvcNAQcCoIInpDCCJ6ACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDkieZSLbv51D9t
# KJkNEL1fo0yT8uVfECkQIgJY9ESzl6CCDYUwggYDMIID66ADAgECAhMzAAACU+OD
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGiA
# LzNb/PXYY5LqCErDAykcbMxwa/3Y3yEV+vgyXlHOMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQu
# Y29tIDANBgkqhkiG9w0BAQEFAASCAQBw/UYlnzFfmWsB/LWkzMUuZIwwZORCkZJv
# RAOh5Dl3K1fS53DZIr1raLRYKdTyFGDhMtEBAcrwa+ZCU+rXN+Jy+XHlk9toe6C1
# fm7v2f6VM3+raP1bqZ1lXCgfR87oFqeP5GImJ7gBfxhyLcSGKHOeekjDoJ04HZVK
# 1avYn5eYOIAaiLfxRWY/5A0+deqJmGZe8XPdXxXQJFS2x9i0Nn4jITJILp+1h3oM
# RkAco10qqM3J2++3BWCwbD8nihsrCxCSISVTloUvvyXwyZVIErwncb01BCbnpElu
# Nfjagvdj2umaa7ZP23tWImBlkza1oILHow2KQ7s8x3tfiiZYp7L3oYIXDDCCFwgG
# CisGAQQBgjcDAwExghb4MIIW9AYJKoZIhvcNAQcCoIIW5TCCFuECAQMxDzANBglg
# hkgBZQMEAgEFADCCAVUGCyqGSIb3DQEJEAEEoIIBRASCAUAwggE8AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEILFY+s7GKVKBd/jO5UaMHQFw6+lFkLwY
# 6UIoq3rNqDfCAgZiaxg8hkkYEzIwMjIwNTEzMDUyNjMyLjQ1MlowBIACAfSggdSk
# gdEwgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNV
# BAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1U
# aGFsZXMgVFNTIEVTTjo0NjJGLUUzMTktM0YyMDElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZaCCEV8wggcQMIIE+KADAgECAhMzAAABpAfP44+j
# um/WAAEAAAGkMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwMB4XDTIyMDMwMjE4NTExOFoXDTIzMDUxMTE4NTExOFowgc4xCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29m
# dCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVT
# Tjo0NjJGLUUzMTktM0YyMDElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# U2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMBHjgD6FPy8
# 1PUhcOIVGh4bOSaq634Y+TjW2hNF9BlnWxLJCEuMiV6YF5x6YTM7T1ZLM6NnH0wh
# Pypiz3bVZRmwgGyTURKfVyPJ89R3WaZ/HMvcAJZnCMgL+mOpxE94gwQJD/qo8Uqu
# OrCKCY/fcjchxV8yMkfIqP69HnWfW0ratk+I2GZF2ISFyRtvEuxJvacIFDFkQXj3
# H+Xy9IHzNqqi+g54iQjOAN6s3s68mi6rqv6+D9DPVPg1ev6worI3FlYzrPLCIuns
# btYt3Xw3aHKMfA+SH8CV4iqJ/eEZUP1uFJT50MAPNQlIwWERa6cccSVB5mN2YgHf
# 8zDUqQU4k2/DWw+14iLkwrgNlfdZ38V3xmxC9mZc9YnwFc32xi0czPzN15C8wiZE
# IqCddxbwimc+0LtPKandRXk2hMfwg0XpZaJxDfLTgvYjVU5PXTgB10mhWAA/Yosg
# bB8KzvAxXPnrEnYg3XLWkgBZ+lOrHvqiszlFCGQC9rKPVFPCCsey356VhfcXlvwA
# JauAk7V0nLVTgwi/5ILyHffEuZYDnrx6a+snqDTHL/ZqRsB5HHq0XBo/i7BVuMXn
# SSXlFCo3On8IOl8JOKQ4CrIlri9qWJYMxsSICscotgODoYOO4lmXltKOB0l0IAhE
# XwSSKID5QAa9wTpIagea2hzjI6SUY1W/AgMBAAGjggE2MIIBMjAdBgNVHQ4EFgQU
# 4tATn6z4CBL2xZQd0jjN6SnjJMIwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacb
# UzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAo
# MSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1w
# JTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggr
# BgEFBQcDCDANBgkqhkiG9w0BAQsFAAOCAgEACVYcUNEMlyTuPDBGhiZ1U548ssF6
# J2g9QElWEb2cZ4dL0+5G8721/giRtTPvgxQhDF5rJCjHGj8nFSqOE8fnYz9vgb2Y
# clYHvkoKWUJODxjhWS+S06ZLR/nDS85HeDAD0FGduAA80Q7vGzknKW2jxoNHTb74
# KQEMWiUK1M2PDN+eISPXPhPudGVGLbIEAk1Goj5VjzbQuLKhm2Tk4a22rkXkeE98
# gyNojHlBhHbb7nex3zGBTBGkVtwt2ud7qN2rcpuJhsJ/vL/0XYLtyOk7eSQZdfye
# 0TT1/qj18iSXHsIXDhHOuTKqBiiatoo4Unwk7uGyM0lv38Ztr+YpajSP+p0PEMRH
# 9RdfrKRm4bHV5CmOTIzAmc49YZt40hhlVwlClFA4M+zn3cyLmEGwfNqD693hD5W3
# vcpnhf3xhZbVWTVpJH1CPGTmR4y5U9kxwysK8VlfCFRwYUa5640KsgIv1tJhF9LX
# emWIPEnuw9JnzHZ3iSw5dbTSXp9HmdOJIzsO+/tjQwZWBSFqnayaGv3Y8w1KYiQJ
# S8cKJhwnhGgBPbyan+E5D9TyY9dKlZ3FikstwM4hKYGEUlg3tqaWEilWwa9SaNet
# NxjSfgah782qzbjTQhwDgc6Jf07F2ak0YMnNJFHsBb1NPw77dhmo9ki8vrLOB++d
# 6Gm2Z/jDpDOSst8wggdxMIIFWaADAgECAhMzAAAAFcXna54Cm0mZAAAAAAAVMA0G
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
# byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo0NjJGLUUzMTktM0YyMDEl
# MCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsO
# AwIaAxUANBwo4pNrfEL6DVo+tw96vGJvLp+ggYMwgYCkfjB8MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIFAOYoCwEwIhgPMjAyMjA1
# MTMwMjM4NTdaGA8yMDIyMDUxNDAyMzg1N1owdzA9BgorBgEEAYRZCgQBMS8wLTAK
# AgUA5igLAQIBADAKAgEAAgIf6QIB/zAHAgEAAgIR8jAKAgUA5ilcgQIBADA2Bgor
# BgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAID
# AYagMA0GCSqGSIb3DQEBBQUAA4GBAJQv2pokzCeOv/4uqproLHX9L5aPEI/QEZRQ
# J8QKSuiTA9RB+wssdi549CKBS8aPdtuSwn94M888pOangtAZuWHuwHtsgabJZGwp
# aQB71Qx+8CzAHYcmcikOkxIvXKV53UB5eQQu+7YZM+8dznPMksbmZ/CGJjB94mTo
# FDr6qoSUMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTACEzMAAAGkB8/jj6O6b9YAAQAAAaQwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqG
# SIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgceKRV166vDi9
# VpkiTGmu/K+kMgW3AUA7IF8C6RmWLlEwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHk
# MIG9BCAF/OCjISZwpMBJ8MJ3WwMCF3qOa5YHFG6J4uHjaup5+DCBmDCBgKR+MHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAABpAfP44+jum/WAAEAAAGk
# MCIEIC2USpGIRgwblxW/k/BGwTtsrWwSEZKtF3szY1h+NXavMA0GCSqGSIb3DQEB
# CwUABIICAFlpTfo7sdUhyo2UVihy/fNJe5bTW3ZV1ncuVjHnj6dGlam+TNQdyZvi
# nRB5EplbWeY7pQAkfcRoVXVs62rdqqf4d5fGL7M8lIDhmDRSUJvGo/FCE+e7yZoa
# 0aqg5tqmqWmnAOGKFuHKBAVWortoA0BEk/O+FQvs8RE4KDKYn6Gc6lcQb9P5Re7F
# WDnX13ZpkhzO3mvuA1Oh5DwbmEMyj/VB4w6dV5nukYaFCqScqBsLP4dbsj6YE3TM
# +7CdjnDDPf3i0yDM5jcfpWAY0CbGlUlvyu/96coL5fBh6HoXLTrHD/+4WIfF1j6G
# aZQvZml6HV0j4ffqyvVUQiPXyEENxl/PQ/67FVEGP297uWAwWlIFPOBDis2Jg1lH
# qNlTCOUJRC9UCTJHUaEVLtCNBY2cQFZzt/L8o9KfPHtFNuA3qFa9phBl0MQKU6AY
# 1IUkDP+sQlw/kNrDOSGdY9WoC5YNZbPrjkQdJqSeiTN7g0NWy1AkuGnsT5+Tgszc
# R27RYZAzCJNmRsMT2jdfXiPs5rhdhJa0CghEV6We+wKPuQJLevscK+TO7JvM87A3
# 1tyKY+h9gCJ2DykihSNQL4ClLYWigL4R4yKwFelt6GeFle0ISdvKd559gUbDqmlF
# LqHIypuzmsEAsSn9xR9vVLHsoZuIBnYVg69571JIQgN19l3zh7d8
# SIG # End signature block
