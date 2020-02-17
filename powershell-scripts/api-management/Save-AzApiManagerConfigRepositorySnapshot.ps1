param
(
    # =====================
    # |   AZURE PARAMS    |
    # =====================

    [Parameter(Mandatory = $True)]  # -Username 'name.surname@domain.com'
    [String]
    $Username, # = 'name.surname@{organization-name}.onmicrosoft.com',

    [Parameter(Mandatory = $True)]
    [String]
    $SubscriptionId, # = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX',

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
    $RepositoryUserPassword , # = 'Pa$$w0rd',

    [Parameter()]   # -RepositoryProxy 'http://user:assword@ip:port'
    [String]
    $RepositoryProxy, # = 'http://user:Pa$$w0rd@ip:port',

    # =====================
    # |  Optional PARAMS  |
    # =====================

    [Parameter()]   # Use -SkipLoginAzure to not login again
    [switch]
    $LoginAzure = $False,

    [Parameter()]   # Use -SkipGitClone if already exists a repository
    [switch]
    $SkipGitClone = $False,

    [Parameter()]   # Use -UseProxy if running the script in Corp Network
    [switch]
    $UseProxy = $False,

    [Parameter()]   # Use -CleanFolder if you want to delete the cloned Repository
    [switch]
    $CleanFolder = $False,

    [Parameter()]   # Use -UpdaterepositoryChanges if you want to update the files changes such as csv
    [switch]
    $UpdaterepositoryChanges = $False,

    [Parameter()]   # Use -ContinueOnError if you want to continue executing the script if an error happens
    [switch]
    $ContinueOnError = $False,

    [Parameter()]
    [ValidateSet('primary','secondary')]
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
$StartMS = (Get-Date)

# Set Stop script if an error Ocurs
switch ($ContinueOnError)
{
    $True
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
switch ($LoginAzure)
{
    $False
    {Write-Host "=> [WARNING] User did not specify to log in Azure Portal" -ForegroundColor yellow; break}
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
if ($?) { Write-Host " [Success] Subscription set to "$Subscription.Subscription.Name -ForegroundColor green } else { Write-Host " [Error]" -ForegroundColor red};

# Get APIManager Context
Write-Host "=> Setting APImanager Context" -ForegroundColor blue -NoNewline;
$APIManagerContext = New-AzApiManagementContext -ResourceGroupName $ResourceGroup -ServiceName $ServiceName;
if ($?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor red};

$exists = Test-Path $ServiceName;
if (!$exists) {mkdir $ServiceName;};
Set-Location $ServiceName;

# Save Current Named Values to a CSV File
Write-Host "=> Saving Named Values to $ServiceName.csv as Backup" -ForegroundColor blue -NoNewline;
$namedValues = Get-AzApiManagementProperty -Context $APIManagerContext;
$namedValues | Export-CSV -Delimiter ';' -Path "$ServiceName-namedValues.csv" -NoTypeInformation;
if ($namedValues -And $?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor red};

# Save Current users to a CSV File
Write-Host "=> Saving Users to $ServiceName-users.csv as Backup" -ForegroundColor blue -NoNewline;
$APIUsers =  Get-AzApiManagementUser -Context $APIManagerContext;
$APIUsers | Export-CSV -Delimiter ';' -Path "$ServiceName-users.csv" -NoTypeInformation;
if ($APIUsers -And $?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor red};

# Save Current Subscriptions to a CSV File
Write-Host "=> Saving Subscriptions to $ServiceName-subscriptions.csv as Backup" -ForegroundColor blue -NoNewline;
$APISubscriptions =  Get-AzApiManagementSubscription -Context $APIManagerContext;
$APISubscriptions | Export-CSV -Delimiter ';' -Path "$ServiceName-subscriptions.csv" -NoTypeInformation;
if ($APISubscriptions -And $?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor red};

Set-Location ..

# Save APIManager configuration to its repository located in the Azure environment, use -Verbose -Debug for detail
Write-Host "=> Saving current Deployment APIManager Configuration: " -ForegroundColor blue -NoNewline;
$SavedGitConfigurationResult = Save-AzApiManagementTenantGitConfiguration -Context $APIManagerContext -Branch $ServiceName -PassThru;
if ($SavedGitConfigurationResult) {Write-Host $SavedGitConfigurationResult.ResultInfo -ForegroundColor green};

# Set expiry time for request according to current date + expiry time, as well as resource identifiers
Write-Host "=> Preparing to get git Credentials" -ForegroundColor blue -NoNewline
$expiry = (Get-Date) + $ExpiryTimespan;
$parameters = @{"keyType"= $KeyType;"expiry"= ('{0:yyyy-MM-ddTHH:mm:ss.000Z}' -f $expiry);}
Write-Host " [Success]" -ForegroundColor green

Write-Host "=> Setting SourceIDs" -ForegroundColor blue -NoNewline
$ResourceId = '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.ApiManagement/service/{2}/users/git' -f $SubscriptionId,$ResourceGroup,$ServiceName
if ($?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor red}

# Request & store the git credentials for both encironments
Write-Host "=> Getting git Credentials" -ForegroundColor blue -NoNewline
$GitUsername = 'apim';
$GitPassword = (Invoke-AzResourceAction -Action 'token' -ResourceId $ResourceId -Parameters $parameters -ApiVersion '2016-10-10' -Force).Value;
if ($?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor red}

# Encode Passwords for URLs
$URLEncodedGitPassword = (($GitPassword -replace '/', '%2F') -replace '@', '%40')

# Set rmote URLs with its User & Password
$CloneURL = "https://${GitUsername}:${URLEncodedGitPassword}@${ServiceName}.scm.azure-api.net"


# # ===============
# # | GIT SCRIPTS |
# # ===============

# Set Corporate proxy Settings for GIT (Comment if you are outside Corporate network)
switch ($UseProxy)
{
    $True
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

# Set Git variables to avoid throwing STD Errors
$env:GIT_REDIRECT_STDERR = '2>&1';

# Set Repo folder from repository name (Azure Dev Ops only)
$RepoFolder = $RepositoryURL.split('/')[$RepositoryURL.split('/').Length-1];

# Clone the VSTS Repository where we back-up the APIManager if user does not set -SkipGitClone
switch ($SkipGitClone)
{
    $False
    {
        $TrimmedRepositoryURL = $RepositoryURL.replace("https://","");
        # if (!$RepositoryUserPassword) {$RepositoryUserPassword = $Password};
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
Set-Location $RepoFolder

# Update APIManager VSTS Repository remotes
switch ($SkipGitClone)
{
    $False
    {
        Write-Host "=> Adding APIManager Remote Repository" -ForegroundColor blue -NoNewline
        git remote add APIRemote $CloneURL
        if ($?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor yellow}
        break
    }
    default
    {
        Write-Host "=> Setting APIManager Remote Repository " -ForegroundColor blue -NoNewline
        git remote set-url APIRemote $CloneURLgit
        if ($?) {Write-Host " [Success]" -ForegroundColor green} else {Write-Host " [Error]" -ForegroundColor yellow}
        break
    }
}

Write-Host "`n=> Fetching from master" -ForegroundColor blue
git fetch --all
git checkout master
if ($?) {Write-Host "=> [Success]" -ForegroundColor green} else {Write-Host "   [Error]" -ForegroundColor yellow}

Write-Host "`n=> Fetching from remotes" -ForegroundColor blue
git checkout --track "APIRemote/$ServiceName"
if ($?) {Write-Host "=> [Success]" -ForegroundColor green} else {Write-Host "   [Error]" -ForegroundColor yellow}

Write-Host "`n=> Getting $ServiceName APIManager Configuration" -ForegroundColor blue
git pull APIRemote $ServiceName
if ($?) {Write-Host "=> [Success]" -ForegroundColor green} else {Write-Host "   [Error]" -ForegroundColor yellow}

Write-Host "`n=> Pushing $ServiceName APIManager Configuration as a branch" -ForegroundColor blue
git push origin $ServiceName # -Force
if ($?) {Write-Host "=> [Success]" -ForegroundColor green} else {Write-Host "   [Error]" -ForegroundColor yellow}

Set-Location ..

switch ($UpdaterepositoryChanges)
{
    $True
    {
        Write-Host "`n=> Updating $ServiceName Named Values to current Scripts Repo" -ForegroundColor blue
        git checkout master
        git add "*.csv"
        git commit -m "Updating csv files after saving the current repository"
        git push origin
        if ($?) {Write-Host "=> [Success]" -ForegroundColor green} else {Write-Host "   [Error]" -ForegroundColor yellow}
        break
    }
    default
    {
        Write-Host "`n=> Warning: Repository Will not be updated (csv files)" -ForegroundColor yellow
    }
}

# ===================
# |  OTHER SCRIPTS  |
# ===================

switch ($CleanFolder)
{
    $True
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
Write-Host "Successfully" -ForegroundColor green -NoNewline
Write-Host " - Elapsed time: $($TotalMS) `n" -ForegroundColor blue