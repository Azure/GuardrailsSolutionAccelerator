param (
        [Parameter(Mandatory=$true)]
        [string]
        $configFilePath,
        [Parameter(Mandatory=$false)]
        [string]
        $storageaccountName
    )
    
import-module .\blob-functions.psm1
$config=get-content $configFilePath | convertfrom-json

$resourcegroup=$config.resourcegroup
$autoMationAccountName=$config.autoMationAccountName

$context=New-AzStorageContext -StorageAccountName $storageaccountName -StorageAccountKey (Get-AzStorageAccountKey -ResourceGroupName $resourcegroup -Name $storageaccountName)[0].Value
$blobs=get-blobs -resourceGroup $resourceGroup -storageAccountName $storageaccountName
Write-output "Importing $($blobs.Count) modules."
foreach ($blob in $blobs)
{
    Write-verbose "Importing module $($blob.Name)"
    [uri]$uri=New-AzStorageBlobSASToken -BlobBaseClient $blob.BlobBaseClient -CloudBlob $blob.ICloudBlob -Permission r -ExpiryTime (get-date).AddMinutes(15) -FullUri -Context $context
    Import-AzAutomationModule -ResourceGroupName $resourceGroup -AutomationAccountName $autoMationAccountName -ContentLinkUri $uri -Name $blob.Name.replace(".zip","")
}