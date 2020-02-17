# API Management Scripts

> **_NOTE:_** This Documentation is on progress and will be updated soon

## Introduction

The main objective of these Scripts are:

- Save an Azure API Management Resource Configuration Snapshot to a Git Repository
- Deploy an Azure API Management Git Configuration "Snapshot" from a Repository to an API Management Resource.

> You can see how the script has been implmented and its logic on tis own code comments or at:
> [Azure API Manager VSTS CI/CD General information (TBD)](url)
> [Azure APIManager CI/CD Script Description (TBD)](url)

## Script tasks (Logic)

This script will perform the following tasks:

1. access Azure with your user credentials

2. Save the "original" APImanager to its repository

3. Save the "deployment" APImanager configurations to its repository

4. Generate Git credentials from "original" APImanager repository

5. Generate Git credentials from "deployment" APImanager repository

6. Clone a Owned repository and sync all 3 repositories to the latest "deployment changes"

7. Push latest changes to "deployment" APIManager repository

8. Publis changes to "deployment" APImanager

## Getting Started

To run this script it is required to have Powershell and Azure CMDlets:

1. [Installing Powertshell Windows](https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-6)

2. [Install Azure PowerShell with PowerShellGet](https://docs.microsoft.com/en-us/powershell/azure/install-azurerm-ps?view=azurermps-6.3.0)

## Usage

### Examples

#### Promoting from Development to SIT

To run this script it as simple as opening poweshell and run:

``` powershell
.\SaveAndCloneOriginAndDeployAPIManagers.ps1 -Username 'name.surname@domain.com' -Password 'MyPassword' -OriginResourceGroup 'Development' -OriginServiceName 'mygoodsspain' -DeployResourceGroup 'SIT' -DeployServiceName 'mygoodsspain-sit' -ContinueOnError
```

#### Validating deploying from Development to SIT

If you want to only validate if it could be deployed and debug the errors add "-ValidateOnly":

``` powershell
.\SaveAndCloneOriginAndDeployAPIManagers.ps1 -Username 'name.surname@domain.com' -Password 'MyPassword' -OriginResourceGroup 'Development' -OriginServiceName 'mygoodsspain' -DeployResourceGroup 'SIT' -DeployServiceName 'mygoodsspain-sit' -ContinueOnError -ValidateOnly
```

#### Promoting from Development to SIT within corporate network with a proxy

Or if the script is beeing executed from a corporate Network and requires proxy add "-UseProxy":

``` powershell
.\SaveAndCloneOriginAndDeployAPIManagers.ps1 -Username 'name.surname@domain.com' -Password 'MyPassword' -OriginResourceGroup 'Development' -OriginServiceName 'mygoodsspain' -DeployResourceGroup 'SIT' -DeployServiceName 'mygoodsspain-sit' -ContinueOnError -UseProxy
```

### Parameters

Parameters are set to be able to pass variables to the script in this case we are setting:
> **Note:** If a parameter is mandatory but there is a defualt value, you can skip it, but it is recommended to be passed as parameter

#### Azure Credentials & Resource Groups
Here are listed those parameters related to Azure Environments to be promoted
| Parameter            | Description                                         | Mandatory | Default value                          |
| -------------------- | --------------------------------------------------- | :-------: | -------------------------------------- |
| -Username            | Azure username access (email)                       | ✔         |                                        |
| -Password            | Azure User Password                                 | ✔         |                                        |
| -SubscriptionId      | The Azure Subscription Key assigned to your project | ✔         | 'ba2644ee-46a7-4b6f-910a-b6f7870c4cd8' |
| -OriginResourceGroup | Resource Group from the origin APIManager instance  | ✔         | 'Development'                          |
| -OriginServiceName   | Origin Azure APIManager Service Name                | ✔         |                                        |
| -DeployResourceGroup | Resource Group from the deploy APIManager instance  | ✔         | 'SIT'                                  |
| -DeployServiceName   | Deployment Azure APIManager Service Name            | ✔         |                                        |

> **Note:** Resource Groups are validated according to the implmented resoruce groups in Azure:
> **Development** / **SIT** / **UAT** / **PROD**

#### Git Repository Credentials (optional)

Here are listed the paramneters to clone all the configuration to a remote git Repository
| Parameter               | Description                                               | Mandatory | Default Value                   |
| ----------------------- | --------------------------------------------------------- | :-------: | ------------------------------- |
| -RepositoryURL          | Repository URL                                            | ✔         | MG_APIManager URL (VSTS)        |
| -RepositoryUsername     | Repository username                                       | ✔         | Temporal O.Gonzalez credentials |
| -RepositoryUserPassword | Repository user password                                  | ✔         | Temporal O.Gonzalez credentials |
| -UseProxy         | Forces to use Proxy (or an overrided one)          |           | False                           |
| -RepositoryProxy        | Overrides the Service Account with the defined one |           | Default service account         |

#### Other OPTIONAL Parameters

Here are listed those parameters that may help working with AZURE APIManager deployment processes
| Parameter        | Description                                                                           | Mandatory | Default |
| ---------------- | ------------------------------------------------------------------------------------- | :-------: | ------- |
| -SkipLoginAzure  | Use -SkipLoginAzure to not login again                                                |           | false   |
| -SkipGitClone    | Use -SkipGitClone if already exists a repository in the machine (avoid clone errors)  |           | false   |
| -ValidateOnly    | -ValidateOnly if you only want to validate & debug deployment of APIManager           |           | false   |
| -ContinueOnError | Use -ContinueOnError if you want to continue executing the script if an error happens |           | false   |
| -KeyType         | Key type credential                                                                   |           | primary |
| -ExpiryTimespan  | Git Credentials Expiry Time                                                           |           | 2 Hours |

> **Warning:** -ValidateOnly will ask the user to accept /interact with some options so it can not be launched automatically
