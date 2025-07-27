# Deploy to Existing Azure Resources
# This script deploys your pharmacy inventory app to your existing Azure setup

param(
    [string]$ResourceGroup = "pharmacy-inventory",
    [string]$SubscriptionId = "318d6e86-b40c-4648-829d-b2902b4b6a79",
    [string]$Location = "Canada Central",
    [string]$AppServicePlan = "ASP-pharmacyinventory-ba22"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Deploying to Existing Azure Resources ===" -ForegroundColor Green
Write-Host "Subscription: $SubscriptionId" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Cyan
Write-Host "Location: $Location" -ForegroundColor Cyan
Write-Host "App Service Plan: $AppServicePlan" -ForegroundColor Cyan

# Generate unique names for new resources
$timestamp = Get-Date -Format "yyyyMMddHHmm"
$uniqueSuffix = Get-Random -Minimum 100 -Maximum 999
$acrName = "pharmacyacr$uniqueSuffix"
$backendAppName = "pharmacy-backend-$timestamp"
$frontendAppName = "pharmacy-frontend-$timestamp"
$cosmosAccountName = "pharmacy-cosmos-$uniqueSuffix"

Write-Host "`nNew resources to create:" -ForegroundColor Yellow
Write-Host "Container Registry: $acrName"
Write-Host "Backend App: $backendAppName"
Write-Host "Frontend App: $frontendAppName"
Write-Host "Cosmos DB: $cosmosAccountName"

# Check if Azure CLI is installed
Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow
try {
    $azVersion = az version 2>$null | ConvertFrom-Json
    Write-Host "✅ Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI is not installed" -ForegroundColor Red
    Write-Host "Install from: https://aka.ms/installazurecliwindows" -ForegroundColor Yellow
    
    # Try to install via winget if available
    try {
        winget --version | Out-Null
        $install = Read-Host "Install Azure CLI via winget? (y/n)"
        if ($install -eq "y") {
            Write-Host "Installing Azure CLI..."
            winget install Microsoft.AzureCLI
            Write-Host "Please restart PowerShell and run this script again." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Please install Azure CLI manually and rerun this script." -ForegroundColor Red
    }
    exit 1
}

# Login and set subscription
Write-Host "Setting up Azure authentication..." -ForegroundColor Yellow
try {
    $currentAccount = az account show 2>$null | ConvertFrom-Json
    if ($currentAccount.id -ne $SubscriptionId) {
        Write-Host "Switching to subscription: $SubscriptionId"
        az account set --subscription $SubscriptionId
    }
    $currentAccount = az account show | ConvertFrom-Json
    Write-Host "✅ Using subscription: $($currentAccount.name)" -ForegroundColor Green
} catch {
    Write-Host "Please log in to Azure..."
    az login --use-device-code
    az account set --subscription $SubscriptionId
}

# Check if Docker is available
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    docker --version | Out-Null
    Write-Host "✅ Docker is available" -ForegroundColor Green
    $dockerAvailable = $true
} catch {
    Write-Host "⚠️ Docker not found. Will try to deploy without building images." -ForegroundColor Yellow
    $dockerAvailable = $false
}

# Check if resource group exists
Write-Host "Checking existing resources..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "true") {
    Write-Host "✅ Resource group '$ResourceGroup' exists" -ForegroundColor Green
} else {
    Write-Host "❌ Resource group '$ResourceGroup' not found" -ForegroundColor Red
    Write-Host "Creating resource group..."
    az group create --name $ResourceGroup --location $Location
}

# Check if App Service Plan exists
$aspExists = az appservice plan show --name $AppServicePlan --resource-group $ResourceGroup 2>$null
if ($aspExists) {
    Write-Host "✅ App Service Plan '$AppServicePlan' exists" -ForegroundColor Green
} else {
    Write-Host "Creating App Service Plan (Free tier)..."
    az appservice plan create --name $AppServicePlan --resource-group $ResourceGroup --location $Location --sku FREE
}

# Create Azure Container Registry
Write-Host "`nCreating Azure Container Registry..." -ForegroundColor Green
az acr create --resource-group $ResourceGroup --name $acrName --sku Basic --admin-enabled true
$loginServer = az acr show --name $acrName --resource-group $ResourceGroup --query "loginServer" --output tsv

if ($dockerAvailable) {
    # Build and push images
    Write-Host "Building and pushing Docker images..." -ForegroundColor Green
    az acr login --name $acrName
    
    # Build backend
    Write-Host "Building backend image..."
    Set-Location -Path "./backend"
    az acr build --registry $acrName --image "pharmacy-backend:latest" .
    Set-Location -Path ".."
    
    # Build frontend
    Write-Host "Building frontend image..."
    Set-Location -Path "./frontend"
    az acr build --registry $acrName --image "pharmacy-frontend:latest" .
    Set-Location -Path ".."
} else {
    Write-Host "⚠️ Skipping image build (Docker not available)" -ForegroundColor Yellow
}

# Create Cosmos DB (MongoDB API)
Write-Host "Creating Cosmos DB..." -ForegroundColor Green
az cosmosdb create `
    --name $cosmosAccountName `
    --resource-group $ResourceGroup `
    --kind MongoDB `
    --locations regionName="$Location" failoverPriority=0 `
    --default-consistency-level "Session"

# Get Cosmos DB connection string
$cosmosConnectionString = az cosmosdb keys list --name $cosmosAccountName --resource-group $ResourceGroup --type connection-strings --query "connectionStrings[0].connectionString" --output tsv

# Get ACR credentials
$acrCredentials = az acr credential show --name $acrName | ConvertFrom-Json

# Create Backend Web App (Linux container)
Write-Host "Creating backend web app..." -ForegroundColor Green
az webapp create `
    --resource-group $ResourceGroup `
    --plan $AppServicePlan `
    --name $backendAppName `
    --deployment-container-image-name "node:18-alpine" `
    --runtime "NODE:18-lts"

# Configure backend app settings
Write-Host "Configuring backend app..." -ForegroundColor Green
az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $backendAppName `
    --settings `
        "NODE_ENV=production" `
        "PORT=8000" `
        "MONGO_URI=$cosmosConnectionString" `
        "FRONTEND_URL=https://$frontendAppName.azurewebsites.net"

if ($dockerAvailable) {
    # Update to use our custom image
    az webapp config container set `
        --name $backendAppName `
        --resource-group $ResourceGroup `
        --docker-custom-image-name "$loginServer/pharmacy-backend:latest" `
        --docker-registry-server-url "https://$loginServer" `
        --docker-registry-server-user $acrCredentials.username `
        --docker-registry-server-password $acrCredentials.passwords[0].value
}

# Create Frontend Web App
Write-Host "Creating frontend web app..." -ForegroundColor Green
az webapp create `
    --resource-group $ResourceGroup `
    --plan $AppServicePlan `
    --name $frontendAppName `
    --runtime "NODE:18-lts"

# Configure frontend app settings
Write-Host "Configuring frontend app..." -ForegroundColor Green
az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $frontendAppName `
    --settings `
        "REACT_APP_GRAPHQL_URI=https://$backendAppName.azurewebsites.net/graphql" `
        "NODE_ENV=production"

if ($dockerAvailable) {
    # Update to use our custom image
    az webapp config container set `
        --name $frontendAppName `
        --resource-group $ResourceGroup `
        --docker-custom-image-name "$loginServer/pharmacy-frontend:latest" `
        --docker-registry-server-url "https://$loginServer" `
        --docker-registry-server-user $acrCredentials.username `
        --docker-registry-server-password $acrCredentials.passwords[0].value
}

# Restart apps to apply changes
Write-Host "Restarting applications..." -ForegroundColor Green
az webapp restart --name $backendAppName --resource-group $ResourceGroup
az webapp restart --name $frontendAppName --resource-group $ResourceGroup

# Show deployment results
Write-Host "`n=== Deployment Complete! ===" -ForegroundColor Green
Write-Host "🌐 Your Pharmacy Inventory Application:" -ForegroundColor Cyan
Write-Host "   Frontend: https://$frontendAppName.azurewebsites.net" -ForegroundColor Green
Write-Host "   Backend:  https://$backendAppName.azurewebsites.net" -ForegroundColor Green
Write-Host "   GraphQL:  https://$backendAppName.azurewebsites.net/graphql" -ForegroundColor Green

Write-Host "`n📋 Resources Created:" -ForegroundColor Yellow
Write-Host "   Resource Group: $ResourceGroup"
Write-Host "   Container Registry: $acrName"
Write-Host "   Backend App: $backendAppName"
Write-Host "   Frontend App: $frontendAppName"
Write-Host "   Cosmos DB: $cosmosAccountName"

Write-Host "`n⏰ Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Wait 5-10 minutes for apps to fully deploy"
Write-Host "   2. Visit the frontend URL to test your application"
Write-Host "   3. Check the GraphQL playground for API testing"
Write-Host "   4. Monitor logs in Azure Portal if needed"

Write-Host "`n💰 Cost Management:" -ForegroundColor Yellow
Write-Host "   • Free tier has limitations (60 CPU minutes/day)"
Write-Host "   • Monitor usage in Azure Portal"
Write-Host "   • Consider upgrading to Basic tier for production"

Write-Host "`n🗑️ To Clean Up (delete all resources):" -ForegroundColor Red
Write-Host "   az group delete --name $ResourceGroup --yes --no-wait"

# Save deployment info
$deploymentInfo = @{
    subscriptionId = $SubscriptionId
    resourceGroup = $ResourceGroup
    location = $Location
    frontendUrl = "https://$frontendAppName.azurewebsites.net"
    backendUrl = "https://$backendAppName.azurewebsites.net"
    graphqlUrl = "https://$backendAppName.azurewebsites.net/graphql"
    deploymentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

$deploymentInfo | ConvertTo-Json | Out-File -FilePath "azure-deployment-info.json"
Write-Host "`n💾 Deployment info saved to: azure-deployment-info.json" -ForegroundColor Yellow
