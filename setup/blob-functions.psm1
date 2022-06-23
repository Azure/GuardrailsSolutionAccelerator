#region Functions
function copy-toBlob  {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $FilePath,
        [Parameter(Mandatory=$true)]
        [string]
        $storageaccountName,
        [Parameter(Mandatory=$true)]
        [string]
        $resourcegroup,
        [Parameter(Mandatory=$true)]
        [string]
        $containerName,
        [Parameter(Mandatory=$false)]
        [switch]
        $force
    )
    try {
        $saParams = @{
            ResourceGroupName = $resourcegroup
            Name = $storageaccountName
        }
        $scParams = @{
            Container = $containerName
        }
        $bcParams = @{
            File = $FilePath
            Blob = ($FilePath | Split-Path -Leaf)
        }
        if ($force)
        {Get-AzStorageAccount @saParams | Get-AzStorageContainer @scParams | Set-AzStorageBlobContent @bcParams -Force}
        else {Get-AzStorageAccount @saParams | Get-AzStorageContainer @scParams | Set-AzStorageBlobContent @bcParams}
    }
    catch
    {
        Write-Error $_.Exception.Message
    }
}
function get-blobs  {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $storageaccountName,
        [Parameter(Mandatory=$true)]
        [string]
        $resourcegroup
    )
    $psModulesContainerName="psmodules"
    try {
        $saParams = @{
            ResourceGroupName = $resourcegroup
            Name = $storageaccountName
        }

        $scParams = @{
            Container = $psModulesContainerName
        }
        return (Get-AzStorageAccount @saParams | Get-AzStorageContainer @scParams | Get-AzStorageBlob)
    }
    catch
    {
        Write-Error $_.Exception.Message
    }
}

function read-blob {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $FilePath,
        [Parameter(Mandatory=$true)]
        [string]
        $storageaccountName,
        [Parameter(Mandatory=$true)]
        [string]
        $resourcegroup,
        [Parameter(Mandatory=$true)]
        [string]
        $containerName,
        [Parameter(Mandatory=$false)]
        [switch]
        $force
    )
    $Context=(Get-AzStorageAccount -ResourceGroupName $resourcegroup -Name $storageaccountName).Context
    $blobParams = @{
        Blob        = 'modules.json'
        Container   = $containerName
        Destination = $FilePath
        Context     = $Context
      }
      Get-AzStorageBlobContent @blobParams
      

}
#endregion