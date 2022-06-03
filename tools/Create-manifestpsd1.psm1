#New-ModuleManifest -Path .\Check-BreackGlassAccountOwnersInformation.psd1 -Author "FastTrack for Azure Team" -CompanyName Microsoft -ModuleVersion 1.0.0 -Tags "GOC 30 days Guardrails"
function Generate-Manifest {
    [CmdletBinding()]
    param (
    
        [String] $DirectoryPath, 
        [String] $ModuleVersion,
        [Parameter(Mandatory=$true)]
        [string][string] $ModulesFolder,
        [switch] $interactive
    )
    if ([string]::IsNullOrEmpty($DirectoryPath))
    {
        $DirectoryPath="."
    }
    if ($interactive)
    {
        $PSM1Files = Get-ChildItem -Path $($DirectoryPath + "\*")-include *.psm1 -File -Recurse | Select-Object LastWriteTime, Name,FullName, BaseName, Directory | Out-GridView -PassThru
    }
    else {
        $PSM1Files = Get-ChildItem -Path $($DirectoryPath + "\*")-include *.psm1 -File -Recurse
    }
    $overriteAll=$false
    Write-Output "Found $($PSM1Files.count)"
    $currentFolder=(pwd).Path
    foreach ($file in $PSM1Files) {
        #change to folder containing the file
        "Working on $($file.FullName)"
        Set-Location -Path $file.Directory
        pwd
        #look for manifest. If exists, skip creation
        $manifestFileName=$($file.BaseName+".psd1")
        if (Get-ChildItem -Path $manifestFileName -ErrorAction SilentlyContinue)
        {
            "Using existing manifest."
        }
        else {
            "File $manifestFileName not found."
            "Creating new manifest."
            New-ModuleManifest -Path $manifestFileName -Author "FastTrack for Azure Team" -CompanyName Microsoft -ModuleVersion $ModuleVersion -Tags "GOC 30 days Guardrails" `
                               -RootModule $(".\"+$file.Name) -FunctionsToExport '*' -VariablesToExport '*'  -Confirm                                    
        }
        #create zip file from both files in the Modules Target folder.
        
        if ($PSVersionTable.Platform -ne 'Unix')
        {
            $targetFileName="$($ModulesFolder)\$($file.BaseName).zip"
            "Creating $targetFileName file."
            if ((get-item $targetFileName -ErrorAction SilentlyContinue) -and !$overriteAll)
            {
                Write-Output "File $targetFileName already exists. Overwrite? (Y/N/A)"
                $answer=(Read-Host).ToUpper()
                if ($answer -eq 'Y')
                {
                    Compress-Archive -Path ".\$($file.BaseName).*" -DestinationPath $targetFileName -Force
                }
                else {
                    if ($answer -eq 'A') {
                        $overriteAll = $true
                    }
                    else {
                        "Skipping..."
                    }
                }
            }
            else {
                Compress-Archive -Path ".\$($file.BaseName).*" -DestinationPath $targetFileName -Force
            }
        }
        else {
            $targetFileName="$($ModulesFolder)/$($file.BaseName).zip"
            "Creating $targetFileName file."
            if ((get-item $targetFileName -ErrorAction SilentlyContinue) -and !$overriteAll)
            {
                Write-Output "File $targetFileName already exists. Overwrite? (Y/N/A)"
                $answer=(Read-Host).ToUpper()
                if ($answer -eq 'Y')
                {
                    Compress-Archive -Path ".\$($file.BaseName).*" -DestinationPath $targetFileName -Force
                }
                else {
                    if ($answer -eq 'A') {
                        $overriteAll = $true
                    }
                    else {
                        "Skipping..."
                    }
                }
            }
            else {
                Compress-Archive -Path "./$($file.BaseName).*" -DestinationPath $targetFileName -Force
            }
        }
    }
    Set-Location -Path $currentFolder
}
