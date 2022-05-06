# Guardrails Solution Accelerator
# Update script
#
param (
    [Parameter(Mandatory=$true)]
    [string]
    $configFilePath
)
$newversion='1.1'
$newWorkbookVersion='1.2'
$newReleaseDate='2022-05-06'
$tempFolder='/tmp/modules'
if (!(get-childitem $tempFolder)) {
    mkdir $tempFolder
}
$modulesFolder="../psmodules"
Write-Output "Reading Config file:"
try {
    $config=get-content $configFilePath | convertfrom-json
}
catch {
    "Error reading config file."
    break
}
if ($env:ACC_TID) {
    $tenantIDtoAppend="-"+$($env:ACC_TID).Split("-")[0]
}
else {
    $tenantIDtoAppend="-"+$(((get-azcontext).Tenant).Id).Split("-")[0]
}
$subscriptionId=(get-azcontext).Subscription.Id
$resourcegroup=$config.resourcegroup+$tenantIDtoAppend
$logAnalyticsworkspaceName=$config.logAnalyticsworkspaceName+$tenantIDtoAppend
$autoMationAccountName=$config.autoMationAccountName+$tenantIDtoAppend

#Import new runbook
# Add version test, based on Tags.

Import-AzAutomationRunbook -Name 'main' -Path ./main.ps1 -AutomationAccountName $autoMationAccountName -ResourceGroupName $resourcegroup `
 -Force -Type PowerShell -Description "Main Guardrails module V.$newversion" -Tags @{version=$newversion} -Published 
#expand all modules to temp folder

Get-ChildItem "$modulesFolder/*.zip" | ForEach-Object {Expand-Archive -path $_.FullName -DestinationPath $tempFolder -Force}
#List all modules in automation account
#get each version
# find module manifest
$modules=Get-AzAutomationModule -AutomationAccountName $autoMationAccountName -ResourceGroupName $resourceGroup
foreach ($m in $modules) { 
    $manifest=Get-ChildItem -Path /tmp/modules | ? {$_.basename -eq $m.name} | ? {$_.extension -eq '.psd1'}
    if ($manifest) {
        $newModuleVersion=($manifest| Select-String 'ModuleVersion').Tostring().Split("'")[1]
        if ($m.Version -eq $newModuleVersion) {
            "No Update Needed. Module: $m.Name.Old Version: $($m.Version). New Version: $newModuleVersion"
        }
        else {
            "Update required: Module: $m.Name. Old Version: $($m.Version). New Version: $newModuleVersion" 
        }
    }
}
#Workbook update
$workbookname=(get-azresource -ResourceGroupName $resourcegroup -ResourceType 'Microsoft.Insights/workbooks').Name
$parameters=@{
    subscriptionId=$subscriptionId
    logAnalyticsWorkspaceName=$logAnalyticsworkspaceName
    workbookNameGuid=$workbookname
    newWorkBookVersion=$newWorkbookVersion
}
#Deploys specific template with new workbook and other updates.
New-AzResourceGroupDeployment -TemplateFile ./update.bicep -TemplateParameterFile ./update.bicep -ResourceGroupName $resourceGroup -templateParameterObject $parameters

