param([String] $namePrefix, [String] $region, [String] $userName, [String] $password, [String] $tenantId)
if (!$namePrefix) {
    $namePrefix = $Env:namePrefix
}
if (!$region) {
    $region = $Env:region
}
if (!$userName) {
    $userName = $Env:userName
}
if (!$password) {
    $password = $Env:password
}
if (!$tenantId) {
    $tenantId = $Env:tenantId
}

$loggingPrefix = "Web Deployment ($namePrefix)"
$resourceGroupName = "$namePrefix-web"
$webAIName = "$namePrefix-web-ai"
$webAppName = "$namePrefix-web-app"
$deploymentFile = "./microservice.json"
$eventsResourceGroupName = "$namePrefix-events"

Set-Location "$PSSCriptRoot"

. ./../../scripts/functions.ps1

$directoryStart = Get-Location

if (!$namePrefix) {
    D "Either pass in the '-namePrefix' parameter when calling this script or 
    set and environment variable with the name: 'namePrefix'." $loggingPrefix
}
if (!$region) {
    D "Either pass in the '-region' parameter when calling this script or 
    set and environment variable with the name: 'region'." $loggingPrefix
}

D "Deploying the web server infrasructure." $loggingPrefix

$old_ErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'

# https://github.com/Microsoft/azure-pipelines-agent/issues/1816
$command = "az"
$result = ExecuteCommand $command $loggingPrefix "Executing first AZ call to get around Task bug."

$ErrorActionPreference = $old_ErrorActionPreference 

$command = "az login --service-principal --username $userName --password $password --tenant $tenantId"
$result = ExecuteCommand $command $loggingPrefix "Logging in the Azure CLI"

$command = "az group create -n $resourceGroupName -l $region" 
$result = ExecuteCommand $command $loggingPrefix "Creating the resource group."

$command = "az group deployment create -g $resourceGroupName --template-file ./template.json --parameters uniqueResourceNamePrefix=$namePrefix"
$result = ExecuteCommand $command $loggingPrefix "Deploying the infrastructure."

./deploy-apps.ps1 -namePrefix $namePrefix -region $region -userName $userName -password $password -tenantId $tenantId

$command = "az group deployment create -g $eventsResourceGroupName --template-file ./eventGridSubscriptions-web.json --parameters uniqueResourceNamePrefix=$namePrefix"
$result = ExecuteCommand $command $loggingPrefix "Deploying the event grid subscription."

D "Deployed the web server." $loggingPrefix