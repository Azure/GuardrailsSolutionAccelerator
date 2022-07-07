function Check-CBSSensors {
    param (
        [string] $SubscriptionName , [string] $TenantID , [string] $ControlName, `
        [string] $WorkSpaceID, [string] $workspaceKey, [string] $LogType, [string] $ItemName,  [hashtable] $msgTable,
        [Parameter(Mandatory=$true)]
        [string]
        $ReportTime
    )

    $IsCompliant = $true 
    $SubsFound=""
    $Object = New-Object PSObject

    $Object | Add-Member -MemberType NoteProperty -Name ControlName  -Value $ControlName

    $FirstTokenInTenantID = $TenantID.Split("-")[0]

    $CBSResourceNames=@("cbs-" + $FirstTokenInTenantID)
    $CBSResourceNames+="cbs-" + $FirstTokenInTenantID + "-CanadaCentral"
    $CBSResourceNames+="cbs-" + $FirstTokenInTenantID + "-CanadaEast"
    $CBSResourceNames+="cbs-vault-" + $FirstTokenInTenantID
    $CBSResourceNames+=$FirstTokenInTenantID
    Write-Output $CBSResourceNames
    $sub=Get-AzSubscription | Where-Object {$_.State -eq 'Enabled' -and $_.Name -eq $SubscriptionName}
    if ($null -ne $subs)
    {
        Set-AzContext -Subscription $sub

        foreach ($CBSResourceName in $CBSResourceNames)
        {
            Write-output "Searching for CBS Sensor: $CBSResourceName"
            if ([string]::IsNullOrEmpty($(Get-AzResource -Name $CBSResourceName)))
            {
                Write-Output "Missing $CBSResourceName"
                $IsCompliant = $false 
            }
        }
        if ($IsCompliant)
        {
            $object | Add-Member -MemberType NoteProperty -Name Comments -Value "$($msgTable.cbssCompliant) $SubscriptionName)"
            $MitigationCommands = "N/A."
        }
        else {
            $Object | Add-Member -MemberType NoteProperty -Name Comments -Value $Comment2            
            $MitigationCommands = "Contact CBS to deploy sensors."
        }
    }
    else {
        $IsCompliant = $false
        $Object | Add-Member -MemberType NoteProperty -Name Comments -Value $msgTable.cbsSubDoesntExist
        $MitigationCommands = "$($msgTable.cbssMitigation)" -f $SubscriptionName
    }
    $object | Add-Member -MemberType NoteProperty -TypeName DateTime -Name ReportTime -Value $ReportTime
    $object | Add-Member -MemberType NoteProperty -Name ComplianceStatus -Value $IsCompliant
    $object | Add-Member -MemberType NoteProperty -Name MitigationCommands -Value $MitigationCommands
    $object | Add-Member -MemberType NoteProperty -Name ItemName -Value $ItemName
    $JsonObject = convertTo-Json -inputObject $Object 
        
    Send-OMSAPIIngestionFile -customerId $WorkSpaceID `
       -sharedkey $workspaceKey `
       -body $JsonObject `
       -logType $LogType `
       -TimeStampField Get-Date         
}

