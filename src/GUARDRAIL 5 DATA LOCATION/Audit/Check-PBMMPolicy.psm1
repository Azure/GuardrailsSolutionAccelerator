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
# MIInvAYJKoZIhvcNAQcCoIInrTCCJ6kCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDKX+l7CFAfgla1
# o68UQgKVTp+oL0enI5KEVaZnUzAqy6CCDYUwggYDMIID66ADAgECAhMzAAACU+OD
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGY0wghmJAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAJT44Pelt7FbswAAAAA
# AlMwDQYJYIZIAWUDBAIBBQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINjF
# 8Z9p/vCv8wL9piACwYuhREdie7FU/0cQ4O7yG1k1MEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQu
# Y29tIDANBgkqhkiG9w0BAQEFAASCAQBeGRfYq3Afe41+I0OCzLAfpbxng5O6kTUH
# OGL8qJbXOVqzYVt0VzHeHQfjvQGCJsf+lNa2L6xLTrAwoims3yaRgwZZmDkylq9i
# BBzhq08ZvLUUbi1aH/rDAf2nk8WxVb+JKuw+FmJ3EwFe+ZRNfHBRlrU4Qz68eTfO
# vhGBI6KZvm+pYWOfNDpYGDTdsFDt4Xr0UhvE30K1TSMtM/XHM0sRFmyLLEvxGI8v
# /FWXCq7Q+I6uj37vpm73H0XlGaWkbudbWUvhCvp0X/TBdztG/IiIXI5k5LtTTZK+
# A8UeKlj9ni3+Xnu8gQdAOjp1qWSfDFQER4RFXzO6Di4gRijND3k7oYIXFTCCFxEG
# CisGAQQBgjcDAwExghcBMIIW/QYJKoZIhvcNAQcCoIIW7jCCFuoCAQMxDzANBglg
# hkgBZQMEAgEFADCCAVgGCyqGSIb3DQEJEAEEoIIBRwSCAUMwggE/AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIFS4AaquOc3U575kNIq5NJfUqlbYZ+Rt
# WIHxXVNHpvjsAgZiF5lPtfkYEjIwMjIwNDIxMTgyMDIyLjM1WjAEgAIB9KCB2KSB
# 1TCB0jELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UE
# CxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQL
# Ex1UaGFsZXMgVFNTIEVTTjpEMDgyLTRCRkQtRUVCQTElMCMGA1UEAxMcTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCEWUwggcUMIIE/KADAgECAhMzAAABj/NR
# qOtact3MAAEAAAGPMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMB4XDTIxMTAyODE5Mjc0NloXDTIzMDEyNjE5Mjc0NlowgdIxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jv
# c29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhhbGVz
# IFRTUyBFU046RDA4Mi00QkZELUVFQkExJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCZ
# Vz7+tc8XHoWTj4Kkuu5sOstNrdC4AdFVe7L7OzFfCSiCRPRr5da4FpvAfKqPxFGJ
# lBC929s6rk1ETE54eJoK2RSxDTYRIB70LP6WgE22x8Krzjq7ei1YcImWqS8OtKvu
# YwGrBxFjtx+EAZ8u+WkxKiOgCeTtF6P6NwmdjEh43fgXeH0nAA1jfrSgZgIhLuks
# 6ixZX5vG6D26JNlgT9dyXJg0Xpd3Nn/MP/hTmnFPgxlCbMEa8Oz7xwN0D+y1l+P+
# vL6LRdRg0U+G6pz5QqTCb9c0cH4IOwZCX5lLQZxtRS6fhU9OEcmbqZEDAvnLzOm1
# YQihxtN5FJOZmdRraJgfYQ4FXt4KPHRJ1vqQtzXF0VFyQN5AZHgnXIXLJu5mxQ/z
# HR06wQSgtC46G4qUMtASDsPpnGZkmdLwHTd7CT9KlUuqxvrpTarIXgHAO3W5mSMR
# nt+KcihSBLPgHt9Ytgh47Y4JjEgTRe/CxWin0+9NdNm0Y/POYdTvncZqsrK4zqhr
# +ppPNi+sB9RvspiG9VArEZQ+Qv354qIzsbSp6ckIWtfNk/BFahxwBHfc+E0S67PM
# pkUngN5pMIuD/y4rRDhCMVF5/mfgf7YpAgSJtnvMh4FfeOCysgJvPNKbRBfdJFWZ
# kf/8CqnxjGTBygjVYIGLO/zjP16rBEF1Dgdhw1tAwwIDAQABo4IBNjCCATIwHQYD
# VR0OBBYEFPMG5nRrrknO4qHOhZvbl/s3I3G8MB8GA1UdIwQYMBaAFJ+nFV0AXmJd
# g/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0El
# MjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGlt
# ZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQCMAAwEwYDVR0l
# BAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQELBQADggIBAM1/06j3PKELmfWMLyJT
# s0ljf0WLOOHFnAlslj9i3CfremUyVNJoGl6tqfnrp+5GiMYlK/cTBmz5Gu45TZP9
# lEPHhUd6wse1yUTwaYwzWpMxpk8vwjYWtGZ/k6ingapzE100QIEKVVmafQrMV08y
# pFrn/RHoKaComHSa68iaKSAe5u+iGxq88TLIdBr3gcPj8s0p39ghoIoo/P1IDl8B
# rimFDgS/PZq5j1JSW4h3kwr0flyNZXAHEK9gAP7UJb3PsayEmU2OoG9a0o7onQB6
# Z+DrPbyDupzsb+0K2uUfj/LbvL6y27BZc2/B2xJ3WW8HgzrcC4yX1inpq79cWScb
# Mk8Xqf+5ZHomFC/OHjQguB5OEuZiF/zP5oNvivY4EsbU/YHpoJNbZhCS3tOlSfMj
# RwoavbXcJsq0aT844gdKwM7FqyZ4Yn4WJQkKJXXnCHdplP9VP8+Qv0TiEMEDAa3j
# 0bzyBII7TH2N90NlZ1YZsQteVKYDcQ/h5NirtGuiVjTgbx8a0XSnO5m7jcDb3Noj
# 2Uivm6UpHPwShAdTpy7Q/FTDQH0fxwCS9DFoy6ZFn/h8Juo1vhNw+Q9xY4jbhBiW
# +lu1P2nfV+VgSWZznCMamUCTL+eQlxPQdkQ1d6fFa0++3iByiqml4k8DdL/UPnso
# vfrrt6kivTJXb3QTai1lsBbwMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAA
# AAAAFTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUg
# QXV0aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1N
# aWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQAD
# ggIPADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2
# AX9sSuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpS
# g0S3po5GawcU88V29YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2r
# rPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k
# 45GPsjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSu
# eik3rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09
# /SDPc31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR
# 6L8FA6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxC
# aC4Q6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaD
# IV1fMHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMUR
# HXLvjflSxIUXk8A8FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMB
# AAGjggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQq
# p1L+ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ
# 6XIwXAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRt
# MBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBB
# MAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP
# 6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWlj
# cm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2
# LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMu
# Y3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2
# Pk5HZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03d
# mLq2HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVtI1Tk
# eFN1JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kp
# icO8F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKp
# W99Jo3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrY
# UP4KWN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QB
# jloZkWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkB
# RH58oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0V
# iY1w/ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq
# 0Z4+7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1V
# M1izoXBm8qGCAtQwggI9AgEBMIIBAKGB2KSB1TCB0jELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQg
# T3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpEMDgy
# LTRCRkQtRUVCQTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZaIjCgEBMAcGBSsOAwIaAxUAPk0vggR250gHB0agJpXRYFtBmmqggYMwgYCkfjB8
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1N
# aWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIFAOYL
# 59EwIhgPMjAyMjA0MjEyMjI1MjFaGA8yMDIyMDQyMjIyMjUyMVowdDA6BgorBgEE
# AYRZCgQBMSwwKjAKAgUA5gvn0QIBADAHAgEAAgIRQTAHAgEAAgITXTAKAgUA5g05
# UQIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6Eg
# oQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAABsZHGACUyVw27ZpQ0u4Jyu
# CvXzMQtAI7W8mXQwFtkS9cs5BgkB8dfSvguh/ed+JcCbPff/Pw06OXVW08pNP1LC
# lEkXJeh9rYwah38YiK+b4Yxx2GbeuO0E8y1o8WWMPJKbF/0I/ld13YMDFNBOIoMn
# ikpopzW+ueGXd6/e/O6gMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgUENBIDIwMTACEzMAAAGP81Go61py3cwAAQAAAY8wDQYJYIZIAWUDBAIBBQCg
# ggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQg
# Ms1zRyj5OBjFRXa8N0Vh1dSnhNGNBMX3zAbyqxeXn4cwgfoGCyqGSIb3DQEJEAIv
# MYHqMIHnMIHkMIG9BCCXcgVP4sbGC5WOIqbbYi2Y7p0UNZbydKG7o7qDzIXHHzCB
# mDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
# BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAABj/NRqOta
# ct3MAAEAAAGPMCIEINlz+amGpoF2jChxwJohK5m5NDNr1qv42bKBOzgun+UjMA0G
# CSqGSIb3DQEBCwUABIICAC4NVu4qyc4qryxV9G/dZelM48IXwrDoSN0Z0hrzqIhb
# t4frQDUsdCEAw/lNjwMeCuvs343FTXAp7du+6X6+oSGdinUAegc0n/vAynFyBCsG
# e7Z+BYdmpOQT45Sj8+Kb/pi0cMb1nhhNp/ImQTb47ZXo4ScVynHVISiNp38I0IK4
# /SozOFP+KGscJviq6ChwJCx+XOcQg/V/2gyeqoxc99WPLHdFSUEhC0KxapZnXR7W
# LUA1bL5C5viphm4muVcRo4Uqy83JaBiGkcFY8QNrbcfDcwkVWl+6TpWAXhIki3YJ
# F6b+FD4/ITvtXZmP1qQ8zh9prv901zlSHoM8tn+P/PsGhQHO56/gJS917r/UcxNi
# WvTWwCJPZ+5SDK9odpCxcCrB5rz5+yL1wouAhOb6bZHqAd/tdDumsbpzgMbtSnpX
# rWHWM63SPvq5Aukz/hjqGdkgQnaX/MYeTekDnxCDx9SbgGqG5Th33je9axwnk7Og
# +d/38xsCUJrjhQ9pnQuZLg/RfW7rYfsfn3zYvwgOEIwni19m+EKTcOxi6zFh6LVD
# ohPtOZW8hsxemZXhSMZhjhax2xD91qCVhx1by533QDL9cfCFRt7BPbxCDmdb1cdj
# NfjtB+bH7Jp84a3AQwB6MOZuAgvWMLHuQafRUeV8EgynftahD96LOX+2xA49ds/5
# SIG # End signature block
