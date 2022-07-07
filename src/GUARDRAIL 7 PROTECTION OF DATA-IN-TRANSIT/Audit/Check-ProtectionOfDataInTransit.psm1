
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
        [string] $test,
        [Parameter(Mandatory=$true)]
        [string]
        $ReportTime
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
        ReportTime = $ReportTime
    }
    return $tempObject
}
function Test-ExemptionExists {
    param (
        [string] $ScopeId,
        [array]  $requiredPolicyExemptionIds
    )
    $exemptionsIds=(Get-AzPolicyExemption -Scope $ScopeId).Properties.PolicyDefinitionReferenceIds | Out-Null
    if ($null -ne $exemptionsIds)
    {
        foreach ($exemptionId in $exemptionsIds)
        {
            if ($exemptionId -in $requiredPolicyExemptionIds)
            {
                return $true
            }
        }
    }
    else {
        return $false
    }
    
}
function Check-StatusDataInTransit {
    param (
        [System.Object] $objList,
        [string] $objType, #subscription or management Group
        [array]  $requiredPolicyExemptionIds,
        [string] $PolicyID,
        [string] $ControlName,
        [string] $ItemName,
        [string] $LogType,
        [hashtable] $msgTable,
        [Parameter(Mandatory=$true)]
        [string]
        $ReportTime
    )   
    [PSCustomObject] $tempObjectList = New-Object System.Collections.ArrayList
    foreach ($obj in $objList)
    {
        #Write-Output "Checking $objType : $($obj.Name)"
        if ($objType -eq "subscription") {
            $tempId="/subscriptions/$($obj.Id)"
        }
        else {
            $tempId=$obj.Id
        }
        $AssignedPolicyList = Get-AzPolicyAssignment -scope $tempId -PolicyDefinitionId $PolicyID
        If ($null -eq $AssignedPolicyList -or (-not ([string]::IsNullOrEmpty(($AssignedPolicyList.Properties.NotScopesScope)))))
        {
            $Comment=$msgTable.pbmmNotApplied 
            $ComplianceStatus=$false
        }
        else {
            #PBMM is applied and not excluded. Testing if specific policies haven't been excluded.
            if (Test-ExemptionExists -ScopeId $tempId -requiredPolicyExemptionIds $gr7RequiredPolicies)
            { # boolean, exemption for gr6 required policies exists.
                $ComplianceStatus=$false
                $Comment=$msgTable.grexemptionFound -f $obj.Id,$objType
            }
            else {
                $ComplianceStatus=$true
                $Comment=$msgTable.isCompliant 
                #No exemption exists. All good.
            }
        }
        if ($obj.DisplayName -eq $null)
        {
            $DisplayName=$obj.Name
        }
        else {
            $DisplayName=$obj.DisplayName
        }
        $c=new-customObject -Type $objType -Id $obj.Id -Name $obj.Name -DisplayName $DisplayName `
                -CtrlName $ControlName `
                -ComplianceStatus $ComplianceStatus `
                -ItemName $ItemName `
                -Comments $Comment`
                -ReportTime $ReportTime
        $tempObjectList.add($c)| Out-Null
    }
    return $tempObjectList
}
function Verify-ProtectionDataInTransit {
    param (
            [string] $ControlName,
            [string] $ItemName,
            [string] $PolicyID, `
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
    [PSCustomObject] $FinalObjectList = New-Object System.Collections.ArrayList
    $grRequiredPolicies=@("FunctionAppShouldOnlyBeAccessibleOverHttps","WebApplicationShouldOnlyBeAccessibleOverHttps", "ApiAppShouldOnlyBeAccessibleOverHttps", "OnlySecureConnectionsToYourRedisCacheShouldBeEnabled","SecureTransferToStorageAccountsShouldBeEnabled")
    #Check management groups
    $objs=get-azmanagementgroup
    [string]$type = "Management Group"  
    $FinalObjectList+=Check-StatusDataInTransit -objList $objs -objType $type -requiredPolicyExemptionIds $grRequiredPolicies -PolicyID $PolicyID `
    -ReportTime $ReportTime -ItemName $ItemName -LogType $LogType -msgTable $msgTable -ControlName $ControlName
    #Check Subscriptions
    $objs=Get-AzSubscription
    [string]$type = "subscription"
    $FinalObjectList+=Check-StatusDataInTransit -objList $objs -objType $type -requiredPolicyExemptionIds $grRequiredPolicies -PolicyID $PolicyID `
    -ReportTime $ReportTime -ItemName $ItemName -LogType $LogType -msgTable $msgTable  -ControlName $ControlName
    
    #Writes data
    $FinalObjectList #| convertto-json -Depth 3
    if ($FinalObjectList.Count -gt 0)
    {
        $JsonObject = $FinalObjectList | convertTo-Json -Depth 3
        #$JsonObject
        Send-OMSAPIIngestionFile  -customerId $WorkSpaceID `
        -sharedkey $workspaceKey `
        -body $JsonObject `
        -logType $LogType `
        -TimeStampField Get-Date
    }
}