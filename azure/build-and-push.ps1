# Azure Container Registry Build and Push Script
# This script builds Docker images and pushes them to Azure Container Registry

param(
    [Parameter(Mandatory=$true)]
    [string]$RegistryName,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [string]$Location = "East US",
    [string]$ImageTag = "latest"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Azure Container Registry deployment..." -ForegroundColor Green

# Login to Azure (if not already logged in)
Write-Host "📋 Checking Azure login status..."
$loginStatus = az account show 2>$null
if (!$loginStatus) {
    Write-Host "🔐 Please log in to Azure..."
    az login
}

# Set the subscription if provided in config
if (Test-Path "./azure/config.ps1") {
    . ./azure/config.ps1
    if ($AZURE_SUBSCRIPTION_ID) {
        Write-Host "🔄 Setting subscription to: $AZURE_SUBSCRIPTION_ID"
        az account set --subscription $AZURE_SUBSCRIPTION_ID
    }
}

# Create Resource Group if it doesn't exist
Write-Host "📦 Creating resource group: $ResourceGroup"
az group create --name $ResourceGroup --location $Location

# Create Azure Container Registry
Write-Host "🏗️ Creating Azure Container Registry: $RegistryName"
az acr create --resource-group $ResourceGroup --name $RegistryName --sku Basic --admin-enabled true

# Get ACR login server
$loginServer = az acr show --name $RegistryName --resource-group $ResourceGroup --query "loginServer" --output tsv

Write-Host "📝 ACR Login Server: $loginServer" -ForegroundColor Yellow

# Login to ACR
Write-Host "🔑 Logging into Azure Container Registry..."
az acr login --name $RegistryName

# Build and push backend image
Write-Host "🔨 Building and pushing backend image..."
Set-Location -Path "./backend"
az acr build --registry $RegistryName --image "pharmacy-backend:$ImageTag" .
Set-Location -Path ".."

# Build and push frontend image
Write-Host "🔨 Building and pushing frontend image..."
Set-Location -Path "./frontend"
az acr build --registry $RegistryName --image "pharmacy-frontend:$ImageTag" .
Set-Location -Path ".."

# Get ACR credentials
Write-Host "🔑 Retrieving ACR credentials..."
$acrCredentials = az acr credential show --name $RegistryName | ConvertFrom-Json

Write-Host "`n✅ Build and push completed successfully!" -ForegroundColor Green
Write-Host "📋 Registry Details:" -ForegroundColor Cyan
Write-Host "   Login Server: $loginServer"
Write-Host "   Username: $($acrCredentials.username)"
Write-Host "   Password: $($acrCredentials.passwords[0].value)"
Write-Host "`n🐳 Images pushed:"
Write-Host "   Backend: $loginServer/pharmacy-backend:$ImageTag"
Write-Host "   Frontend: $loginServer/pharmacy-frontend:$ImageTag"

# Save credentials to file for later use
$credentialsFile = "./azure/acr-credentials.json"
@{
    loginServer = $loginServer
    username = $acrCredentials.username
    password = $acrCredentials.passwords[0].value
    backendImage = "$loginServer/pharmacy-backend:$ImageTag"
    frontendImage = "$loginServer/pharmacy-frontend:$ImageTag"
} | ConvertTo-Json | Out-File -FilePath $credentialsFile

Write-Host "💾 Credentials saved to: $credentialsFile" -ForegroundColor Yellow
Write-Host "⚠️  Keep this file secure and do not commit to version control!" -ForegroundColor Red





