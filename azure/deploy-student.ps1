# Simple Deployment for Azure Student Subscription
# Handles provider registration and student subscription limitations

param(
    [string]$ResourceGroup = "pharmacy-inventory",
    [string]$SubscriptionId = "318d6e86-b40c-4648-829d-b2902b4b6a79",
    [string]$Location = "Canada Central"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Azure Student Subscription Deployment ===" -ForegroundColor Green
Write-Host "This script handles Azure for Students subscription limitations" -ForegroundColor Yellow

# Generate unique names
$timestamp = Get-Date -Format "MMddHHmm"
$backendAppName = "pharmacy-backend-$timestamp"
$frontendAppName = "pharmacy-frontend-$timestamp"
$appServicePlan = "pharmacy-plan-$timestamp"

Write-Host ""
Write-Host "Will create:" -ForegroundColor Cyan
Write-Host "- App Service Plan: $appServicePlan (Free tier)"
Write-Host "- Backend App: $backendAppName"
Write-Host "- Frontend App: $frontendAppName"

# Set subscription
Write-Host ""
Write-Host "Setting subscription..." -ForegroundColor Yellow
az account set --subscription $SubscriptionId

# Register required providers (needed for student subscriptions)
Write-Host "Registering Azure resource providers..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..."

$providers = @(
    "Microsoft.Web",
    "Microsoft.Storage", 
    "Microsoft.Insights"
)

foreach ($provider in $providers) {
    Write-Host "Registering $provider..."
    az provider register --namespace $provider --wait
}

Write-Host "Resource providers registered!" -ForegroundColor Green

# Check resource group
Write-Host ""
Write-Host "Checking resource group..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "true") {
    Write-Host "Resource group exists" -ForegroundColor Green
} else {
    Write-Host "Creating resource group..."
    az group create --name $ResourceGroup --location $Location
}

# Create App Service Plan (Free tier for student subscription)
Write-Host ""
Write-Host "Creating App Service Plan (Free tier)..." -ForegroundColor Green
az appservice plan create --name $appServicePlan --resource-group $ResourceGroup --location $Location --sku FREE --is-linux

# Create Backend Web App
Write-Host "Creating backend web app..." -ForegroundColor Green
az webapp create --resource-group $ResourceGroup --plan $appServicePlan --name $backendAppName --runtime "NODE:18-lts"

# Create simple Node.js startup for backend
Write-Host "Configuring backend app..." -ForegroundColor Green
az webapp config appsettings set --resource-group $ResourceGroup --name $backendAppName --settings "NODE_ENV=production" "PORT=8080" "SCM_DO_BUILD_DURING_DEPLOYMENT=true"

# Create Frontend Web App
Write-Host "Creating frontend web app..." -ForegroundColor Green  
az webapp create --resource-group $ResourceGroup --plan $appServicePlan --name $frontendAppName --runtime "NODE:18-lts"

# Configure frontend
az webapp config appsettings set --resource-group $ResourceGroup --name $frontendAppName --settings "REACT_APP_GRAPHQL_URI=https://$backendAppName.azurewebsites.net/graphql" "NODE_ENV=production" "SCM_DO_BUILD_DURING_DEPLOYMENT=true"

Write-Host ""
Write-Host "=== BASIC DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Your app URLs (will be ready in 5-10 minutes):" -ForegroundColor Cyan
Write-Host "Frontend: https://$frontendAppName.azurewebsites.net" -ForegroundColor White
Write-Host "Backend:  https://$backendAppName.azurewebsites.net" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Deploy your code using one of these methods:"
Write-Host "   a) GitHub Actions (recommended)"
Write-Host "   b) VS Code Azure Extension"
Write-Host "   c) ZIP deployment"
Write-Host ""
Write-Host "2. Add a database:"
Write-Host "   - For free tier: Use MongoDB Atlas (free)"
Write-Host "   - For production: Upgrade to paid tier for Cosmos DB"
Write-Host ""
Write-Host "Resources created:" -ForegroundColor Cyan
Write-Host "- App Service Plan: $appServicePlan (Free tier)"
Write-Host "- Backend App: $backendAppName"
Write-Host "- Frontend App: $frontendAppName"
Write-Host ""
Write-Host "Student Subscription Notes:" -ForegroundColor Yellow
Write-Host "- Free tier limits: Limited CPU and bandwidth"
Write-Host "- No custom domains on free tier"
Write-Host "- Apps sleep after 20 minutes of inactivity"
Write-Host ""
Write-Host "To deploy your code, you can:"
Write-Host "1. Use GitHub deployment (recommended)"
Write-Host "2. Use ZIP deployment from local files"
Write-Host ""
Write-Host "Would you like help setting up GitHub deployment? (y/n)" -ForegroundColor Cyan
