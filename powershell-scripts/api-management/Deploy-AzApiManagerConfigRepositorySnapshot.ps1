param
(
    # =====================
    # |   AZURE PARAMS    |
    # =====================

    [Parameter(Mandatory = $True)]  # -Username 'name.surname@domain.com'
    [String]
    $Username, # = 'name.surname@{organization-name}.onmicrosoft.com',

    [Parameter()]
    [String]
    $SubscriptionId, # = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX',

    [Parameter(Mandatory = $True)]
    [String]
    $OriginServiceName, # = 'apimanager',

    [Parameter(Mandatory = $True)]
    [String]
    $ResourceGroup, # = 'RG',

    [Parameter(Mandatory = $True)]
    [String]
    $ServiceName, # = 'apimanager',

    # =====================
    # |    GIT  PARAMS    |
    # =====================

    # Repository for APIManager BackUp Parameters

    [Parameter(Mandatory = $True)]   # -RepositoryURL 'https://...'
    [String]
    $RepositoryURL, # = 'https://dev.azure.com/{organization-name}/{project-name}/_git/{repo-name}',

    [Parameter()]   # -RepositoryUsername 'username'
    [String]
    $RepositoryUsername,

    [Parameter(Mandatory = $True)]   # -RepositoryUserPassword 'password'
    [String]
    $RepositoryUserPassword, # = 'Pa$$w0rd',

    [Parameter()]   # -RepositoryProxy 'http://user:assword@ip:port'
    [String]
    $RepositoryProxy, # = 'http://user:Pa$$w0rd@ip:port',

    # =====================
    # |  Optional PARAMS  |
    # =====================

    [Parameter()]   # Use -LoginAzure to login again
    [switch]
    $LoginAzure = $false,

    [Parameter()]   # Use -SkipGitClone if already exists a repository
    [switch]
    $SkipGitClone = $false,

    [Parameter()]   # Use -UseProxy if running the script in a corporate network with proxy
    [switch]
    $UseProxy = $false,

    [Parameter()]   # Use -CleanFolder if you want to delete the cloned Repository
    [switch]
    $CleanFolder = $false,

    [Parameter()]   # Use -ContinueOnError if you want to continue executing the script if an error happens
    [switch]
    $ContinueOnError = $false,

    [Parameter()]   # Use -Validate to validate deployment
    [switch]
    $Validate = $false,

    [Parameter()]   # Use -OverwriteNamedValues to create or update APIManager Named Values (not recomended) (overrides AddNewNamedValues)
    [switch]
    $OverwriteNamedValues = $false,

    [Parameter()]   # Use -AddNewNamedValues to create non existing APIManager Named Values from the other environment (overriden by OverwriteNamedValues)
    [switch]
    $AddNewNamedValues = $false,

    [Parameter()]   # Use -OverwriteUsers to create or update APIManager Users
    [switch]
    $OverwriteUsers = $false,

    [Parameter()]
    [ValidateSet('primary', 'secondary')]
    [String]
    $KeyType = 'primary',

    [Parameter()]
    [timespan]
    $ExpiryTimespan = (New-Timespan -Hours 2)

)


# =====================
# | PREFLIGHT SCRIPTS |
# =====================

Write-Host "`n=> Starting preflight scripts" -ForegroundColor blue

# Get start date to calculate elapsed time
$StartMS = (Get-Date);
# $NewSecurePassword = ConvertTo-SecureString 'S3cuR3.P4$$w0rd!' -AsPlainText -Force;

# Set Stop script if an error Ocurs
switch ($ContinueOnError)
{
    $true
    {
        Write-Host "=> WARNING: If an error happens the script will continue" -ForegroundColor yellow
        break
    }
    default
    {
        Write-Host "=> If an error happens the script will stop" -ForegroundColor yellow
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"
        $PSDefaultParameterValues['*:ErrorAction']='Stop'
        break
    }
}


# ===================
# |   AZURE LOGIN   |
# ===================

# If user specifies -LoginAzure, it will call the Azure LogIn Page
switch ($LoginAzure) {
    $False
    { Write-Host "=> [WARNING] User did not specify to log in Azure Portal" -ForegroundColor yellow; break }
    default {
        Write-Host "=> Logging-in with User Account in Azure Cloud Portal Services " -ForegroundColor blue -NoNewline
        #Login-AzAccount
        $Account = Login-AzAccount
        if ($Account) { Write-Host "[Success]" -ForegroundColor green; } else { Throw "User could not be logged in Azure"; Exit 0; }
        break
    }
}

# ===================
# |  AZURE SCRIPTS  |
# ===================

# Set subscription as it may change according to default subscriptions from the user
Write-Host "=> Setting Subscription" -ForegroundColor blue -NoNewline;
$Subscription = Select-AzSubscription -SubscriptionId $SubscriptionId;
if ($?) { Write-Host " [Success] Subscription set to "$Subscription.Subscription.Name -ForegroundColor green } else { Write-Host " [Error]" -ForegroundColor red };

# Get APImanager if it already exists
# Write-Host "=> Getting APImanager Instance" -ForegroundColor blue -NoNewline;
#$APIManager = Get-AzApiManagement -ResourceGroupName $ResourceGroup -Name $ServiceName;
# if ($?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor red};

# if (!$APIManager){
    #If it does not exists create apimanager
    #$APIManager = New-AzApiManagement -ResourceGroupName $ResourceGroup -Name $ServiceName -Location $Location -Organization $OrganizationName  -AdminEmail $Username
    # Throw "APIManager $ServiceName in resourceGroup $ResourceGroup can not be retrieved";
# }

# Get APIManager Context
Write-Host "=> Setting APImanager Context" -ForegroundColor blue -NoNewline;
$APIManagerContext = New-AzApiManagementContext -ResourceGroupName $ResourceGroup -ServiceName $ServiceName;
if ($?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor red};


switch ($OverwriteNamedValues)
{
    $true
    {
        #import NamedValues From CSV File, if variable exists update it, else create it
        $namedValues = Import-Csv "$OriginServiceName/$OriginServiceName-namedValues.csv" -Delimiter ';' -Encoding UTF8;
        $namedValues | ForEach-Object {
            $_.PropertyId;
            $property = Get-AzApiManagementProperty -Context $APIManagerContext -PropertyId $_.PropertyId -ErrorAction SilentlyContinue;
            if ( $property) { Set-AzApiManagementProperty -Context $APIManagerContext -PropertyId $_.PropertyId -Name $_.Name -Value $_.Value -PassThru};
            if (!$property) { New-AzApiManagementProperty -Context $APIManagerContext -PropertyId $_.PropertyId -Name $_.Name -Value $_.Value};
        };
        break
    }
    default
    {
        # If the OverwriteNamedValues is false then check to add only the new ones
        switch ($AddNewNamedValues)
        {
            $true
            {
                #import NamedValues From CSV File, if variable exists update it, else create it
                $namedValues = Import-Csv "$OriginServiceName/$OriginServiceName-namedValues.csv" -Delimiter ';' -Encoding UTF8
                $namedValues | ForEach-Object {
                    $propertyId = $_.PropertyId;
                    $propertyName =  $_.Name;

                    Write-Host "SEARCH Named Value Id: $propertyId & Name: $propertyName" -ForegroundColor blue;
                    $propertyById = Get-AzApiManagementProperty -Context $APIManagerContext -PropertyId $propertyId -ErrorAction SilentlyContinue;

                    if ($propertyById) {
                        Write-Host "   - Named Value with property Id: $propertyId [EXISTS]" -ForegroundColor green;
                        #Set-AzApiManagementProperty -Context $APIManagerContext -PropertyId $_.PropertyId -Name $_.Name -Value $_.Value -PassThru
                    };
                    if (!$propertyById) {
                        $propertyByName = Get-AzApiManagementProperty -Context $APIManagerContext -Name $propertyName -ErrorAction SilentlyContinue;
                        if ($propertyByName) {
                            Write-Host "   - [ATTENTION!] Named Value with property Name: $propertyName [EXISTS] but does not match id $propertyId" -ForegroundColor red;
                            #Set-AzApiManagementProperty -Context $APIManagerContext -PropertyId $_.PropertyId -Name $_.Name -Value $_.Value -PassThru
                        };
                        if (!$propertyByName) {
                            Write-Host "   - [WARNING] Creating New Named Value with property Name: $propertyName and id $propertyId" -ForegroundColor yellow;
                            New-AzApiManagementProperty -Context $APIManagerContext -PropertyId $_.PropertyId -Name $_.Name -Value $_.Value
                        };
                    };
                };
                break
            }
            default
            {
                break
            }
        }
        break
    }
}

# Set expiry time for request according to current date + expiry time, as well as resource identifiers
Write-Host "=> Preparing to get git Credentials" -ForegroundColor blue -NoNewline;
$expiry = (Get-Date) + $ExpiryTimespan;
$parameters = @{"keyType"= $KeyType;"expiry"= ('{0:yyyy-MM-ddTHH:mm:ss.000Z}' -f $expiry);};
Write-Host " [Success]" -ForegroundColor green;

Write-Host "=> Setting SourceIDs" -ForegroundColor blue -NoNewline;
$ResourceId = '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.ApiManagement/service/{2}/users/git' -f $SubscriptionId,$ResourceGroup,$ServiceName;
if ($?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor red}

# Request & store the git credentials for both encironments
Write-Host "=> Getting git Credentials" -ForegroundColor blue -NoNewline;
$GitUsername = 'apim';
$GitPassword = (Invoke-AzResourceAction -Action 'token' -ResourceId $ResourceId -Parameters $parameters -ApiVersion '2016-10-10' -Force).Value;
if ($?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor red};

# Encode Passwords for URLs
$URLEncodedGitPassword = (($GitPassword -replace '/', '%2F') -replace '@', '%40');

# Set rmote URLs with its User & Password
$CloneURL = "https://${GitUsername}:${URLEncodedGitPassword}@${ServiceName}.scm.azure-api.net";


# # ===============
# # | GIT SCRIPTS |
# # ===============

# Set  Proxy Settings for GIT if necessary
$env:GIT_REDIRECT_STDERR = '2>&1'

switch ($UseProxy)
{
    $true
    {
        Write-Host "=> Setting git proxy settings" -ForegroundColor blue -NoNewline;
        git config --global http.proxy $RepositoryProxy;
        if ($?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor red}
        break
    }
    default
    {
        Write-Host "=> User did not specify to use proxy git configuration" -ForegroundColor yellow;
        $currentGitConfig =  git config --global  --get http.proxy;
        if($currentGitConfig){
            Write-Host "=> Unsetting git proxy settings" -ForegroundColor blue -NoNewline;
            git config --global --unset http.proxy;
            if ($?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor red};
        }
        break
    }
}

# Clone the VSTS Repository where we back-up the APIManager if user does not set -SkipGitClone
$RepoFolder = $RepositoryURL.split('/')[$RepositoryURL.split('/').Length-1];

switch ($SkipGitClone)
{
    $false
    {
        $TrimmedRepositoryURL = $RepositoryURL.replace("https://","");
        $RepositoryUsername = (($Username -replace '/', '%2F') -replace '@', '%40');
        $RepositoryUserPassword = (($RepositoryUserPassword -replace '/', '%2F') -replace '@', '%40');
        Write-Host  "`n=> Cloning VSTS APIManager Repository " -ForegroundColor blue;
        git config --global user.email $Username;
        git config --global user.name $Username.split('@')[0];
        git clone "https://${RepositoryUsername}:${RepositoryUserPassword}@${TrimmedRepositoryURL}" ./$RepoFolder
        if ($?) {Write-Host "=> [Success]" -ForegroundColor green} else {Write-Host "   [Error]" -ForegroundColor yellow}
        break
    }
    default { "`n=> User did not specify to clone repository "; break }
}

Write-Host "`n=> Switch to APIManager Repository Folder " -ForegroundColor blue
# Get main repo Folder
$RepoFolder = $RepositoryURL.split('/')[$RepositoryURL.split('/').Length-1];
Set-Location $RepoFolder

# Update APIManager VSTS Repository remotes
switch ($SkipGitClone)
{
    $false
    {
        Write-Host "=> Adding APIManager Remote Repository" -ForegroundColor blue -NoNewline;
        git remote add APIRemote $CloneURL;
        if ($?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor yellow};
        break
    }
    default
    {
        Write-Host "=> Setting APIManager Remote Repository " -ForegroundColor blue -NoNewline;
        git remote set-url APIRemote $CloneURL;
        if ($?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor yellow};
        break
    }
}

Write-Host "`n=> Fetching from all repositories" -ForegroundColor blue
git fetch --all;
if ($?) {Write-Host "=> [Success]" -ForegroundColor green} else {Write-Host "   [Error]" -ForegroundColor yellow}

Write-Host "`n=> Checkout $OriginServiceName branch" -ForegroundColor blue
git checkout origin/$OriginServiceName;
git checkout -b $OriginServiceName;
if ($?) {Write-Host "=> [Success]" -ForegroundColor green} else {Write-Host "   [Error]" -ForegroundColor yellow}

Write-Host "`n=> Push changes to Remote $OriginServiceName branch" -ForegroundColor blue
git push APIRemote $OriginServiceName -f
if ($?) {Write-Host "=> [Success]" -ForegroundColor green} else {Write-Host "   [Error]" -ForegroundColor yellow}

switch ($Validate)
{
    $false
    {
        Write-Host "=> [Success]" -ForegroundColor green;
        Write-Host "=> Validating configuration & Deploying $OriginServiceName branch on APIManager Configuration: " -ForegroundColor blue -NoNewline;
        Publish-AzApiManagementTenantGitConfiguration -Context $APIManagerContext -Branch $OriginServiceName -PassThru -Verbose -Force;
        if ($?) {Write-Host "=> [Success]" -ForegroundColor green} else {Write-Host "   [Error]" -ForegroundColor red}
    }
    default
    {
        Write-Host "=> Validating $OriginServiceName branch on APIManager Configuration: " -ForegroundColor blue -NoNewline;
        Publish-AzApiManagementTenantGitConfiguration -Context $APIManagerContext -Branch $OriginServiceName -PassThru -Verbose -ValidateOnly -ErrorAction 'Continue' -Debug -Confirm:$false -Force
        if ($?) {
            Write-Host "=> [Success]" -ForegroundColor green;
            Write-Host "=> Deploying $OriginServiceName branch on APIManager Configuration: " -ForegroundColor blue -NoNewline;
            Publish-AzApiManagementTenantGitConfiguration -Context $APIManagerContext -Branch $OriginServiceName -PassThru -Verbose -Force;
            if ($?) {Write-Host "=> [Success]" -ForegroundColor green} else {Write-Host "   [Error]" -ForegroundColor red}
        }
        else {Write-Host " [Error]" -ForegroundColor red}
    }
}

Set-Location ..

#import NamedValues From CSV File, if variable exists update it, else create it
switch ($OverwriteUsers)
{
    $true
    {
        $APIMUsers = Import-Csv "$OriginServiceName/$OriginServiceName-users.csv" -Delimiter ';' -Encoding UTF8;
        $APIMUsers | ForEach-Object {
            if ($_.Email -And !($_.Email -eq $Username)){
                Try{
                    New-AzApiManagementUser -Context $APIManagerContext -FirstName $_.FirstName -LastName $_.LastName -Email $_.Email -Password $securePassword;
                }Catch{
                    "User Already Exists";
                };
            };
        };
        break
    }
    default
    {
        break
    }
}



# ===================
# |  OTHER SCRIPTS  |
# ===================

switch ($CleanFolder)
{
    $true
    {
        Write-Host "`n=> Removing repository folder" -ForegroundColor blue -NoNewline
        Remove-Item $RepoFolder -Recurse -Force
        if ($?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor red}
        break
    }
    default
    {
        Write-Host "`n=> Warning: Repository Folder not removed" -ForegroundColor yellow
    }
}

$TotalMS = (Get-Date) - $StartMS
Write-Host "`n=> Process finished " -ForegroundColor blue -NoNewline
Write-Host "[ SUCCESS ]" -ForegroundColor green -NoNewline
Write-Host " - Elapsed time: $($TotalMS) `n" -ForegroundColor blue