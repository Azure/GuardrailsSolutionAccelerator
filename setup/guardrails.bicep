//Scope
targetScope = 'resourceGroup'
//Parameters and variables
param storageAccountName string
param subscriptionId string
param location string = 'canadacentral'
param kvName string = 'guardrails-kv'
param automationAccountName string = 'guardrails-AC'
param logAnalyticsWorkspaceName string = 'guardrails-LAW'
param PBMMPolicyID string = '4c4a5f27-de81-430b-b4e5-9cbd50595a87'
param AllowedLocationPolicyId string = 'e56962a6-4747-49cd-b67b-bf8b01975c4c'
param DepartmentNumber string
param deployKV bool = true
param deployLAW bool = true
param CBSSubscriptionName string 
param SecurityLAWResourceId string
param HealthLAWResourceId string
param CustomModulesBaseURL string = 'https://raw.githubusercontent.com/igomaa/GoCGuardrailsSolutionAccelerator/Final/psmodules'
//var <variable-name> = <variable-value>
var containername = 'guardrailsstorage'
var vaultUri = 'https://${kvName}.vault.azure.net/'
var rg=resourceGroup().name
var wbConfig1 ='''
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 1,
      "content": {
        "json": "## Guardrails Accelerator",
        "style": "info"
      },
      "name": "Details Title"
    },
    {
      "type": 11,
      "content": {
        "version": "LinkItem/1.0",
        "style": "tabs",
        "links": [
          {
            "id": "6a683959-7ed3-42b1-a509-3cdcd18017cf",
            "cellValue": "selectedTab",
            "linkTarget": "parameter",
            "linkLabel": "GUARDRAIL 1",
            "subTarget": "gr1",
            "style": "link"
          },
          {
            "id": "6a683959-7fd3-42b1-a509-3cdcd18017cf",
            "cellValue": "selectedTab",
            "linkTarget": "parameter",
            "linkLabel": "GUARDRAIL 2",
            "subTarget": "gr2",
            "style": "link"
          },
          {
            "id": "6a683359-5ed3-42b1-a509-3cdcd18017cf",
            "cellValue": "selectedTab",
            "linkTarget": "parameter",
            "linkLabel": "GUARDRAIL 3",
            "subTarget": "gr3",
            "style": "link"
          },
          {
            "id": "6a383959-1ed3-42b1-a509-3cdcd18017cf",
            "cellValue": "selectedTab",
            "linkTarget": "parameter",
            "linkLabel": "GUARDRAIL 4",
            "subTarget": "gr4",
            "style": "link"
          },
          {
            "id": "6b683959-7ed3-42b1-a509-3cdcd18017cf",
            "cellValue": "selectedTab",
            "linkTarget": "parameter",
            "linkLabel": "GUARDRAIL 5",
            "subTarget": "gr5",
            "style": "link"
          },
          {
            "id": "6a683959-4fd3-42b1-a509-3cdcd18017cf",
            "cellValue": "selectedTab",
            "linkTarget": "parameter",
            "linkLabel": "GUARDRAIL 6",
            "subTarget": "test6",
            "style": "link"
          },
          {
            "id": "6a683959-7ed3-42b1-a509-3cfcd18017cf",
            "cellValue": "selectedTab",
            "linkTarget": "parameter",
            "linkLabel": "GUARDRAIL 7",
            "subTarget": "gr7",
            "style": "link"
          },
          {
            "id": "4b2de2e9-a9c7-486c-a524-7da0e8f44d26",
            "cellValue": "selectedTab",
            "linkTarget": "parameter",
            "linkLabel": "GUARDRAIL 8",
            "subTarget": "gr8",
            "style": "link"
          },
          {
            "id": "40243b3d-3037-482b-959b-d95c1b4b2014",
            "cellValue": "selectedTab",
            "linkTarget": "parameter",
            "linkLabel": "GUARDRAIL 9",
            "subTarget": "gr9",
            "style": "link"
          },
          {
            "id": "6bc4aa50-56c1-425b-9894-d6d7edb20e3a",
            "cellValue": "selectedTab",
            "linkTarget": "parameter",
            "linkLabel": "GUARDRAIL 10",
            "subTarget": "gr10",
            "style": "link"
          },
          {
            "id": "cad591d5-9404-46e2-b56f-b32723b390de",
            "cellValue": "selectedTab",
            "linkTarget": "parameter",
            "linkLabel": "GUARDRAIL 11",
            "subTarget": "gr11",
            "style": "link"
          },
          {
            "id": "144c0d71-a9de-4e02-95bf-0474d243ada6",
            "cellValue": "selectedTab",
            "linkTarget": "parameter",
            "linkLabel": "GUARDRAIL 12",
            "subTarget": "gr12",
            "style": "link"
          }
        ]
      },
      "name": "links - 1"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 1\"\r\n|project ItemName=ItemName_s, Comments=Comments_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ ')",
        "size": 0,
        "title": "GR 1",
        "timeContext": {
          "durationMs": 3600000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      },
      "conditionalVisibility": {
        "parameterName": "selectedTab",
        "comparison": "isEqualTo",
        "value": "gr1"
      },
      "name": "Gr1"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 2\"\r\n|project ItemName=ItemName_s, Comments=Comments_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ ')",
        "size": 0,
        "title": "GR 2",
        "timeContext": {
          "durationMs": 3600000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      },
      "conditionalVisibility": {
        "parameterName": "selectedTab",
        "comparison": "isEqualTo",
        "value": "gr2"
      },
      "name": "Gr1 - Copy"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 3\"\r\n|project ItemName=ItemName_s, Comments=Comments_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ ')",
        "size": 0,
        "title": "GR 3",
        "timeContext": {
          "durationMs": 3600000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      },
      "conditionalVisibility": {
        "parameterName": "selectedTab",
        "comparison": "isEqualTo",
        "value": "gr3"
      },
      "name": "Gr1 - Copy - Copy"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 4\"\r\n|project ItemName=ItemName_s, Comments=Comments_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ ')",
        "size": 0,
        "title": "GR 4",
        "timeContext": {
          "durationMs": 3600000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      },
      "conditionalVisibility": {
        "parameterName": "selectedTab",
        "comparison": "isEqualTo",
        "value": "gr4"
      },
      "name": "query - 6 - Copy"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 5:\" \r\n| project ItemName_s,DisplayName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\r\n| sort by Status asc",
        "size": 0,
        "title": "GR 5",
        "timeContext": {
          "durationMs": 3600000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces",
        "gridSettings": {
          "hierarchySettings": {
            "treeType": 1,
            "groupBy": [
              "Status"
            ]
          }
        }
      },
      "conditionalVisibility": {
        "parameterName": "selectedTab",
        "comparison": "isEqualTo",
        "value": "gr5"
      },
      "name": "query - 2 - Copy - Copy"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 6:\" \r\n| project ItemName_s,DisplayName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\r\n| sort by Status asc",
        "size": 0,
        "title": "GR 6",
        "timeContext": {
          "durationMs": 3600000
        },
        "exportToExcelOptions": "all",
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces",
        "gridSettings": {
          "hierarchySettings": {
            "treeType": 1,
            "groupBy": [
              "Status"
            ]
          }
        }
      },
      "conditionalVisibility": {
        "parameterName": "selectedTab",
        "comparison": "isEqualTo",
        "value": "test6"
      },
      "name": "query - 26 - Copy"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 7:\" \r\n| project ItemName_s,DisplayName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\r\n| sort by Status asc",
        "size": 0,
        "title": "GR 7",
        "timeContext": {
          "durationMs": 3600000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces",
        "gridSettings": {
          "hierarchySettings": {
            "treeType": 1,
            "groupBy": [
              "Status"
            ]
          }
        }
      },
      "conditionalVisibility": {
        "parameterName": "selectedTab",
        "comparison": "isEqualTo",
        "value": "gr7"
      },
      "name": "query - 6 - Copy"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 8:\" \r\n| project SubnetName=SubnetName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\r\n| sort by Status asc",
        "size": 0,
        "title": "GR 8",
        "timeContext": {
          "durationMs": 3600000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces",
        "gridSettings": {
          "hierarchySettings": {
            "treeType": 1,
            "groupBy": [
              "Status"
            ]
          }
        }
      },
      "conditionalVisibility": {
        "parameterName": "selectedTab",
        "comparison": "isEqualTo",
        "value": "gr8"
      },
      "name": "query - 2"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 9:\" \r\n| project ['VNet Name']=VNETName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\r\n",
        "size": 0,
        "title": "GR 9",
        "timeContext": {
          "durationMs": 3600000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      },
      "conditionalVisibility": {
        "parameterName": "selectedTab",
        "comparison": "isEqualTo",
        "value": "gr9"
      },
      "name": "query - 3"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 10:\" \r\n| project ItemName_s,DisplayName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\r\n| sort by Status asc",
        "size": 0,
        "title": "GR 10",
        "timeContext": {
          "durationMs": 3600000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      },
      "conditionalVisibility": {
        "parameterName": "selectedTab",
        "comparison": "isEqualTo",
        "value": "gr10"
      },
      "name": "query - 2 - Copy - Copy - Copy"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 11:\" \r\n| project ItemName_s,DisplayName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\r\n| sort by Status asc",
        "size": 0,
        "title": "GR 11",
        "timeContext": {
          "durationMs": 3600000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      },
      "conditionalVisibility": {
        "parameterName": "selectedTab",
        "comparison": "isEqualTo",
        "value": "gr11"
      },
      "name": "query - 2 - Copy - Copy - Copy - Copy"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "GuardrailsCompliance_CL\n| where ControlName_s has \"GUARDRAIL 12:\" \n| project SubnetName=SubnetName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\n| sort by Status asc",
        "size": 0,
        "title": "GR12",
        "timeContext": {
          "durationMs": 3600000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces",
        "gridSettings": {
          "hierarchySettings": {
            "treeType": 1
          }
        }
      },
      "conditionalVisibility": {
        "parameterName": "selectedTab",
        "comparison": "isEqualTo",
        "value": "gr12"
      },
      "name": "query - 2 - Copy"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 12:\" \r\n| project SubnetName=SubnetName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\r\n| sort by Status asc",
        "size": 0,
        "title": "GR12",
        "timeContext": {
          "durationMs": 3600000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces",
        "gridSettings": {
          "sortBy": [
            {
              "itemKey": "$gen_count_$gen_group_0",
              "sortOrder": 1
            }
          ]
        },
        "sortBy": [
          {
            "itemKey": "$gen_count_$gen_group_0",
            "sortOrder": 1
          }
        ]
      },
      "conditionalVisibility": {
        "parameterName": "selectedTab",
        "comparison": "isEqualTo",
        "value": "gr12"
      },
      "name": "query - 2 - Copy"
    }
  ],
  "fallbackResourceIds": [
'''
var wbConfig2='"/subscriptions/${subscriptionId}/resourceGroups/${rg}/providers/Microsoft.OperationalInsights/workspaces/${logAnalyticsWorkspaceName}"'
var wbConfig3='''
  ]
}
'''
var wbConfig='${wbConfig1}${wbConfig2}${wbConfig3}'
//Resources:
//KeyVault

resource guardrailsAC 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: automationAccountName
  location: location
  identity: {
     type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: true
    disableLocalAuth: false
    sku: {
        name: 'Basic'
    }
    encryption: {
        keySource: 'Microsoft.Automation'
        identity: {}
    }
  }
  resource OMSModule 'modules' ={
    name: 'OMSIngestionAPI'
    properties: {
      contentLink: {
        uri: 'https://devopsgallerystorage.blob.core.windows.net/packages/omsingestionapi.1.6.0.nupkg'
        version: '1.6.0'
      }
    }
  }
  resource AzureGraph 'modules' ={
    name: 'AzureGraph'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/AzureGraph.zip'
        version: '1.0.0'
      }
    }
  }
  resource module1 'modules' ={
    name: 'Check-BreackGlassAccountOwnersInformation'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Check-BreackGlassAccountOwnersInformation.zip'
        version: '1.0.0'
      }
    }
  }
resource module2 'modules' ={
    name: 'Check-BreakGlassAccountIdentityProtectionLicense'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Check-BreakGlassAccountIdentityProtectionLicense.zip'
        version: '1.0.0'
      }
    }
  }
resource module3 'modules' ={
    name: 'Check-BreakGlassAccountProcedure'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Check-BreakGlassAccountProcedure.zip'
        version: '1.0.0'
      }
    }
  }
resource module4 'modules' ={
    name: 'Check-DeprecatedAccounts'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Check-DeprecatedAccounts.zip'
        version: '1.0.0'
      }
    }
  }
resource module5 'modules' ={
    name: 'Check-ExternalAccounts'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Check-ExternalAccounts.zip'
        version: '1.0.0'
      }
    }
  }
resource module6 'modules' ={
    name: 'Check-GuardRailsConditionalAccessPolicie'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Check-GuardRailsConditionalAccessPolicie.zip'
        version: '1.0.0'
      }
    }
  }
resource module7 'modules' ={
    name: 'Check-MonitorAccount'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Check-MonitorAccount.zip'
        version: '1.0.0'
      }
    }
  }
resource module8 'modules' ={
    name: 'Check-PBMMPolicy'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Check-PBMMPolicy.zip'
        version: '1.0.0'
      }
    }
  }
resource module9 'modules' ={
    name: 'Check-SubnetComplianceStatus'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Check-SubnetComplianceStatus.zip'
        version: '1.0.0'
      }
    }
  }
resource module10 'modules' ={
    name: 'Check-VNetComplianceStatus'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Check-VNetComplianceStatus.zip'
        version: '1.0.0'
      }
    }
  }
resource module11 'modules' ={
    name: 'Detect-UserBGAUsersAuthMethods'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Detect-UserBGAUsersAuthMethods.zip'
        version: '1.0.0'
      }
    }
  }
resource module12 'modules' ={
    name: 'Get-AzureADLicenseType'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Get-AzureADLicenseType.zip'
        version: '1.0.0'
      }
    }
  }
resource module13 'modules' ={
    name: 'Get-Tags'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Get-Tags.zip'
        version: '1.0.0'
      }
    }
  }
resource module14 'modules' ={
    name: 'Validate-BreakGlassAccount'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Validate-BreakGlassAccount.zip'
        version: '1.0.0'
      }
    }
  }
  resource module15 'modules' ={
    name: 'Check-AllowedLocationPolicy'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Check-AllowedLocationPolicy.zip'
        version: '1.0.0'
      }
    }
  }
  resource module16 'modules' ={
    name: 'Check-PrivateMarketPlace'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Check-PrivateMarketPlace.zip'
        version: '1.0.0'
      }
    }
  }
  resource module17 'modules' ={
    name: 'Az.Marketplace'
    properties: {
      contentLink: {
        uri: 'https://devopsgallerystorage.blob.core.windows.net:443/packages/az.marketplace.0.3.0.nupkg'
        version: '0.3.0'
      }
    }
    dependsOn: [
      module18
    ]
  }
  resource module18 'modules' ={
    name: 'Az.Accounts'
    properties: {
      contentLink: {
        uri: 'https://devopsgallerystorage.blob.core.windows.net:443/packages/az.accounts.2.7.2.nupkg'
        version: '0.3.0'
      }
    }
  }
  resource module19 'modules' ={
    name: 'Check-CyberSecurityServices'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Check-CyberSecurityServices.zip'
        version: '1.0.0'
      }
    }
  }
  resource module20 'modules' ={
    name: 'Check-LoggingAndMonitoring'
    properties: {
      contentLink: {
        uri: '${CustomModulesBaseURL}/Check-LoggingAndMonitoring.zip'
        version: '1.0.0'
      }
    }
  }
  resource variable1 'variables' = {
    name: 'KeyvaultName'
    properties: {
        isEncrypted: false
        value: '"${guardrailsKV.name}"'
    }
  }
  
  resource variable2 'variables' = {
    'name': 'WorkSpaceID'
    'properties': {
        'isEncrypted': false
        'value': '"${guardrailsLogAnalytics.properties.customerId}"'
    }
  }
  resource variable3 'variables' = {
    'name': 'LogType'
    'properties': {
        'isEncrypted': false
        'value': '"GuardrailsCompliance"'
    }
  }
  resource variable4 'variables' = {
    'name': 'PBMMPolicyID'
    'properties': {
        'isEncrypted': false
        'value': '"/providers/Microsoft.Authorization/policySetDefinitions/${PBMMPolicyID}"'
    }
  }
  resource variable5 'variables' = {
    'name': 'GuardrailWorkspaceIDKeyName'
    'properties': {
        'isEncrypted': false
        'value': '"WorkSpaceKey"'
    }
  }
  resource variable6 'variables' = {
    'name': 'StorageAccountName'
    'properties': {
        'isEncrypted': false
        'value': '"${guardrailsStorage.name}"'
    }
  }
  resource variable7 'variables' = {
    'name': 'ContainerName'
    'properties': {
        'isEncrypted': false
        'value': '"${containername}"'
    }
  }
  resource variable8 'variables' = {
    'name': 'ResourceGroupName'
    'properties': {
        'isEncrypted': false
        'value': '"${resourceGroup().name}"'
    }
  }
  resource variable9 'variables' = {
    'name': 'AllowedLocationPolicyId'
    'properties': {
        'isEncrypted': false
        'value': '"/providers/Microsoft.Authorization/policyDefinitions/${AllowedLocationPolicyId}"'
    }
  }
  resource variable10 'variables' = {
    name: 'DepartmentNumber'
    'properties': {
      'isEncrypted': false
      'value': '"${DepartmentNumber}"'
  }
  }
  resource variable11 'variables' = {
    name: 'CBSSubscriptionName'
    'properties': {
      'isEncrypted': false
      'value': '"${CBSSubscriptionName}"'
  }
  }
  resource variable12 'variables' = {
    name: 'SecurityLAWResourceId'
    'properties': {
      'isEncrypted': false
      'value': '"${SecurityLAWResourceId}"'
  }
  }
  resource variable14 'variables' = {
    name: 'HealthLAWResourceId'
    'properties': {
      'isEncrypted': false
      'value': '"${HealthLAWResourceId}"'
  }
  }
}

resource guardrailsKV 'Microsoft.KeyVault/vaults@2021-06-01-preview' = if (deployKV) {
  name: kvName
  location: location
  properties: {
    sku: {
      family: 'A'
      name:  'standard'
    }
    tenantId: guardrailsAC.identity.tenantId
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: false
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: true
    vaultUri: vaultUri
    provisioningState: 'Succeeded'
    publicNetworkAccess: 'Enabled'
  }
}

resource guardrailsLogAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = if (deployLAW) {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource guarrailsWorkbooks 'Microsoft.Insights/workbooks@2021-08-01' = if (deployLAW) {
location: location
kind: 'shared'
name: guid('guardrails')
properties:{
  displayName: 'Guardrails'
  serializedData: wbConfig
  version: '1.0'
  category: 'workbook'
  sourceId: guardrailsLogAnalytics.id
}

}
//Storage Account
resource guardrailsStorage 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    supportsHttpsTrafficOnly: true
  }
  resource blobServices 'blobServices'={
    name: 'default'
    properties: {
        cors: {
            corsRules: []
        }
        deleteRetentionPolicy: {
            enabled: false
        }
    }
    resource container1 'containers'={
      name: containername
      properties: {
        immutableStorageWithVersioning: {
            enabled: false
        }
        denyEncryptionScopeOverride: false
        defaultEncryptionScope: '$account-encryption-key'
        publicAccess: 'None'
      }
    }
    resource container2 'containers'={
      name: 'psmodules'
      properties: {
        immutableStorageWithVersioning: {
            enabled: false
        }
        denyEncryptionScopeOverride: false
        defaultEncryptionScope: '$account-encryption-key'
        publicAccess: 'None'
      }
    }
  }
}


