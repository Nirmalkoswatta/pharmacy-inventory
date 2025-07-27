# Azure App Service Deployment Script
# Deploys the pharmacy inventory app using Azure App Service

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$AppServicePlan,
    
    [Parameter(Mandatory=$true)]
    [string]$BackendAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$FrontendAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$RegistryName,
    
    [string]$Location = "East US",
    [string]$Sku = "B1",
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Azure App Service deployment..." -ForegroundColor Green

# Get ACR details
$loginServer = az acr show --name $RegistryName --resource-group $ResourceGroup --query "loginServer" --output tsv
$acrCredentials = az acr credential show --name $RegistryName | ConvertFrom-Json

# Create App Service Plan
Write-Host "📋 Creating App Service Plan: $AppServicePlan"
az appservice plan create `
    --name $AppServicePlan `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku $Sku `
    --is-linux

# Create Azure Cosmos DB for MongoDB API (as managed MongoDB alternative)
$cosmosAccountName = "$ResourceGroup-cosmos-$(Get-Random -Minimum 1000 -Maximum 9999)"
Write-Host "🗄️ Creating Cosmos DB account: $cosmosAccountName"
az cosmosdb create `
    --name $cosmosAccountName `
    --resource-group $ResourceGroup `
    --kind MongoDB `
    --locations regionName="$Location" failoverPriority=0 `
    --default-consistency-level "Session" `
    --enable-multiple-write-locations false

# Get Cosmos DB connection string
$cosmosConnectionString = az cosmosdb keys list --name $cosmosAccountName --resource-group $ResourceGroup --type connection-strings --query "connectionStrings[0].connectionString" --output tsv

# Create Backend App Service
Write-Host "🔧 Creating backend App Service: $BackendAppName"
az webapp create `
    --resource-group $ResourceGroup `
    --plan $AppServicePlan `
    --name $BackendAppName `
    --deployment-container-image-name "$loginServer/pharmacy-backend:$ImageTag"

# Configure backend app settings
Write-Host "⚙️ Configuring backend app settings..."
az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $BackendAppName `
    --settings `
        "NODE_ENV=production" `
        "PORT=80" `
        "MONGO_URI=$cosmosConnectionString" `
        "FRONTEND_URL=https://$FrontendAppName.azurewebsites.net" `
        "DOCKER_REGISTRY_SERVER_URL=https://$loginServer" `
        "DOCKER_REGISTRY_SERVER_USERNAME=$($acrCredentials.username)" `
        "DOCKER_REGISTRY_SERVER_PASSWORD=$($acrCredentials.passwords[0].value)"

# Configure backend container settings
az webapp config container set `
    --name $BackendAppName `
    --resource-group $ResourceGroup `
    --docker-custom-image-name "$loginServer/pharmacy-backend:$ImageTag" `
    --docker-registry-server-url "https://$loginServer" `
    --docker-registry-server-user $acrCredentials.username `
    --docker-registry-server-password $acrCredentials.passwords[0].value

# Create Frontend App Service
Write-Host "🎨 Creating frontend App Service: $FrontendAppName"
az webapp create `
    --resource-group $ResourceGroup `
    --plan $AppServicePlan `
    --name $FrontendAppName `
    --deployment-container-image-name "$loginServer/pharmacy-frontend:$ImageTag"

# Configure frontend app settings
Write-Host "⚙️ Configuring frontend app settings..."
az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $FrontendAppName `
    --settings `
        "REACT_APP_GRAPHQL_URI=https://$BackendAppName.azurewebsites.net/graphql" `
        "DOCKER_REGISTRY_SERVER_URL=https://$loginServer" `
        "DOCKER_REGISTRY_SERVER_USERNAME=$($acrCredentials.username)" `
        "DOCKER_REGISTRY_SERVER_PASSWORD=$($acrCredentials.passwords[0].value)"

# Configure frontend container settings
az webapp config container set `
    --name $FrontendAppName `
    --resource-group $ResourceGroup `
    --docker-custom-image-name "$loginServer/pharmacy-frontend:$ImageTag" `
    --docker-registry-server-url "https://$loginServer" `
    --docker-registry-server-user $acrCredentials.username `
    --docker-registry-server-password $acrCredentials.passwords[0].value

# Enable continuous deployment from ACR
Write-Host "🔄 Enabling continuous deployment..."
az webapp deployment container config `
    --name $BackendAppName `
    --resource-group $ResourceGroup `
    --enable-cd true

az webapp deployment container config `
    --name $FrontendAppName `
    --resource-group $ResourceGroup `
    --enable-cd true

# Restart apps to apply configuration
Write-Host "🔄 Restarting applications..."
az webapp restart --name $BackendAppName --resource-group $ResourceGroup
az webapp restart --name $FrontendAppName --resource-group $ResourceGroup

# Get app URLs
$backendUrl = "https://$BackendAppName.azurewebsites.net"
$frontendUrl = "https://$FrontendAppName.azurewebsites.net"

Write-Host "`n✅ App Service deployment completed successfully!" -ForegroundColor Green
Write-Host "📋 Deployment Details:" -ForegroundColor Cyan
Write-Host "   Resource Group: $ResourceGroup"
Write-Host "   App Service Plan: $AppServicePlan"
Write-Host "   Backend App: $BackendAppName"
Write-Host "   Frontend App: $FrontendAppName"
Write-Host "   Cosmos DB: $cosmosAccountName"
Write-Host "   Backend URL: $backendUrl"
Write-Host "   Frontend URL: $frontendUrl"

# Save deployment info
$deploymentInfo = @{
    resourceGroup = $ResourceGroup
    appServicePlan = $AppServicePlan
    backendAppName = $BackendAppName
    frontendAppName = $FrontendAppName
    cosmosAccountName = $cosmosAccountName
    backendUrl = $backendUrl
    frontendUrl = $frontendUrl
    deploymentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

$deploymentInfo | ConvertTo-Json | Out-File -FilePath "./azure/app-service/deployment-info.json"

Write-Host "`n💾 Deployment info saved to: ./azure/app-service/deployment-info.json" -ForegroundColor Yellow
Write-Host "`n🌐 Your application is available at: $frontendUrl" -ForegroundColor Green
Write-Host "📊 GraphQL endpoint: $backendUrl/graphql" -ForegroundColor Green

Write-Host "`n📝 Useful commands:" -ForegroundColor Cyan
Write-Host "   View backend logs: az webapp log tail --name $BackendAppName --resource-group $ResourceGroup"
Write-Host "   View frontend logs: az webapp log tail --name $FrontendAppName --resource-group $ResourceGroup"
Write-Host "   Scale up: az appservice plan update --name $AppServicePlan --resource-group $ResourceGroup --sku P1V2"
