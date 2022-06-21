Disable-AzContextAutosave

#Standard variables
$WorkSpaceID=Get-AutomationVariable -Name "WorkSpaceID" 
$LogType=Get-AutomationVariable -Name "LogType" 
$KeyVaultName=Get-AutomationVariable -Name "KeyVaultName" 
$GuardrailWorkspaceIDKeyName=Get-AutomationVariable -Name "GuardrailWorkspaceIDKeyName" 
$ResourceGroupName=Get-AutomationVariable -Name "ResourceGroupName"
$ReportTime=(get-date).tostring("dd-MM-yyyy-hh:mm:ss")
$StorageAccountName=Get-AutomationVariable -Name "StorageAccountName" 
$Locale=Get-AutomationVariable -Name "GuardRailsLocale" 

Add-LogEntry 'Information' "Starting execution of main runbook" -workspaceGuid $WorkSpaceID -workspaceKey $WorkSpaceKey

# Connects to Azure using the Automation Account's managed identity
Connect-AzAccount -Identity
$SubID = (Get-AzContext).Subscription.Id
$tenantID = (Get-AzContext).Tenant.Id

Write-Output "Reading configuration file."
read-blob -FilePath ".\modules.json" -resourcegroup $ResourceGroupName -storageaccountName $StorageAccountName -containerName "configuration"
try {
    $modulesList=Get-Content .\modules.json
}
catch {
    Write-Error "Couldn't find module configuration file."    
    break
}
$modules=$modulesList | convertfrom-json

Write-Output "Found $($modules.Count) modules."

[String] $WorkspaceKey = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $GuardrailWorkspaceIDKeyName -AsPlainText 
# Gets a token for the current sessions (Automation account's MI that can be used by the modules.)
[String] $GraphAccessToken = (Get-AzAccessToken -ResourceTypeName MSGraph).Token

# This loads the file containing all of the messages in the culture specified in the automation account variable "GuardRailsLocale"
Import-LocalizedData -BindingVariable "msgTable" -UICulture $Locale -FileName "GR-ComplianceChecks-Msgs" -BaseDirectory "C:\Modules\User\GR-ComplianceChecks" #-ErrorAction SilentlyContinue

foreach ($module in $modules)
{
    $NewScriptBlock = [scriptblock]::Create($module.Script)
    Write-Output "Processing Module $($module.modulename)" -ForegroundColor Yellow
    $variables=$module.variables
    $secrets=$module.secrets
    $localVariables=$module.localVariables
    $vars = [PSCustomObject]@{}          
    if ($variables -ne $null)
    {
        foreach ($v in $variables)
        {
            $tempvarvalue=Get-AutomationVariable -Name $v.value
            $vars | Add-Member -MemberType Noteproperty -Name $($v.Name) -Value $tempvarvalue
        }      
    }
    if ($secrets -ne $null)
    {
        foreach ($v in $secrets)
        {
            $tempvarvalue=Get-AzKeyVaultSecret -VaultName $KeyVaultName -AsPlainText -Name $v.value
            $vars | Add-Member -MemberType Noteproperty -Name $($v.Name) -Value $tempvarvalue
        }
    }
    if ($localVariables -ne $null)
    {
        foreach ($v in $localVariables)
        {
            $vars | Add-Member -MemberType Noteproperty -Name $($v.Name) -Value $v.value
        }
    }
    $vars
    Write-host $module.Script
    $NewScriptBlock.Invoke()
}
break

