function Check-PrivateMarketPlaceCreation {
        param (
                [string] $ControlName, `
                [string] $WorkSpaceID, [string] $workspaceKey, [string] $LogType,
                [hashtable] $msgTable,
                [Parameter(Mandatory=$true)]
                [string]
                $ReportTime
        )
                
    
$IsCompliant=$false 
$Object = New-Object PSObject

try {
        [String] $PrivateMarketPlace=  Get-AzMarketplacePrivateStore -ErrorAction Stop  
}
catch {
    Add-LogEntry 'Error' "Failed to execute the 'Get-AzMarketplacePrivateStore'--ensure that the Az.Marketplace module is installed `
        and up to date; returned error message: $_" -workspaceGuid $WorkSpaceID -workspaceKey $WorkSpaceKey
    throw "Error: Failed to execute the 'Get-AzMarketplacePrivateStore'--ensure that the Az.Marketplace module is installed `
        and up to date; returned error message: $_" 
}


if($null -eq $PrivateMarketPlace){
        $Object| Add-Member NoteProperty -Name ComplianceStatus  -Value $IsCompliant
        $Object| Add-Member NoteProperty -Name Comments  -Value $msgTable.mktPlaceNotCreated
        $MitigationCommands = $msgTable.enableMktPlace
}
else {       
        $IsCompliant= $true
        $Object| Add-Member NoteProperty -Name ComplianceStatus  -Value $IsCompliant
        $Object| Add-Member NoteProperty -Name Comments  -Value "$($msgTable.mktPlaceCreated) - $($PrivateMarketPlace.PrivateStoreId)"
        $MitigationCommands = ""
}
$Object| Add-Member -MemberType NoteProperty -Name ControlName -Value $ControlName -Force
$Object| Add-Member -MemberType NoteProperty -Name ReportTime -Value $ReportTime -Force
$Object| Add-Member -MemberType NoteProperty -Name MitigationCommands -Value $MitigationCommands -Force
$Object| Add-Member -MemberType NoteProperty -Name ItemName -Value $msgTable.mktPlaceCreation -Force
$JsonObject = $Object | convertTo-Json  
Send-OMSAPIIngestionFile  -customerId $WorkSpaceID `
    -sharedkey $workspaceKey `
    -body $JsonObject `
    -logType $LogType `
    -TimeStampField Get-Date
}

