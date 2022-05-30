#Future Params:
#Security
function get-apiLinkedServicesData {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $subscriptionId,
        [Parameter(Mandatory=$true)]
        [string]
        $resourceGroup,
        [Parameter(Mandatory=$true)]
        [string]
        $LAWName
    )
    $token=(Get-AzAccessToken).Token
    $apiUrl="https://management.azure.com/subscriptions/$subscriptionId/resourcegroups/$resourceGroup/providers/Microsoft.OperationalInsights/workspaces/$LAWName/linkedServices?api-version=2020-08-01"
    $Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $apiUrl -Method Get
    return $Data
}
function get-tenantDiagnosticsSettings {
    #AadGraph, AnalysisServices, Arm, Attestation, Batch, DataLake, KeyVault, MSGraph, OperationalInsights, ResourceManager, Storage, Synapse
    $token=(Get-AzAccessToken -ResourceTypeName Arm).Token

    #$apiUrl="https://graph.microsoft.com/beta/auditLogs/directoryAudits"
    $apiUrl = "https://management.azure.com/providers/microsoft.aadiam/diagnosticSettings?api-version=2017-04-01-preview"
    $Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $apiUrl -Method Get
    return $data.value.properties
}
function Check-LoggingAndMonitoring {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $SecurityLAWResourceId,
        [Parameter(Mandatory=$true)]
        [string]
        $HealthLAWResourceId,
        [Parameter(Mandatory=$true)]
        [string]
        $ControlName,
        [Parameter(Mandatory=$true)]
        [string]
        $WorkSpaceID,
        [Parameter(Mandatory=$true)]
        [string]
        $workspaceKey,
        [Parameter(Mandatory=$true)]
        [string]
        $LogType="GuardrailsCompliance",
        [Parameter(Mandatory=$true)]
        [string]
        $ReportTime
    )
    $ItemName1="SecurityMonitoring"
    $ItemName2="HealthMonitoring"
    $ItemName3="DefenderMonitoring"
    #Code
    $Subscription=$SecurityLAWResourceId.Split("/")[2]
    $LAWRG=$SecurityLAWResourceId.Split("/")[4]
    $LAWName=$SecurityLAWResourceId.Split("/")[8]
    $HealthLAWRG=$SecurityLAWResourceId.Split("/")[4]
    $HealthLAWName=$SecurityLAWResourceId.Split("/")[8]
    
    $IsCompliant=$true
    #LAW exists and has the proper retention
    $Comment1="The specified Log Analytics Workspace for Security monitoring has not been found."
    $Comment2="Retention not set to 730 days."
    $Comment3="WorkSpace not configured to ingest activity Logs."
    $Comment4="Required solutions not present in the Log Analytics Workspace."
    $Comment5="No linked automation account has been found."
    $Comment6="Tenant Diagnostics settings are not pointing to the provided log analysitcs workspace."
    $Comment7="Workspace set in tenant config but not all required log types are enabled (Audit and signin)."
    $Comment8="The specified Log Analytics Workspace for Health monitoring has not been found."
    $Comment9="Retention not set to at least90 days."
    $Comment10="Required solutions not present in the Health Log Analytics Workspace."
    $Comment11=""
    $Comment12=""
    $Comment13=""
    $MitigationCommands=""
    Select-AzSubscription -Subscription $Subscription
    $LAW=Get-AzOperationalInsightsWorkspace -Name $LAWName -ResourceGroupName $LAWRG
    if ($LAW -eq $null)
    {
        $IsCompliant=$false
        $Comments=$Comment1 # "The specified Log Analytics Workspace has not been found."
        $MitigationCommands="Please create a log analytics workspace according to guidelines."
    }
    else {
        # Test linked automation account
        $LinkedServices=get-apiLinkedServicesData -subscriptionId $Subscription `
            -resourceGroup $LAWRG `
            -LAWName $LAWName
        if (($LinkedServices.value.properties.resourceId | Where-Object {$_ -match "automationAccounts"}).count -lt 1)
        {
            $IsCompliant=$false
            $Comments+=$Comment5 #"No linked automation account has been found."
            $MitigationCommands+=@"
Please connect an automation account to the provided workspace.($LAWName).
https://docs.microsoft.com/en-us/azure/automation/quickstarts/create-account-portal
https://docs.microsoft.com/en-us/azure/automation/how-to/region-mappings
"@
        }
        #Test Retention Days
        $Retention=$LAW.retentionInDays
        if ($Retention -ne 730)
        {
            $IsCompliant=$false
            $Comments+=$Comment2 # "Retention not set to 730 days."
            $MitigationCommands+="Set retention of the workspace to 730 days.($LAWName)-https://docs.microsoft.com/en-us/azure/azure-monitor/logs/data-retention-archive?tabs=api-1%2Capi-2 "
        }
        #Verify presense of the Activity Logs as a source
        $ActivityLogDS=Get-AzOperationalInsightsDataSource -Workspace $LAW -Kind AzureActivityLog
        If ($ActivityLogDS -eq $null)
        {
            $IsCompliant=$false
            $Comments+=$Comment3 # "WorkSpace not configured to ingest activity Logs."
            $MitigationCommands+="Please add the Activity Logs solution to the workspace ($LAWName) - https://docs.microsoft.com/en-us/azure/active-directory/reports-monitoring/howto-analyze-activity-logs-log-analytics"
        }
        # Tests for required Solutions
        $enabledSolutions=(Get-AzOperationalInsightsIntelligencePack -ResourceGroupName $LAW.ResourceGroupName -WorkspaceName $LAW.Name| Where-Object {$_.Enabled -eq "True"}).Name
        if ($enabledSolutions -notcontains "Updates" -or $enabledSolutions -notcontains "AntiMalware")
        {
            $IsCompliant=$false
            $Comments+=$Comment4 # "Required solutions not present in the Log Analytics Workspace."
            $MitigationCommands+=@"
Please add the both the Updates and Anti-Malware solution to the workspace ($LAWName)"
https://docs.microsoft.com/en-us/azure/automation/update-management/overview
https://azuremarketplace.microsoft.com/en-us/marketplace/apps/Microsoft.AntiMalwareOMS?tab=Overview
"@
        }
        # Tenant Diagnostics configuration. Needs Graph API...
        $tenantWS=get-tenantDiagnosticsSettings
        if ($SecurityLAWResourceId -notin $tenantWS.workspaceId)
        {
            $IsCompliant=$false
            $Comments+=$Comment6 # "Tenant Diagnostics settings are not pointing to the provided log analysitcs workspace."
            $MitigationCommands+="Please configure the Tenant diagnostics to point to the provided workspace. ($LAWName) https://docs.microsoft.com/en-us/azure/active-directory/reports-monitoring/howto-integrate-activity-logs-with-log-analytics#send-logs-to-azure-monitor"
        }
        else {
            #Workspace is there but need to check if logs are enabled.
            $enabledLogs=(($p| ? {$_.workspaceId -eq $wsid}).logs | ? {$_.enabled -eq $true}).category
            if ("AuditLogs" -notin $enabledLogs -or "SignInLogs" -notin $enabledLogs)
            {
                $IsCompliant=$false
                $Comments+=$Comment7 # "Workspace set in tenant config but not all required log types are enabled (Audit and signin)."
                $MitigationCommands+="Please enable Audit Logs and SignInLogs in the Tenant Dianostics settings. ($LAWName) - https://docs.microsoft.com/en-us/azure/active-directory/reports-monitoring/howto-integrate-activity-logs-with-log-analytics#send-logs-to-azure-monitor"
            }
        }
        #Blueprint redirection
        # Sentinel, not sure how to detect this.
        if ($IsCompliant)
        {
            $Comments="The Logs and Monitoring is compliant for Security."
            $MitigationCommands+="N/A"
        }
        $object = [PSCustomObject]@{ 
            ComplianceStatus = $IsCompliant
            Comments = $Comments
            ItemName = $ItemName1
            ControlName = $ControlName
            ReportTime = $ReportTime
            MitigationCommands=$MitigationCommands
        }
        $JSON= ConvertTo-Json -inputObject $object

        Send-OMSAPIIngestionFile  -customerId $WorkSpaceID `
        -sharedkey $workspaceKey `
        -body $JSON `
        -logType $LogType `
        -TimeStampField Get-Date 
        $IsCompliant=$true
    }
    #
    #Health
    #
    $MitigationCommands=""
    $IsCompliant=$true
    $Comments=""
    $HSubscription=$SecurityLAWResourceId.Split("/")[2]
    if ($Subscription -ne $HSubscription)
    {
        Select-AzSubscription -Subscription $HSubscription
    }
    $LAW=Get-AzOperationalInsightsWorkspace -Name $HealthLAWName -ResourceGroupName $HealthLAWRG
    if ($LAW -eq $null)
    {
        $IsCompliant=$false
        $Comments+=$Comment8 # "The specified Log Analytics Workspace for Health monitoring has not been found."
        $MitigationCommands+="Please create a workspace according to the Guarrails guidelines. ($HealthLAWName)"
    }
    else {
        $LinkedServices=get-apiLinkedServicesData -subscriptionId $HSubscription `
        -resourceGroup $LAW.ResourceGroupName `
        -LAWName $LAW.Name
        if (($LinkedServices.value.properties.resourceId | Where-Object {$_ -match "automationAccounts"}).count -lt 1)
        {
            $IsCompliant=$false
            $Comments+=$Comment5 #"No linked automation account has been found."
            $MitigationCommands+=@"
Please connect an automation account to the provided workspace.($LAWName).
https://docs.microsoft.com/en-us/azure/automation/quickstarts/create-account-portal
https://docs.microsoft.com/en-us/azure/automation/how-to/region-mappings
"@
        }
        $Retention=$LAW.retentionInDays
        if ($Retention -lt 90)
        {
            $IsCompliant=$false
            $Comments+=$Comment9 # "Retention not set to at least90 days."
            $MitigationCommands+="Set retention of the workspace to at least 90 days.($HealthLAWName) - https://docs.microsoft.com/en-us/azure/azure-monitor/logs/data-retention-archive?tabs=api-1%2Capi-2"
        }
        #Checks required solutions
        $enabledSolutions=(Get-AzOperationalInsightsIntelligencePack -ResourceGroupName $LAW.ResourceGroupName -WorkspaceName $LAW.Name| Where-Object {$_.Enabled -eq "True"}).Name
        if ($enabledSolutions -notcontains "AgentHealthAssessment")
        {
            $IsCompliant=$false
            $Comments+=$Comment10 # "Required solutions not present in the Health Log Analytics Workspace."
            $MitigationCommands+="Please enable the Agent Health Assessment soltuion in the workspace.($HealthLAWName) - https://docs.microsoft.com/en-us/azure/azure-monitor/insights/solution-agenthealth"
        }
        #Tenant...No information on how to detect it.
        #Blueprint
    }
    if ($IsCompliant)
    {
        $Comments="The environment is compliant."
        $MitigationCommands+="N/A."
    }
    $object = [PSCustomObject]@{ 
        ComplianceStatus = $IsCompliant
        Comments = $Comments
        ItemName = $ItemName2
        ControlName = $ControlName
        ReportTime = $ReportTime  
        MitigationCommands=$MitigationCommands      
    }
    $JSON= ConvertTo-Json -inputObject $object

    Send-OMSAPIIngestionFile  -customerId $WorkSpaceID `
    -sharedkey $workspaceKey `
    -body $JSON `
    -logType $LogType `
    -TimeStampField Get-Date 
    #
    # Defender for cloud detection.
    #
    $IsCompliant=$true
    $MitigationCommands=""
    $Comments=""
    $sublist=Get-AzSubscription | Where-Object {$_.State -eq 'Enabled'}
    # This will look for specific Defender for Cloud, on a per subscription basis.
    foreach ($sub in $sublist)
    {
        Select-AzSubscription -SubscriptionObject $sub
        $ContactInfo=Get-AzSecurityContact
        if ($ContactInfo.Email -ne $null -or $ContactInfo.Phone -eq $null)
        {
            $IsCompliant=$false
            $Comments="Subscription $($sub.Name) is missing Contact Information."
            $MitigationCommands+="Please set a security contact for Defender for Cloud in the subscription. $($sub.Name)"
        }
        if ((Get-AzSecurityPricing | Select-Object PricingTier | Where-Object {$_.PricingTier -eq 'Free'}).Count -gt 0)
        {
            $IsCompliant=$false
            $Comments+="Not all princing plan options are set to Standard for subscription $($sub.Name)"
            $MitigationCommands+="Please set Defender for cloud plans to Standard. ($($sub.Name))"
        }
    }
    if ($IsCompliant)
    {
        $Comments="The Logs and Monitoring is compliant for Security."
    }
    $object = [PSCustomObject]@{ 
        ComplianceStatus = $IsCompliant
        Comments = $Comments
        ItemName = $ItemName3
        ControlName = $ControlName
        ReportTime = $ReportTime
        MitigationCommands=$MitigationCommands
    }
    $JSON= ConvertTo-Json -inputObject $object

    Send-OMSAPIIngestionFile  -customerId $WorkSpaceID `
    -sharedkey $workspaceKey `
    -body $JSON `
    -logType $LogType `
    -TimeStampField Get-Date 
    $IsCompliant=$true
}
