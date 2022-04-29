param (
        [Parameter(Mandatory=$false)]
        [string]
        $storageaccountName="guardrail",
        [Parameter(Mandatory=$false)]
        [string]
        $resourcegroup="Guardrail",
        [Parameter(Mandatory=$false)]
        [switch]
        $force
    )
import-module .\blob-functions.psm1
Write-output "Uploading modules to storage account."
if ($force) 
    {Get-Item "..\modules\*.zip" | ForEach-Object { copy-toBlob -FilePath $_.FullName -storageaccountName $storageaccountName -resourcegroup $resourcegroup -Force} }
else  
    {Get-Item "..\modules\*.zip" | ForEach-Object { copy-toBlob -FilePath $_.FullName -storageaccountName $storageaccountName -resourcegroup $resourcegroup } }
