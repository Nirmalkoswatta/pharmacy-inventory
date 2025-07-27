# Simple Azure Deployment Script for Pharmacy Inventory
# This script deploys your application to Azure App Service

param(
    [string]$Environment = "dev"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Pharmacy Inventory Azure Deployment ===" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Cyan

# Configuration
$AZURE_SUBSCRIPTION_ID = "318d6e86-b40c-4648-829d-b2902b4b6a79"
$AZURE_DEFAULT_LOCATION = "East US"
$PROJECT_NAME = "pharmacy-inventory"
$UNIQUE_SUFFIX = Get-Random -Minimum 1000 -Maximum 9999
$RESOURCE_GROUP = "$PROJECT_NAME-$Environment-rg-$UNIQUE_SUFFIX"
$ACR_NAME = "$PROJECT_NAME$Environment$UNIQUE_SUFFIX"
$APP_SERVICE_PLAN = "$PROJECT_NAME-$Environment-plan"
$BACKEND_APP_NAME = "$PROJECT_NAME-$Environment-backend-$UNIQUE_SUFFIX"
$FRONTEND_APP_NAME = "$PROJECT_NAME-$Environment-frontend-$UNIQUE_SUFFIX"
$IMAGE_TAG = "v1.0"

Write-Host "Resource Group: $RESOURCE_GROUP" -ForegroundColor Yellow
Write-Host "ACR Name: $ACR_NAME" -ForegroundColor Yellow

# Check Azure CLI
Write-Host "Checking Azure CLI..." -ForegroundColor Yellow
try {
    $azVersion = az version | ConvertFrom-Json
    Write-Host "Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
} catch {
    Write-Host "Azure CLI is not installed" -ForegroundColor Red
    exit 1
}

# Login and set subscription
Write-Host "Setting up Azure authentication..." -ForegroundColor Yellow
try {
    $currentAccount = az account show | ConvertFrom-Json
    if ($currentAccount.id -ne $AZURE_SUBSCRIPTION_ID) {
        Write-Host "Switching to subscription: $AZURE_SUBSCRIPTION_ID"
        az account set --subscription $AZURE_SUBSCRIPTION_ID
    }
    Write-Host "Using subscription: $($currentAccount.name)" -ForegroundColor Green
} catch {
    Write-Host "Please log in to Azure..."
    az login
    az account set --subscription $AZURE_SUBSCRIPTION_ID
}

# Check Docker
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    docker version | Out-Null
    Write-Host "Docker is running" -ForegroundColor Green
} catch {
    Write-Host "Docker is not running. Please start Docker Desktop" -ForegroundColor Red
    exit 1
}

# Step 1: Create resource group
Write-Host "Step 1: Creating resource group..." -ForegroundColor Green
az group create --name $RESOURCE_GROUP --location $AZURE_DEFAULT_LOCATION

# Step 2: Create ACR and build images
Write-Host "Step 2: Creating Azure Container Registry..." -ForegroundColor Green
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --admin-enabled true

Write-Host "Building and pushing images..." -ForegroundColor Green
az acr login --name $ACR_NAME

# Build backend
Set-Location -Path "./backend"
az acr build --registry $ACR_NAME --image "pharmacy-backend:$IMAGE_TAG" .
Set-Location -Path ".."

# Build frontend  
Set-Location -Path "./frontend"
az acr build --registry $ACR_NAME --image "pharmacy-frontend:$IMAGE_TAG" .
Set-Location -Path ".."

# Step 3: Create Cosmos DB
Write-Host "Step 3: Creating Cosmos DB..." -ForegroundColor Green
$cosmosAccountName = "$RESOURCE_GROUP-cosmos-$(Get-Random -Minimum 1000 -Maximum 9999)"
az cosmosdb create --name $cosmosAccountName --resource-group $RESOURCE_GROUP --kind MongoDB --locations regionName="$AZURE_DEFAULT_LOCATION" failoverPriority=0

# Get connection string
$cosmosConnectionString = az cosmosdb keys list --name $cosmosAccountName --resource-group $RESOURCE_GROUP --type connection-strings --query "connectionStrings[0].connectionString" --output tsv

# Step 4: Create App Service Plan
Write-Host "Step 4: Creating App Service Plan..." -ForegroundColor Green
az appservice plan create --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP --location $AZURE_DEFAULT_LOCATION --sku B1 --is-linux

# Get ACR credentials
$loginServer = az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "loginServer" --output tsv
$acrCredentials = az acr credential show --name $ACR_NAME | ConvertFrom-Json

# Step 5: Create Backend App Service
Write-Host "Step 5: Creating backend app..." -ForegroundColor Green
az webapp create --resource-group $RESOURCE_GROUP --plan $APP_SERVICE_PLAN --name $BACKEND_APP_NAME --deployment-container-image-name "$loginServer/pharmacy-backend:$IMAGE_TAG"

# Configure backend
az webapp config appsettings set --resource-group $RESOURCE_GROUP --name $BACKEND_APP_NAME --settings "NODE_ENV=production" "PORT=80" "MONGO_URI=$cosmosConnectionString" "FRONTEND_URL=https://$FRONTEND_APP_NAME.azurewebsites.net" "DOCKER_REGISTRY_SERVER_URL=https://$loginServer" "DOCKER_REGISTRY_SERVER_USERNAME=$($acrCredentials.username)" "DOCKER_REGISTRY_SERVER_PASSWORD=$($acrCredentials.passwords[0].value)"

# Step 6: Create Frontend App Service
Write-Host "Step 6: Creating frontend app..." -ForegroundColor Green
az webapp create --resource-group $RESOURCE_GROUP --plan $APP_SERVICE_PLAN --name $FRONTEND_APP_NAME --deployment-container-image-name "$loginServer/pharmacy-frontend:$IMAGE_TAG"

# Configure frontend
az webapp config appsettings set --resource-group $RESOURCE_GROUP --name $FRONTEND_APP_NAME --settings "REACT_APP_GRAPHQL_URI=https://$BACKEND_APP_NAME.azurewebsites.net/graphql" "DOCKER_REGISTRY_SERVER_URL=https://$loginServer" "DOCKER_REGISTRY_SERVER_USERNAME=$($acrCredentials.username)" "DOCKER_REGISTRY_SERVER_PASSWORD=$($acrCredentials.passwords[0].value)"

# Restart apps
Write-Host "Restarting applications..." -ForegroundColor Green
az webapp restart --name $BACKEND_APP_NAME --resource-group $RESOURCE_GROUP
az webapp restart --name $FRONTEND_APP_NAME --resource-group $RESOURCE_GROUP

# Show results
Write-Host "=== Deployment Completed Successfully! ===" -ForegroundColor Green
Write-Host "Frontend URL: https://$FRONTEND_APP_NAME.azurewebsites.net" -ForegroundColor Cyan
Write-Host "Backend URL: https://$BACKEND_APP_NAME.azurewebsites.net" -ForegroundColor Cyan
Write-Host "GraphQL Playground: https://$BACKEND_APP_NAME.azurewebsites.net/graphql" -ForegroundColor Cyan

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Wait 5-10 minutes for apps to fully start"
Write-Host "2. Test your application at the frontend URL"
Write-Host "3. Monitor in Azure Portal"

Write-Host "`nTo clean up (delete all resources):" -ForegroundColor Red
Write-Host "az group delete --name $RESOURCE_GROUP --yes --no-wait"
