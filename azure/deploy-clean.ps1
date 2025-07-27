# Deploy Pharmacy Inventory to Existing Azure Resources
# Works with your existing setup: Resource Group 'pharmacy-inventory'

param(
    [string]$ResourceGroup = "pharmacy-inventory",
    [string]$SubscriptionId = "318d6e86-b40c-4648-829d-b2902b4b6a79",
    [string]$Location = "Canada Central",
    [string]$AppServicePlan = "ASP-pharmacyinventory-ba22"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Deploying Pharmacy Inventory to Azure ===" -ForegroundColor Green
Write-Host "Subscription: $SubscriptionId" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Cyan
Write-Host "Location: $Location" -ForegroundColor Cyan

# Generate unique names
$timestamp = Get-Date -Format "yyyyMMddHHmm"
$uniqueSuffix = Get-Random -Minimum 100 -Maximum 999
$acrName = "pharmacyacr$uniqueSuffix"
$backendAppName = "pharmacy-backend-$timestamp"
$frontendAppName = "pharmacy-frontend-$timestamp"
$cosmosAccountName = "pharmacy-cosmos-$uniqueSuffix"

Write-Host ""
Write-Host "Creating these new resources:"
Write-Host "- Container Registry: $acrName"
Write-Host "- Backend App: $backendAppName" 
Write-Host "- Frontend App: $frontendAppName"
Write-Host "- Cosmos DB: $cosmosAccountName"

# Check Azure CLI
Write-Host ""
Write-Host "Checking Azure CLI..." -ForegroundColor Yellow
try {
    $null = az version 2>$null
    Write-Host "Azure CLI is installed" -ForegroundColor Green
} catch {
    Write-Host "Azure CLI is not installed" -ForegroundColor Red
    Write-Host "Install from: https://aka.ms/installazurecliwindows"
    exit 1
}

# Login and set subscription
Write-Host "Setting up authentication..." -ForegroundColor Yellow
try {
    $currentAccount = az account show 2>$null | ConvertFrom-Json
    if ($currentAccount.id -ne $SubscriptionId) {
        az account set --subscription $SubscriptionId
    }
    Write-Host "Using subscription: $($currentAccount.name)" -ForegroundColor Green
} catch {
    Write-Host "Please log in to Azure..."
    az login
    az account set --subscription $SubscriptionId
}

# Verify resource group exists
Write-Host "Checking resource group..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "true") {
    Write-Host "Resource group exists" -ForegroundColor Green
} else {
    Write-Host "Creating resource group..."
    az group create --name $ResourceGroup --location $Location
}

# Create Container Registry
Write-Host ""
Write-Host "Creating Azure Container Registry..." -ForegroundColor Green
az acr create --resource-group $ResourceGroup --name $acrName --sku Basic --admin-enabled true

$loginServer = az acr show --name $acrName --resource-group $ResourceGroup --query "loginServer" --output tsv
Write-Host "Container Registry created: $loginServer"

# Check Docker
Write-Host ""
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    docker --version | Out-Null
    Write-Host "Docker is available" -ForegroundColor Green
    
    # Build and push images
    Write-Host "Building and pushing images..." -ForegroundColor Green
    az acr login --name $acrName
    
    # Backend
    Write-Host "Building backend..."
    Set-Location "./backend"
    az acr build --registry $acrName --image "pharmacy-backend:latest" .
    Set-Location ".."
    
    # Frontend
    Write-Host "Building frontend..."
    Set-Location "./frontend"
    az acr build --registry $acrName --image "pharmacy-frontend:latest" .
    Set-Location ".."
    
    $imagesBuilt = $true
} catch {
    Write-Host "Docker not available, will deploy basic Node.js apps" -ForegroundColor Yellow
    $imagesBuilt = $false
}

# Create Cosmos DB
Write-Host ""
Write-Host "Creating Cosmos DB..." -ForegroundColor Green
az cosmosdb create --name $cosmosAccountName --resource-group $ResourceGroup --kind MongoDB --locations regionName="$Location" failoverPriority=0

$cosmosConnectionString = az cosmosdb keys list --name $cosmosAccountName --resource-group $ResourceGroup --type connection-strings --query "connectionStrings[0].connectionString" --output tsv

# Get ACR credentials
$acrCredentials = az acr credential show --name $acrName | ConvertFrom-Json

# Create Backend App
Write-Host ""
Write-Host "Creating backend web app..." -ForegroundColor Green
az webapp create --resource-group $ResourceGroup --plan $AppServicePlan --name $backendAppName --runtime "NODE:18-lts"

# Configure backend
az webapp config appsettings set --resource-group $ResourceGroup --name $backendAppName --settings "NODE_ENV=production" "PORT=8000" "MONGO_URI=$cosmosConnectionString" "FRONTEND_URL=https://$frontendAppName.azurewebsites.net"

if ($imagesBuilt) {
    az webapp config container set --name $backendAppName --resource-group $ResourceGroup --docker-custom-image-name "$loginServer/pharmacy-backend:latest" --docker-registry-server-url "https://$loginServer" --docker-registry-server-user $acrCredentials.username --docker-registry-server-password $acrCredentials.passwords[0].value
}

# Create Frontend App  
Write-Host "Creating frontend web app..." -ForegroundColor Green
az webapp create --resource-group $ResourceGroup --plan $AppServicePlan --name $frontendAppName --runtime "NODE:18-lts"

# Configure frontend
az webapp config appsettings set --resource-group $ResourceGroup --name $frontendAppName --settings "REACT_APP_GRAPHQL_URI=https://$backendAppName.azurewebsites.net/graphql" "NODE_ENV=production"

if ($imagesBuilt) {
    az webapp config container set --name $frontendAppName --resource-group $ResourceGroup --docker-custom-image-name "$loginServer/pharmacy-frontend:latest" --docker-registry-server-url "https://$loginServer" --docker-registry-server-user $acrCredentials.username --docker-registry-server-password $acrCredentials.passwords[0].value
}

# Restart apps
Write-Host ""
Write-Host "Restarting applications..." -ForegroundColor Green
az webapp restart --name $backendAppName --resource-group $ResourceGroup
az webapp restart --name $frontendAppName --resource-group $ResourceGroup

# Show results
Write-Host ""
Write-Host "=== DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Your Pharmacy Inventory Application:" -ForegroundColor Cyan
Write-Host "Frontend:  https://$frontendAppName.azurewebsites.net" -ForegroundColor White
Write-Host "Backend:   https://$backendAppName.azurewebsites.net" -ForegroundColor White  
Write-Host "GraphQL:   https://$backendAppName.azurewebsites.net/graphql" -ForegroundColor White
Write-Host ""
Write-Host "Resources Created:" -ForegroundColor Yellow
Write-Host "- Container Registry: $acrName"
Write-Host "- Backend App: $backendAppName"
Write-Host "- Frontend App: $frontendAppName" 
Write-Host "- Cosmos DB: $cosmosAccountName"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Wait 5-10 minutes for deployment to complete"
Write-Host "2. Visit the frontend URL to test your app"
Write-Host "3. Use GraphQL playground for API testing"
Write-Host ""
Write-Host "Note: Free tier has limitations (60 CPU minutes/day)"
Write-Host "Monitor usage in Azure Portal"
Write-Host ""
Write-Host "To delete all resources:"
Write-Host "az group delete --name $ResourceGroup --yes --no-wait" -ForegroundColor Red
