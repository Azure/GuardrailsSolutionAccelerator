# Guardrails - Controls

How the controls work.

## GUARDRAIL 1 PROTECT ROOT  GLOBAL ADMINS ACCOUNT
In this control the solution tries to validate multiple items as follow.

1. Break Glass accounts Creation

      The solution will verify the existence of the two Break Glass accounts that you have  entered in the config.json during the setup process.Once the solution detects both accounts the check mark status will be changed from (❌) to (✔️).

2. Break Glass accounts Procedure

      If you have completed the break glass accounts procedure, make sure to upload an empty Text file with the name "BreakGlassAccountProcedure.txt" to the container name "guardrailsstorage" in the storage account created by the setup. this file tell the solution that you have completed this task. please do not upload the break glass account procedure it self, once the solution detects the file,  the check mark status will be changed from (❌) to (✔️).

      ![BreakGlassAccountProcedure.txt uploaded to the storage account](/docs/media/BreakGlassAccountProcedure.png)

3. Break Glass Accounts Owners contacts information
      
      Break Glass Account must be owned by  in the organization, the owner is the manager of the accounts , the solution will verify if the manager information for both Break Glass Accounts is populated, once the solution detects the manager information for both accounts,  the check mark status will be changed from (❌) to (✔️).

      ![BreakGlassAccountProcedure.txt uploaded to the storage account](/docs/media/BreakGlassAccountOwnersContactInformation.png)
      
4. Responsibility of Break Glass accounts 

    After you confirm that the person(s) responsible of the Break Glass accounts is not technical and and has a director level or above make sure to upload an empty Text file with the name "ConfirmBreakGlassAccountResponsibleIsNotTechnical.txt" to the container name "guardrailsstorage" in the storage account created by the setup. this file tells the solution that you have completed this task. Once the solution detects the file,  the check mark status will be changed from (❌) to (✔️).

      ![BreakGlassAccountProcedure.txt uploaded to the storage account](/docs/media/ConfirmBreakGlassAccountResponsibleIsNotTechnical.png)

5. AD License Type

      The module will look for a P2 equivalent licensing, Once the solution find any of the following "String Id",  the check mark status will be changed from (❌) to (✔️).

      * Product name: AZURE ACTIVE DIRECTORY PREMIUM P2,  String ID: AAD_PREMIUM_P2 
      * Product name: ENTERPRISE MOBILITY + SECURITY E5,  String ID: EMSPREMIUM    	
      * Product name: Microsoft 365 E5, 	                String ID: SPE_E5  	

6. Break Glass Accounts Restricted Access 

      The module checks if the multi-factor authentication (MFA) is enable on the break glass account, if MFA is not enabled the check mark status will be changed from (❌) to (✔️).

7. Break Glass Accounts must be created in the tenant Azure Active Directory

      The solution checks if both break glass accounts are member of the Azure Active Directory, and not guest account or from another directory. if the solution finds both break glass accounts are member of the Azure Active Directory it will change the check mark status from (❌) to (✔️).


## GUARDRAIL 2 MANAGEMENT OF ADMINISTRATIVE PRIVILEGES
    
This Module...

## GUARDRAIL 3 CLOUD CONSOLE ACCESS
    
This Module...

## GUARDRAIL 4 ENTERPRISE MONITORING ACCOUNTS
    
This Module...

## GUARDRAIL 5 DATA LOCATION

### Check-DataLocation

### Check-PBMMPolicy
    
This Module will detect the PBMM Initiative. The detection will happen at the Root Tenant management group and down, looking for all subscriptions and management groups. Any subscription of MG without the applied initial will be marked as non compliant.

## GUARDRAIL 6 PROTECTION OF DATA-AT-REST
    
This module will detect the PBMM and look for specific policies not to be exempted. The compliance will fail right away if the PBMM policy is not applied. If applied, the following policies will be checked for exemptions:

- "TransparentDataEncryptionOnSqlDatabasesShouldBeEnabled"
- "DiskEncryptionShouldBeAppliedOnVirtualMachines"

## Module 7GUARDRAIL 7 PROTECTION OF DATA-IN-TRANSIT
    
This module will detect the PBMM and look for specific policies not to be exempted. The compliance will fail right away if the PBMM policy is not applied. If applied, the following policies will be checked for exemptions:

- "FunctionAppShouldOnlyBeAccessibleOverHttps"
- "WebApplicationShouldOnlyBeAccessibleOverHttps"
- "ApiAppShouldOnlyBeAccessibleOverHttps"
- "OnlySecureConnectionsToYourRedisCacheShouldBeEnabled"
- "SecureTransferToStorageAccountsShouldBeEnabled"
   

## Guardrails Module 8 - Separation and Segmentation

This module will retrieve the list of subnets in all available VNets (all VNets visible to the managed identity, according to the permissions assigned (Typically, all since permissions are assigned at the Root Management Group level))

For each subnet the following items will be evaluated:

### Regarding Segmentation


- Existence of an NSG attached to the subnet.
- In the said NSG, there must be a rule, set as the last rule in the custom rules, and configured to deny all traffic.

If any of the above rules is not true, the subnet will be considered non compliant

### Regarding Separation

- Existence of an UDR (Route table) assigned to the subnet
- The UDR must have a default route set to a Virtual Appliance

If any of the above rules is not true, the subnet will be considered not compliant.

## GUARDRAIL 9 NETWORK SECURITY SERVICES

This module will retrieve the list of all VNets (all VNets visible to the managed identity, according to the permissions assigned (Typically, all since permissions are assigned at the Root Management Group level))

For each VNet the following items will be evaluated.

- DDos Protection set to Standard.

If any of the above rules is not true, the VNet will be considered not compliant.

## GUARDRAIL 10 CYBER DEFENSE SERVICES
    
  The solution will verify the existence of the [Cyber Defence Services resources](https://github.com/canada-ca/cloud-guardrails/blob/master/EN/10_Cyber-Defense-Services.md) in the dedicated Cyber Defence Services subscription in the config.json during the setup process. Once the solution detects these resources the check mark status will be changed from (❌) to (✔️).
## GUARDRAIL 11 LOGGING AND MONITORING
    
This module will detect the items below:

| Item | Description |
| ----------- | ----------- |
| SECURITY ||
| Create a RG for security monitoring | Implied since the Log Analytics workspace needs to be informed as a parameter |
|Create LAW, Retention needs to be 2 years.|Checks the retention of the provided LAW|
|Workspace summary, add the log types:  activity log analytics. Ensure to add all subscriptions except sandbox|Checks for a data source set to Activity Logs |
|Workspace summary, add, anti-malware assessment|Checks for the presence of the anti-malware solution|
|Workspace summary, add, KeyVault analytics|This solution has been deprecated. KeyVault insights is recommended. **Not being detected at the moment**|
|Create a resource, automation account | Checks for a connected automation account in the provided LAW|
|Go to RG. Select the account, update management, select the LAW and enable| Checks for the Update Management solution in the provided LAW|
|In the tenant, select diagnostic setting. Select the LAW and select audit logs, sigint logs |**TBD - Not functional right now**|
|Need to redirect blueprint to this LAW |**TBD**|
|Go to Azure sentinel and select the LAW and add it to sentinel. Go to data connectors. Add azure activity, office 365 and anything we use |**TBD**|
|HEALTH||
|create a RG for performance and health monitoring. Create LAW, Retention needs to be 90 days.   |Checks for the specific retention in the provided health LAW|
|Workspace summary, add the log types . Make sure to add all subscriptions except sandbox |Right now all subscriptions are tested, **no exceptions.**|
|Workspace summary, add, Azure Log Analytics Agent Health |Checks for the solution|
|Create a resource, automation account |Checks for a connected automation account in the provided LAW|
|Go to RG. Select the account, update management, select the LAW and enable |Checks for the Update Management solution in the provided LAW|
|In the tenant, select diagnostic setting. Select the LAW and select ….. |**TBD**|
|Need to redirect blueprint to this LAW |**TBD**|
|DEFENDER FOR CLOUD||
|Standard tier | Considered compliant if all tiers are enabled.|
|Data collection  -  Send all events |**TBD**|
|Email notification - enter email and phone number (select send email for high severity alerts) | **Any email or telephone** found is considered compliant.|
|Threat detection – enable |**TBD**|

## GUARDRAIL 12 CONFIGURATION OF CLOUD MARKETPLACES
    
The solution will verify if the private market place has been created, Once the solution detects the private market place the check mark status will be changed from (❌) to (✔️).
