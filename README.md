<p align="center">

# GuardRails Solution Accelartor for Canadian Public Sector

</p>

 
## Introduction
 
The purpose of the reference implementation is to help Canadian Public Sector departments and agencies to identify and remediate the [GC Cloud Guardrails](https://github.com/canada-ca/cloud-guardrails#gc-cloud-guardrails)   to ensure on-going compliance with the Guardrails requirements.The GC Cloud Guardrails requirements can be found in the [Canadian Governments public GitHub repository](https://github.com/canada-ca/cloud-guardrails#summary---initial-30-days).
 

## Goals

Implementing the required GC Cloud Guardrails can take a considerable amount of time. This solution checks the environment for all [12 Cloud Guardrails Controls](https://github.com/canada-ca/cloud-guardrails#summary---initial-30-days) and provides guidance on what is required to remediate any that are non-compliant.  The solution runs on an ongoing basis, ensuring that your environment continues to meet the baseline requirements.  


## Architecture
1. The solution is deployment from the Azure Portal's cloud shell. After cloning the repository, some configuration may be done to the provided config.json file. Once triggered, the setup will deploy all the required components.

2. Azure Automation will trigger the main runbook every hour. It will fetch information from multiple sources (AAD, Azure Resources, Storage Account).

3. The data is then stored into the Log Analytics workspace.

4. The data summary and details can be visualized using the provided Guardrails workbook.

<p align="center">
<img src="./docs/media/SolutionDiagram.png " />
</p>

## Setup 
The setup document describing how to deploy the Guardrails Solution Accelerator can be found here: [Setup](./docs/setup.md)

## How it works 
The solution has multiple modules, each module verifies specific set of settings in the enviroment and compare them with the required [GC guardrails settings](https://github.com/canada-ca/cloud-guardrails#gc-cloud-guardrails) recommended by [Treasury Board of Canada](https://www.canada.ca/en/treasury-board-secretariat.html)   [and Shared Services Canada](https://www.canada.ca/en/shared-services.html), in order to understand what the modules are looking for , please check the [controls documents](./docs/controls.md)
## Contributing
This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the Microsoft Open Source Code of Conduct. For more information see the Code of Conduct FAQ or contact opencode@microsoft.com with any additional questions or comments.
## Telemetry
oft can correlate these resources used to support the deployments. Microsoft collects this information to provide the best experiences with their products and to operate their business. The telemetry is collected through customer usage attribution. The data is collected and governed by Microsoft's privacy policies, located at https://www.microsoft.com/trustcenter.

If you don't wish to send usage data to Microsoft, you can set the customerUsageAttribution.enabled setting to false in config/telemetry.json. Learn more in our Azure DevOps Pipelines onboarding guide.

Project Bicep collects telemetry in some scenarios as part of improving the product.
## License
All files except for Super-Linter in the repository are subject to the MIT license.

Super-Linter in this project is provided as an example for enabling source code linting capabilities. It is subjected to the license based on it's repository.
## Trademark
This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow Microsoft's Trademark & Brand Guidelines. Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.