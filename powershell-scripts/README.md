# Microsoft Azure PowerShell Scripts

This repository contains PowerShell Scripts for developers and administrators to develop, deploy, and manage Microsoft Azure resources & applications.

## Resource Scripts List

| Resource
| ---------------------
| [API Management](powershell-scripts/api-management)

## Usage

> TBD: please check each Azure Resource scripts readme page

## Installation & Environment Set Up

In order to execute the different Azure Poershell Scripts its is strictly required to have Powershell and the corresponding Azure Powershell Module:

### PowerShell Core

PowerShell Core is open source. See the following articles for more information on installing PowerShell Core on various supported and experimental platforms.

- [Installing PowerShell Core on Windows][InstallingPowerShellCoreWindows]
- [Installing PowerShell Core on macOS][InstallingPowerShellCoreMac]
- [Installing PowerShell Core on Linux][InstallingPowerShellCoreLinux]

> For more information about installing the legacy versions of PowerShell on Windows, see [Installing Windows PowerShell][InstallingWindowsPowerShell].

### Powershell Modules

Below is a table containing necessary Azure PowerShell modules in order to run the scripts.

Description       | Module Name  | PowerShell Gallery Link
----------------- | ------------ | -----------------------
Azure PowerShell  | `Az`         | [![Az]][AzGallery]

Run the following command in an elevated PowerShell session to install the rollup module for Azure PowerShell cmdlets:

```powershell
Install-Module -Name Az
```

> Note: *These scripts run on Windows PowerShell with [.NET Framework 4.7.2][DotNetFramework] or greater, or [PowerShell Core][PowerShellCore]. The `Az` module replaces `AzureRM`. You should not install `Az` side-by-side with `AzureRM`.*

If you have an earlier version of the Azure PowerShell modules installed from the PowerShell Gallery and would like to update to the latest version, run the following commands in an elevated PowerShell session:

<details>
  <summary>Azure Module Usage  (Click to expand)</summary>

### Azure Module Usage

#### Log into Azure

To connect to Azure, use the [`Connect-AzAccount`][ConnectAzAccount] cmdlet:

```powershell
# Device Code login - Provides a link to sign into Azure via your web browser
Connect-AzAccount

# Service Principal login - Use a previously created service principal to log in
Connect-AzAccount -ServicePrincipal -ApplicationId 'http://my-app' -Credential $PSCredential -TenantId $TenantId
```

#### Getting and setting your Azure PowerShell session context

A session context persists login information across Azure PowerShell modules and PowerShell instances. To view the context you are using in the current session, which contains the subscription and tenant, use the [`Get-AzContext`][GetAzContext] cmdlet:

```powershell
# Gets the Azure PowerShell context for the current PowerShell session
Get-AzContext

# Lists all available Azure PowerShell contexts in the current PowerShell session
Get-AzContext -ListAvailable
```

For details on Azure PowerShell contexts, see our [persisted credentials guide][PersistedCredentialsGuide].

#### Discovering cmdlets

Use the `Get-Command` cmdlet to discover cmdlets within a specific module, or cmdlets that follow a specific search pattern:

```powershell
# List all cmdlets in the Az.Accounts module
Get-Command -Module Az.Accounts

# List all cmdlets that contain VirtualNetwork
Get-Command -Name '*VirtualNetwork*'

# List all cmdlets that contain VM in the Az.Compute module
Get-Command -Module Az.Compute -Name '*VM*'
```

#### Cmdlet help and examples

To view the help content for a cmdlet, use the `Get-Help` cmdlet:

```powershell
# View the basic help content for Get-AzSubscription
Get-Help -Name Get-AzSubscription

# View the examples for Get-AzSubscription
Get-Help -Name Get-AzSubscription -Examples

# View the full help content for Get-AzSubscription
Get-Help -Name Get-AzSubscription -Full

# View the help content for Get-AzSubscription on https://docs.microsoft.com
Get-Help -Name Get-AzSubscription -Online
```

For detailed instructions on using Azure PowerShell, please refer to the [getting started guide][GettingStartedGuide].

## Learn More

* [Microsoft Azure Documentation][MicrosoftAzureDocs]
* [PowerShell Documentation][PowerShellDocs]

</details>

<!-- References -->

<!-- Powershell Installation -->
[InstallingWindowsPowerShell]: https://docs.microsoft.com/en-gb/powershell/scripting/install/installing-windows-powershell?view=powershell-7
[InstallingPowerShellCoreWindows]: https://docs.microsoft.com/en-gb/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7
[InstallingPowerShellCoreMac]: https://docs.microsoft.com/en-gb/powershell/scripting/install/installing-powershell-core-on-macos?view=powershell-7
[InstallingPowerShellCoreLinux]: https://docs.microsoft.com/en-gb/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7

<!-- Local -->
[GitHubIssues]: https://github.com/Azure/azure-powershell/issues

[Contributing]: CONTRIBUTING.md

[AzureIcon]: documentation/images/MicrosoftAzure-32px.png
[PowershellIcon]: documentation/images/MicrosoftPowerShellCore-32px.png
[AzurePowerShelModules]: documentation/azure-powershell-modules.md
[DeveloperGuide]: documentation/development-docs/azure-powershell-developer-guide.md

<!-- External -->
[Az]: https://img.shields.io/powershellgallery/v/Az.svg?style=flat-square&label=Az
[AzGallery]: https://www.powershellgallery.com/packages/Az/

[DotNetFramework]: https://dotnet.microsoft.com/download/dotnet-framework-runtime
[PowerShellCore]: https://github.com/PowerShell/PowerShell/releases/latest

[CloudShell]: https://shell.azure.com/powershell
[CloudShellIcon]: https://shell.azure.com/images/launchcloudshell.png "Launch Azure Cloud Shell"

[ContributionGuidelines]: https://azure.github.io/guidelines/
[CodeOfConduct]: https://opensource.microsoft.com/codeofconduct/
[CodeOfConductFaq]: https://opensource.microsoft.com/codeofconduct/faq/
[OpenCodeEmail]: mailto:opencode@microsoft.com

<!-- Docs -->
[MicrosoftAzureDocs]: https://docs.microsoft.com/en-us/azure/
[PowerShellDocs]: https://docs.microsoft.com/en-us/powershell/

[InstallationGuide]: https://docs.microsoft.com/en-us/powershell/azure/install-az-ps
[GettingStartedGuide]: https://docs.microsoft.com/en-us/powershell/azure/get-started-azureps
[PersistedCredentialsGuide]: https://docs.microsoft.com/en-us/powershell/azure/context-persistence

[ConnectAzAccount]: https://docs.microsoft.com/en-us/powershell/module/az.accounts/connect-azaccount
[GetAzContext]: https://docs.microsoft.com/en-us/powershell/module/az.accounts/get-azcontext
[GetAzSubscription]: https://docs.microsoft.com/en-us/powershell/module/az.accounts/get-azsubscription
[SetAzContext]: https://docs.microsoft.com/en-us/powershell/module/az.accounts/set-azcontext
[SendFeedback]: https://docs.microsoft.com/en-us/powershell/module/az.accounts/send-feedback