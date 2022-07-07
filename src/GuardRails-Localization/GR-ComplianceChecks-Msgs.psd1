ConvertFrom-StringData @'

# English strings

CtrName1 = GUARDRAIL 1: PROTECT ROOT / GLOBAL ADMINS ACCOUNT
CtrName2 = GUARDRAIL 2: MANAGEMENT OF ADMINISTRATIVE PRIVILEGES
CtrName3 = GUARDRAIL 3: CLOUD CONSOLE ACCESS
CtrName4 = GUARDRAIL 4: ENTERPRISE MONITORING ACCOUNTS
CtrName5 = GUARDRAIL 5: DATA LOCATION
CtrName6 = GUARDRAIL 6: PROTECTION OF DATA-AT-REST
CtrName7 = GUARDRAIL 7: PROTECTION OF DATA-IN-TRANSIT
CtrName8 = GUARDRAIL 8: NETWORK SEGMENTATION AND SEPARATION
CtrName9 = GUARDRAIL 9: NETWORK SECURITY SERVICES
CtrName10 = GUARDRAIL 10: CYBER DEFENSE SERVICES
CtrName11 = GUARDRAIL 11: LOGGING AND MONITORING
CtrName12 = GUARDRAIL 12: CONFIGURATION OF CLOUD MARKETPLACES

# Guardrail 1
adLicense = AD License Type
mfaEnforcement = MFA Enforcement
mfaDisabledFor =  MFA Authentication is not enabled for {0} 
m365Assignment = Microsoft 365 E5 Assignment
bgProcedure = Break Glass account Procedure
bgCreation = Break Glass account Creation
bgAccountResponsibility = Responsibility of break glass accounts must be with someone not-technical, director level or above
bgAccountOwnerContact = Break Glass Account Owners Contact information
procedureFileFound = File {0} found in Container.
procedureFileNotFound = Coudnt find document for {0}, please create and upload a file with the name {1} in Container {2} on {3} Storage account to confirm you have completed the Item in the control.
bgAccountsCompliance = {0} Compliance status = {1}, {2} Compliance status = {3}
bgAuthenticationMeth =  Authentication Methods 
bgLicenseNotAssigned = NOT ASSIGNED
bgAssignedLicense =  Assigned License = 
bgAccountHasManager = BG Account {0} has a Manager
bgAccountNoManager = BG Account {0} doesnt have a Manager 
bgBothHaveManager = Both BreakGlass accounts have manager

# GuardRail #2
removeDeletedAccount = Permanently remove deleted accounts
removeDeprecatedAccount = Remove deprecated accounts
removeGuestAccounts = Remove guest accounts.
accountNotDeleted = This user account has been deleted but has not yet been DELETED PERMANENTLY from Azure Active Directory
guestMustbeRemoved = This GUEST account should not have any role assignment in the Azure subscriptions
removeGuestAccountsComment = Remove guest accounts from Azure AD or remove their permissions from the Azure subscriptions.
noGuestAccounts = There are no GUEST users in your tenant.
guestAccountsNoPermission = There are Guest accounts in the tenant but they don't have any permission in the subscriptions.
ADDeletedUser = AD Deleted User
ADDisabledUsers = AD Disabled Users
noncompliantUsers = The following Users are disabled and not synchronized with AD: - 
noncompliantComment = Total Number of non-compliant users {0}. 
compliantComment = Didnt find any unsynced deprecated users
mitigationCommands = Verify is the users reported are deprecated.
apiError = API Error
apiErrorMitigation = Please verify existance of the user (more likely) or application permissions.

# GuardRail #4
monitorAccount = Monitor Account Creation
checkUserExistsError = API call returned Error {0}. Please Check if the user exists.
checkUserExists = Please Check if the user exists.

# GuardRail #5-6
pbmmCompliance = PBMMPolicy Compliance
policyNotAssigned = The Policy or Initiative is not assigned to the {0}
excludedFromScope = {0} is excluded from the scope of the assignment
grexemptionFound = Exemption for {0} {1} found.
isCompliant = Compliant
policyNotAssignedRootMG = The Policy or Initiative is not assigned on the Root Management Groups
rootMGExcluded =This Root Management Groups is excluded from the scope of the assignment
pbmmNotApplied =PBMM Initiative is not applied.
subscription = subscription
managementGroup = Management Groups
notAllowedLocation =  Location is outside of the allowed locations. 
allowedLocationPolicy = AllowedLocationPolicy
dataAtRest = PROTECTION OF DATA-AT-REST
dataInTransit = PROTECTION OF DATA-IN-TRANSIT

# GuardRail #8
noNSG=No NSG is present.
subnetCompliant = Subnet is compliant.
nsgConfigDenyAll = NSG is present but not properly configured (Missing Deny all last Rule).
nsgCustomRule = NSG is present but not properly configured (Missing Custom Rules).
networkSegmentation = Segmentation
networkSeparation = Separation
routeNVA = Route present but not directed to a Virtual Appliance.
routeNVAMitigation = Update the route to point to a virtual appliance
noUDR = No User defined Route configured.
noUDRMitigation = Please apply a custom route to this subnet, pointing to a virtual appliance.
subnetExcluded = Subnet Excluded (manually or reserved name).

# GuardRail # 9
vnetDDosConfig = VNet DDos configuration
ddosEnabled=DDos Protection Enabled. 
ddosNotEnabled=DDos Protection not enabled.

# GuardRail #10
cbsSubDoesntExist = CBS Subscription doesnt exist
cbcSensorsdontExist = The expected CBC sensors do not exist
cbssMitigation = Check subscription provided: {0} or check existence of the CBS solution in the provided subscription.
cbssCompliant = Found resources in these subscriptions: 

# GuardRail #11
securityMonitoring =SecurityMonitoring
healthMonitoring = HealthMonitoring
defenderMonitoring =DefenderMonitoring
securityLAWNotFound = The specified Log Analytics Workspace for Security monitoring has not been found.
lawRetention730Days = Retention not set to 730 days.
lawNoActivityLogs = WorkSpace not configured to ingest activity Logs.
lawSolutionNotFound = Required solutions not present in the Log Analytics Workspace.
lawNoAutoAcct = No linked automation account has been found.
lawNoTenantDiag = Tenant Diagnostics settings are not pointing to the provided log analytics workspace.
lawMissingLogTypes = Workspace set in tenant config but not all required log types are enabled (Audit and signin).
healthLAWNotFound = The specified Log Analytics Workspace for Health monitoring has not been found.
lawRetention90Days = Retention not set to at least 90 days.
lawHealthNoSolutionFound = Required solutions not present in the Health Log Analytics Workspace.
createLAW = Please create a log analytics workspace according to guidelines.
connectAutoAcct = Please connect an automation account to the provided workspace.
setRetention60Days = Set retention of the workspace to at least 90 days for workspace: 
setRetention730Days = Set retention of the workspace to 730 days for workspace: 
addActivityLogs = Please add the Activity Logs solution to the workspace: 
addUpdatesAndAntiMalware = Please add the both the Updates and Anti-Malware solution to the workspace: 
configTenantDiag = Please configure the Tenant diagnostics to point to the provided workspace: 
addAuditAndSignInsLogs = Please enable Audit Logs and SignInLogs in the Tenant Dianostics settings.
logsAndMonitoringCompliantForHealth= The Logs and Monitoring are compliant for Health.
logsAndMonitoringCompliantForSecurity = The Logs and Monitoring are compliant for Security.
logsAndMonitoringCompliantForDefender = The Logs and Monitoring are compliant for Defender.
createHealthLAW = Please create a workspace for Health Monitoring according to the Guardrails guidelines.
enableAgentHealthSolution = Please enable the Agent Health Assessment solution in the workspace.
lawEnvironmentCompliant = The environment is compliant.
noSecurityContactInfo = Subscription {0} is missing Contact Information.
setSecurityContact = Please set a security contact for Defender for Cloud in the subscription. {0}
notAllDfCStandard = Not all princing plan options are set to Standard for subscription {0}
setDfCToStandard = Please set Defender for Cloud plans to Standard. ({0})

# GuardRail #12
mktPlaceCreation = MarketPlaceCreation
mktPlaceCreated = The Private Marketplace has been created.
mktPlaceNotCreated = The Private Marketplace has not been created.
enableMktPlace = Enable Azure Private MarketPlace as per: https://docs.microsoft.com/en-us/marketplace/create-manage-private-azure-marketplace-new

'@
