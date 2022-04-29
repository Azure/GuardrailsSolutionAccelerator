Disable-AzContextAutosave

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

$WorkSpaceID=Get-AutomationVariable -Name "WorkSpaceID" 
$LogType=Get-AutomationVariable -Name "LogType" 
$KeyVaultName=Get-AutomationVariable -Name "KeyVaultName" 
$GuardrailWorkspaceIDKeyName=Get-AutomationVariable -Name "GuardrailWorkspaceIDKeyName" 
$StorageAccountName=Get-AutomationVariable -Name "StorageAccountName" 
$ContainerName=Get-AutomationVariable -Name "ContainerName" 
$PBMMPolicyID=Get-AutomationVariable -Name "PBMMPolicyID"
$ResourceGroupName=Get-AutomationVariable -Name "ResourceGroupName"
$AllowedLocationPolicyId=Get-AutomationVariable -Name "AllowedLocationPolicyId"
$DepartmentNumber=Get-AutomationVariable -Name "DepartmentNumber"
$CBSSubscriptionName =Get-AutomationVariable -Name "CBSSubscriptionName"
$SecurityLAWResourceId=Get-AutomationVariable -Name "SecurityLAWResourceId"
$HealthLAWResourceId=Get-AutomationVariable -Name "HealthLAWResourceId"
#Set-AzAutomationVariable -Name LatestReportTime -Value (get-date).tostring("dd-MM-yyyy-hh:mm:ss") -Encrypted $false #-ResourceGroupName Guardrails-6eb08c2c -AutomationAccountName Guardrails-6eb08c2c
$ReportTime=(get-date).tostring("dd-MM-yyyy-hh:mm:ss")
#$=Get-AutomationVariable -Name "" 
#endregion Parameters 

# Connects to Azure using the Automation Account's managed identity
Connect-AzAccount -Identity
$SubID = (Get-AzContext).Subscription.Id
$tenantID = (Get-AzContext).Tenant.Id

[String] $WorkspaceKey = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $GuardrailWorkspaceIDKeyName -AsPlainText 
# Gets a token for the current sessions (Automation account's MI that can be used by the modules.)
[String] $GraphAccessToken = (Get-AzAccessToken -ResourceTypeName MSGraph).Token
# Grabs the secrets below from the Vault.
$BGA1=Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name BGA1 -AsPlainText 
$BGA2=Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name BGA2 -AsPlainText 

#region Guardrail module 1
"Check-ProcedureDocument 1"
Check-ProcedureDocument -StorageAccountName $StorageAccountName -ContainerName $ContainerName `
    -ResourceGroupName $ResourceGroupName -SubscriptionID $SubID `
    -DocumentName "BreakGlassAccountProcedure.txt" -ControlName $CtrName1 -ItemName "Break Glass account Procedure" `
    -LogType $LogType -WorkSpaceID  $WorkSpaceID -WorkspaceKey $WorkspaceKey

"Get-BreakGlassAccounts"
Get-BreakGlassAccounts -token $GraphAccessToken  -ControlName $CtrName1 -ItemName "Break Glass account Creation" `
    -FirstBreakGlassUPN $BGA1 -SecondBreakGlassUPN $BGA2 `
    -LogType $LogType -WorkSpaceID  $WorkSpaceID -WorkspaceKey $WorkspaceKey                
"Get-ADLicenseType"
Get-ADLicenseType -Token $GraphAccessToken -ControlName $CtrName1 -ItemName "AD License Type" `
    -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey 
"Get-UserAuthenticationMethod"
Get-UserAuthenticationMethod -token $GraphAccessToken -ControlName $CtrName1 -ItemName "MFA Enforcement" `
    -FirstBreakGlassEmail   $BGA1 `
    -SecondBreakGlassEmail  $BGA2 `
    -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey 
"Get-BreakGlassAccountLicense"
Get-BreakGlassAccountLicense -token $GraphAccessToken -ControlName $CtrName1 -ItemName "Microsoft 365 E5 Assignment" `
    -FirstBreakGlassUPN  $BGA1 `
    -SecondBreakGlassUPN  $BGA2 `
    -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey 
"Check-ProcedureDocument 2"
Check-ProcedureDocument -StorageAccountName $StorageAccountName -ContainerName $ContainerName `
    -ResourceGroupName $ResourceGroupName -SubscriptionID $SubID `
    -DocumentName "ConfirmBreakGlassAccountResponsibleIsNotTechnical.txt" -ControlName $CtrName1 -ItemName "Responsibility of break glass accounts must be with someone not-technical, director level or above" `
    -LogType $LogType -WorkSpaceID  $WorkSpaceID -WorkspaceKey $WorkspaceKey
"Get-BreakGlassOwnerinformation"
Get-BreakGlassOwnerinformation  -token $GraphAccessToken -ControlName $CtrName1 -ItemName "Break Glass Account Owners Contact information" `
    -FirstBreakGlassUPNOwner $BGA1 `
    -SecondBreakGlassUPNOwner $BGA2 `
    -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey 
#endregion Guardrail module 1
"Check-Policy"
Check-Policy -Token    $GraphAccessToken   -AADPrivRolesPolicyName "ABCPrivateRole" -AzureMFAPolicyName "ABCPrivateRole" 
"Check-ADDeletedUsers"
Check-ADDeletedUsers -Token $GraphAccessToken -ControlName $CtrName2 -ItemName "Remove deprecated accounts" `
    -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey
"Check-ExternalUsers"    
Check-ExternalUsers -Token $GraphAccessToken -ControlName $CtrName2 -ItemName "Remove External accounts" `
    -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey
"Check-MonitorAccountCreation"
Check-MonitorAccountCreation -Token $GraphAccessToken -DepartmentNumner $DepartmentNumber -ControlName $CtrName4 -ItemName "Monitor Account Creation" `
    -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey
"Verify-PBMMPolicy"
#Verify-PBMMPolicy -ControlName $CtrName5  -ItemName "PBMMPolicy Compliance" -PolicyID $PBMMPolicyID -LogType $LogType -WorkSpaceID $WorkSpaceID -WorkspaceKey $workspaceKey$CtrName6 = "GUARDRAIL 6: PROTECTION OF DATA-AT-REST"
$ItemName6="PROTECTION OF DATA-AT-REST"
$ItemName7="PROTECTION OF DATA-IN-TRANSIT"
Verify-PBMMPolicy -ControlName $CtrName5 -ItemName "PBMMPolicy Compliance" `
-CtrName6 $CtrName6 -ItemName6 $ItemName6 `
-CtrName7 $CtrName7 -ItemName7 $ItemName7 `
-PolicyID $PBMMPolicyID -LogType $LogType `
-WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey
"Verify-AllowedLocationPolicy"
Verify-AllowedLocationPolicy -ControlName $CtrName5 -ItemName "AllowedLocationPolicy" -PolicyID $AllowedLocationPolicyId -LogType $LogType -WorkSpaceID $WorkSpaceID -workspaceKey $workspaceKey
#Guardrail module 8
"Get-SubnetComplianceInformation" 
Get-SubnetComplianceInformation -ControlName $CtrName8 -WorkSpaceID $WorkSpaceID -workspaceKey $WorkspaceKey
#Guardrail module 9
"Get-VnetComplianceInformation"
Get-VnetComplianceInformation -ControlName $CtrName9 -WorkSpaceID $WorkSpaceID -workspaceKey $WorkspaceKey 
#Guradrail modul 10
"Check-CBSSensors"
Check-CBSSensors -SubscriptionName $CBSSubscriptionName  -TenantID $TenantID -ControlName $CtrName10 `
                 -WorkSpaceID $WorkSpaceID -workspaceKey $WorkspaceKey -LogType $LogType
#Guardrail Module 11
"Check-LoggingAndMonitoring"
Check-LoggingAndMonitoring -SecurityLAWResourceId $SecurityLAWResourceId `
-HealthLAWResourceId $HealthLAWResourceId `
-LogType $LogType `
-WorkSpaceID $WorkSpaceID -WorkspaceKey $WorkspaceKey `
-ControlName $CtrName11 `
-ReportTime $ReportTime 
#Guardrail module 12 
"Check-PrivateMarketPlaceCreaion"
Check-PrivateMarketPlaceCreaion -ControlName $Ctrname12  -WorkSpaceID $WorkSpaceID -workspaceKey $WorkspaceKey -LogType $LogType
#Confirm-CloudConsoleAccess -token $token.access_token -PolicyName 
