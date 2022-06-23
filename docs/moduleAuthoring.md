# Creating a new module

Modules in the Guardrails solution are defined in a file called modules.json, with the structure described below.

The general steps to create a module are:

- Write PowerShell Module, sign it and zip it.
- Store the compress file in the psmodules folder
- Add module import to the bicep file. For example:

  resource module1 'modules' ={

    name: 'Check-BreackGlassAccountOwnersInformation'

    properties: {

      contentLink: {

        uri: '${CustomModulesBaseURL}/Check-BreackGlassAccountOwnersInformation.zip'

        version: '1.0.0'

      }

    }

  }

- Update modules.json file with the modules information:
{
    "ModuleName": "",
    "Control":"Guardrails",
    "ModuleType": "Builtin",
    "Status": "Enabled",
    "Script": "",
    "variables":
    [
      {
        "Name":"",
        "Value":""
      }
    ],
  "secrets":
     [
       {
         "Name":"",
         "Value":""
       }
     ],
  "localVariables":
     [
       {
         "Name":"",
         "Value":""
       }
     ]
  }

variables: references to automation account variables.

localvariables: variables added to the `$vars` object, only local to the execution of the module.

secrets: references to keyvault secrets.

All variables, localvariables and secrets are added to `$vars.xxxxx' (where xxxxx is the name in the definition above) and can be used as module parameters.

- Add automation account variable to the bicep file and update setup/config/etc if required.
    - Config.json file needs to receive a new entry.
    - In setup.ps1, the entry must be referred and, if needed, replaced in the bicep parameters template file.

## Standard variables

These variables can be used in the module calls without the needs of creating custom variables in the modules.json file.

- $WorkSpaceID : log analytics
- $LogType : the type of logs
- $KeyVaultName: name of the keyvault
- $GuardrailWorkspaceIDKeyName : Name of the variable object name in the AA containing the keyvault key.
- $ResourceGroupName : name of the resource group for guardrails.
- $StorageAccountName : Name of the Storage Account.
- $ReportTime: the unified report time for all modules in each execution.
