
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

$modules=Get-Content ./test.json | ConvertFrom-Json
foreach ($module in $modules)
{
    $NewScriptBlock = [scriptblock]::Create($module.Script)
    Write-host "Processing Module $($module.modulename)" -ForegroundColor Yellow
    $variables=$module.variables
    if ($variables -ne $null)
    {
        $vars = [PSCustomObject]@{}          
        foreach ($v in $variables)
        {
            $vars | Add-Member -MemberType Noteproperty -Name $($v.Name) -Value "get variable with name: $($v.value)"
        }
        $vars
    }
    
    Write-host $module.Script
    #$NewScriptBlock.Invoke()
}
