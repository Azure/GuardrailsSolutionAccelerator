<#
.SYNOPSIS
   the module will verify if the manager information for both Break Glass Accounts is populated
   results are sent to the identified log analytics workspace.

.DESCRIPTION
 the module will verify if the manager information for both Break Glass Accounts is populated
   results are sent to the identified log analytics workspace.
.PARAMETER Name
        FirstBreakGlassUPNOwner :- The First Break Glass Account UPN 
        SecondBreakGlassUPNOwner :- The second Break Glass Account UPN
        ControlName :-  GUARDRAIL 1 PROTECT ROOT  GLOBAL ADMINS ACCOUNT
        ItemName, 
        WorkSpaceID : Workspace ID to ingest the logs 
        WorkSpaceKey: Workspace Key for the Workdspace 
        LogType: GuardrailsCompliance, it will show in log Analytics search as GuardrailsCompliance_CL
#>
function Start-ComplianceChecks {
    param (
        [string] $Empty
    )

    # Empty Module

}