# Creating a new module

Modules in the Guardrails solution are defined in a file called modules.json, with the structure described below.

The general steps to create a module are:

- Write PowerShell Module, sign it and zip it.
- Store the compress file in the psmodules folder
- Add module import to the bicep file. For example:

  resource module1 'modules' ={

    name: 'Check-BreakGlassAccountOwnersInformation'

    properties: {

      contentLink: {

        uri: '${CustomModulesBaseURL}/Check-BreakGlassAccountOwnersInformation.zip'

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

## Exception Handling

Exception handing in modules is implemented using try/catch blocks and the custom function `Add-LogEntry`. `Add-LogEntry` adds an event to the custom GuardrailsComplianceException table in the Guardrails Log Analytics Workspace. When calling `Add-LogEntry`, keep the following in mind:

- Within a try/catch block, not all errors for a given cmdlet are terminating--add the `-ErrorAction Stop` parameter and value to ensure errors are caught
- Including the original exception at the end of a custom message ensures that those details are also logged. For example, `-message 'Code execution hit a error. Error message: $_'`
- `Add-LogEntry` requires a `-workspaceKey` and `-workspaceGUID` parameter be passed, in addition to `-severity` and `-message` parameters
- `Add-LogEntry` does not terminate the script or write to the host; add either a `Write-Error` or `throw` to log to the host or terminate the script

## Testing

From your fork (which will be public due to visibility inheritance) you can clone to the Cloud Shell storage normally. After that, you may edit the guardrails.bicep file and adjust the **CustomModulesBaseURL** parameter and point to the base URL of you repo. Make sure to test downloading a module to confirm the raw URL. Alternatively, add an entry to the parameters_template.json file, as per below:

`"CustomModulesBaseURL": {
      "value": "<your github base url"
    }`


