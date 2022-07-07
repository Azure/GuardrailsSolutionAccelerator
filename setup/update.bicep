//Scope
targetScope = 'resourceGroup'
//Parameters and variables
param subscriptionId string
param location string = 'canadacentral'
param logAnalyticsWorkspaceName string = 'guardrails-LAW'
param workbookNameGuid string
param newWorkbookVersion string
param version string
param releaseDate string
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
      "type": 9,
      "content": {
        "version": "KqlParameterItem/1.0",
        "parameters": [
          {
            "id": "618c9321-a3de-4287-b4cf-860a4adf42d4",
            "version": "KqlParameterItem/1.0",
            "name": "RunTime",
            "label": "Report Time",
            "type": 2,
            "isRequired": true,
            "query": "GuardrailsCompliance_CL\n| summarize by ReportTime_s",
            "value": "05-07-2022 04:27:10",
            "typeSettings": {
              "additionalResourceOptions": []
            },
            "timeContext": {
              "durationMs": 86400000
            },
            "queryType": 0,
            "resourceType": "microsoft.operationalinsights/workspaces"
          }
        ],
        "style": "pills",
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      },
      "name": "parameters - 1"
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
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 1\" and ReportTime_s == \"{RunTime}\"\r\n|project ItemName=ItemName_s, Comments=Comments_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ ')",
        "size": 0,
        "title": "GR 1",
        "timeContext": {
          "durationMs": 86400000
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
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 2\" and ReportTime_s == \"{RunTime}\"\r\n|project ItemName=ItemName_s, Comments=Comments_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ ')",
        "size": 0,
        "title": "GR 2",
        "timeContext": {
          "durationMs": 86400000
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
          "durationMs": 86400000
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
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 4\" and ReportTime_s == \"{RunTime}\"\r\n|project ItemName=ItemName_s, Comments=Comments_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ ')",
        "size": 0,
        "title": "GR 4",
        "timeContext": {
          "durationMs": 86400000
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
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 5:\"  and ReportTime_s == \"{RunTime}\"\r\n| project ItemName_s,DisplayName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\r\n| sort by Status asc",
        "size": 0,
        "title": "GR 5",
        "timeContext": {
          "durationMs": 86400000
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
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 6:\"  and ReportTime_s == \"{RunTime}\"\r\n| project ItemName_s,DisplayName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\r\n| sort by Status asc",
        "size": 0,
        "title": "GR 6",
        "timeContext": {
          "durationMs": 86400000
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
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 7:\" and ReportTime_s == \"{RunTime}\"\r\n| project ItemName_s,DisplayName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\r\n| sort by Status asc",
        "size": 0,
        "title": "GR 7",
        "timeContext": {
          "durationMs": 86400000
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
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 8:\"  and ReportTime_s == \"{RunTime}\"\r\n| project SubnetName=SubnetName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\r\n| sort by Status asc",
        "size": 0,
        "title": "GR 8",
        "timeContext": {
          "durationMs": 86400000
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
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 9:\"  and ReportTime_s == \"{RunTime}\"\r\n| project ['VNet Name']=VNETName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\r\n",
        "size": 0,
        "title": "GR 9",
        "timeContext": {
          "durationMs": 86400000
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
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 10:\"  and ReportTime_s == \"{RunTime}\"\r\n| project ItemName_s,DisplayName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\r\n| sort by Status asc",
        "size": 0,
        "title": "GR 10",
        "timeContext": {
          "durationMs": 86400000
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
        "query": "GuardrailsCompliance_CL\r\n| where ControlName_s has \"GUARDRAIL 11:\"  and ReportTime_s == \"{RunTime}\"\r\n| project ItemName_s,DisplayName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\r\n| sort by Status asc",
        "size": 0,
        "title": "GR 11",
        "timeContext": {
          "durationMs": 86400000
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
        "query": "GuardrailsCompliance_CL\n| where ControlName_s has \"GUARDRAIL 12:\"  and ReportTime_s == \"{RunTime}\"\n| project SubnetName=SubnetName_s, Status=iif(tostring(ComplianceStatus_b)==\"True\", '✔️ ', '❌ '), Comments=Comments_s\n| sort by Status asc",
        "size": 0,
        "title": "GR12",
        "timeContext": {
          "durationMs": 86400000
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
      "type": 12,
      "content": {
        "version": "NotebookGroup/1.0",
        "groupType": "editable",
        "items": [
          {
            "type": 3,
            "content": {
              "version": "KqlItem/1.0",
              "query": "GuardrailsCompliance_CL \n| extend Status=iif(tostring(ComplianceStatus_b)==\"True\", 'Compliant ', 'Not Compliant'), Title=\"Items by Compliance\"\n| summarize Total=count() by Status, Title",
              "size": 4,
              "timeContext": {
                "durationMs": 86400000
              },
              "queryType": 0,
              "resourceType": "microsoft.operationalinsights/workspaces",
              "visualization": "tiles",
              "tileSettings": {
                "showBorder": false,
                "titleContent": {
                  "columnMatch": "Status",
                  "formatter": 1
                },
                "leftContent": {
                  "columnMatch": "Total",
                  "formatter": 12,
                  "formatOptions": {
                    "palette": "auto"
                  },
                  "numberFormat": {
                    "unit": 17,
                    "options": {
                      "maximumSignificantDigits": 3,
                      "maximumFractionDigits": 2
                    }
                  }
                }
              }
            },
            "name": "query - 16"
          },
          {
            "type": 3,
            "content": {
              "version": "KqlItem/1.0",
              "query": "GuardrailsCompliance_CL\n| summarize by ControlName_s\n| count \n| extend Title=\"Total of Controls\"",
              "size": 4,
              "timeContext": {
                "durationMs": 86400000
              },
              "queryType": 0,
              "resourceType": "microsoft.operationalinsights/workspaces",
              "visualization": "tiles",
              "tileSettings": {
                "titleContent": {
                  "columnMatch": "Title",
                  "formatter": 1
                },
                "leftContent": {
                  "columnMatch": "Count",
                  "numberFormat": {
                    "unit": 17,
                    "options": {
                      "style": "decimal"
                    }
                  }
                },
                "showBorder": true,
                "size": "auto"
              }
            },
            "name": "query - 15"
          }
        ]
      },
      "name": "group - 17"
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

resource guardrailsLogAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource guarrailsWorkbooks  'Microsoft.Insights/workbooks@2021-08-01' = {
  location: location
  kind: 'shared'
    tags: {
    version: version
    releasedate: releaseDate
  }
  name: workbookNameGuid
  properties:{
    displayName: 'Guardrails'
    serializedData: wbConfig
    version: newWorkbookVersion
    category: 'workbook'
    sourceId: guardrailsLogAnalytics.id
  }
}
