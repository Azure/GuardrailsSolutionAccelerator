# Guardrails - Controls

How the controls work.

## GUARDRAIL 1 PROTECT ROOT  GLOBAL ADMINS ACCOUNT
In this control the solution tries to validate muliple items as follow.

1. Break Glass accounts Creation

      The solution will verify the existence of the two Break Glass accounts that you have  entered in the config.json during the setup process.Once the solution detects both accounts the check mark status will be changed from (❌) to (✔️).

2. Break Glass accounts Procedure

      If you have completed the break glass accounts procedure, make sure to upload an empty Text file with the name "BreakGlassAccountProcedure.txt" to the container name "guardrailsstorage" in the storage account created by the setup. this file tell the solution that you have completed this task. please do not upload the break glass account procedure it self, once the solution detects the file,  the check mark status will be changed from (❌) to (✔️).

      ![BreakGlassAccountProcedure.txt uploaded to the storage account](/Images/BreakGlassAccountProcedure.png)

3. Break Glass Accounts Owners contacs information
      
      Break Glass Account must be owned by  in the orgnization, the owner is the manager of the accounts , the solution will verify if the manager information for both Break Glass Accounts is populated, once the solution detects the manager information for both accounts,  the check mark status will be changed from (❌) to (✔️).

      ![BreakGlassAccountProcedure.txt uploaded to the storage account](/Images/BreakGlassAccountOwnersContactInformation.png)
      
4. Responsibility of Break Glass accounts 

    After you confirm that the person(s) responsible of the Break Glass accounts is not technical and and has a director level or above make sure to upload an empty Text file with the name "ConfirmBreakGlassAccountResponsibleIsNotTechnical.txt" to the container name "guardrailsstorage" in the storage account created by the setup. this file tells the solution that you have completed this task. Once the solution detects the file,  the check mark status will be changed from (❌) to (✔️).

      ![BreakGlassAccountProcedure.txt uploaded to the storage account](/Images/ConfirmBreakGlassAccountResponsibleIsNotTechnical.png)

5. AD License Type

      The module will look for a P2 equivalent licensing, Once the solution find any of the following "String Id",  the check mark status will be changed from (❌) to (✔️).

      * Product name: AZURE ACTIVE DIRECTORY PREMIUM P2,  String ID: AAD_PREMIUM_P2 
      * Product name: ENTERPRISE MOBILITY + SECURITY E5,  String ID: EMSPREMIUM    	
      * Product name: Microsoft 365 E5, 	                String ID: SPE_E5  	

6. Break Glass Accounts Restricted Access 

      The module checks if the mutifactor authentication (MFA) is enable on the break glass account, if MFA is not enabled the check mark status will be changed from (❌) to (✔️).

7. Break Glass Accounts must be created in the tenant Azure Active Directory

      The solution checks if both break glass accounts are member of the Azure Active Directory, and not guest account or from another directory. if the solutuion finds both break glass accounts are member of the Azure Active Directory it will change the check mark status from (❌) to (✔️).


## GUARDRAIL 2 MANAGEMENT OF ADMINISTRATIVE PRIVILEGES
    
This Module...

## GUARDRAIL 3 CLOUD CONSOLE ACCESS
    
This Module...

## GUARDRAIL 4 ENTERPRISE MONITORING ACCOUNTS
    
This Module...

## GUARDRAIL 5 DATA LOCATION
    
This Module...

## GUARDRAIL 6 PROTECTION OF DATA-AT-REST
    
This Module...


## Module 7GUARDRAIL 7 PROTECTION OF DATA-IN-TRANSIT
    
This Module...

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
    
This Module...

## GUARDRAIL 11 LOGGING AND MONITORING
    
This Module...

## GUARDRAIL 12 CONFIGURATION OF CLOUD MARKETPLACES
    
This Module...
