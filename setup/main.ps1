Disable-AzContextAutosave

#Import-LocalizedData -BaseDirectory werwer -BindingVariable "msgTable" -FileName qweer -UICulture "en-CA"

#region Parameters 
$CtrName1 = "GUARDRAIL 1: PROTECT ROOT / GLOBAL ADMINS ACCOUNT"
$CtrName2 = "GUARDRAIL 2: MANAGEMENT OF ADMINISTRATIVE PRIVILEGES"
$CtrName3 = "GUARDRAIL 3: CLOUD CONSOLE ACCESS"
$CtrName4 = "GUARDRAIL 4: ENTERPRISE MONITORING ACCOUNTS"
$CtrName5 = "GUARDRAIL 5: DATA LOCATION"
$CtrName6 = "GUARDRAIL 6: PROTECTION OF DATA-AT-REST"
$CtrName7 = "GUARDRAIL 7: PROTECTION OF DATA-IN-TRANSIT"
$CtrName8 = "GUARDRAIL 8: NETWORK SEGMENTATION AND SEPARATION"
$CtrName9 = "GUARDRAIL 9: NETWORK SECURITY SERVICES"
$CtrName10 = "GUARDRAIL 10: CYBER DEFENSE SERVICES"
$CtrName11 = "GUARDRAIL 11: LOGGING AND MONITORING"
$CtrName12 = "GUARDRAIL 12: CONFIGURATION OF CLOUD MARKETPLACES"

#Standard variables
$WorkSpaceID=Get-AutomationVariable -Name "WorkSpaceID" 
$LogType=Get-AutomationVariable -Name "LogType" 
$KeyVaultName=Get-AutomationVariable -Name "KeyVaultName" 
$GuardrailWorkspaceIDKeyName=Get-AutomationVariable -Name "GuardrailWorkspaceIDKeyName" 
$ResourceGroupName=Get-AutomationVariable -Name "ResourceGroupName"
$ReportTime=(get-date).tostring("dd-MM-yyyy-hh:mm:ss")
$StorageAccountName=Get-AutomationVariable -Name "StorageAccountName" 

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

foreach ($module in $modules)
{
    $NewScriptBlock = [scriptblock]::Create($module.Script)
    Write-Output "Processing Module $($module.modulename)" -ForegroundColor Yellow
    $variables=$module.variables
    $secrets=$module.secrets
    $localVariables=$module.$localVariables
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

