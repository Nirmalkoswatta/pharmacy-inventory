# One-Command Azure Deployment for Pharmacy Inventory
# This script sets up everything needed and deploys your application

param(
    [ValidateSet("aci", "aks", "app-service", "arm")]
    [string]$DeploymentType = "app-service",
    
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment = "dev",
    
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Pharmacy Inventory - Azure Deployment" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Green

# Load configuration
. .\azure\config.ps1

# Override config with parameters
$DEPLOYMENT_TYPE = $DeploymentType
$ENVIRONMENT = $Environment

Write-Host "`n📋 Deployment Configuration:" -ForegroundColor Yellow
Write-Host "   Subscription ID: $AZURE_SUBSCRIPTION_ID"
Write-Host "   Environment: $ENVIRONMENT"
Write-Host "   Deployment Type: $DEPLOYMENT_TYPE"
Write-Host "   Resource Group: $RESOURCE_GROUP"
Write-Host "   Location: $AZURE_DEFAULT_LOCATION"

# Verify prerequisites
Write-Host "`n🔍 Checking prerequisites..." -ForegroundColor Yellow

# Check Azure CLI
try {
    $azVersion = az version | ConvertFrom-Json
    Write-Host "   ✅ Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Azure CLI is not installed" -ForegroundColor Red
    Write-Host "      Download from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Check and set Azure subscription
Write-Host "`n🔐 Setting up Azure authentication..."
try {
    $currentAccount = az account show | ConvertFrom-Json
    if ($currentAccount.id -ne $AZURE_SUBSCRIPTION_ID) {
        Write-Host "   🔄 Switching to subscription: $AZURE_SUBSCRIPTION_ID"
        az account set --subscription $AZURE_SUBSCRIPTION_ID
    }
    Write-Host "   ✅ Using subscription: $($currentAccount.name)" -ForegroundColor Green
} catch {
    Write-Host "   🔐 Please log in to Azure..."
    az login
    az account set --subscription $AZURE_SUBSCRIPTION_ID
}

# Check Docker (if not skipping build)
if (-not $SkipBuild) {
    try {
        docker version | Out-Null
        Write-Host "   ✅ Docker is running" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Docker is not running" -ForegroundColor Red
        Write-Host "      Please start Docker Desktop"
        exit 1
    }
}

# Start deployment
Write-Host "`n🚀 Starting deployment process..." -ForegroundColor Green

# Step 1: Create resource group
Write-Host "`n📦 Step 1: Creating resource group..."
az group create --name $RESOURCE_GROUP --location $AZURE_DEFAULT_LOCATION
Write-Host "   ✅ Resource group created: $RESOURCE_GROUP" -ForegroundColor Green

# Step 2: Build and push images (unless skipped)
if (-not $SkipBuild) {
    Write-Host "`n🔨 Step 2: Building and pushing Docker images..."
    .\azure\build-and-push.ps1 -RegistryName $ACR_NAME -ResourceGroup $RESOURCE_GROUP -Location $AZURE_DEFAULT_LOCATION -ImageTag $IMAGE_TAG
} else {
    Write-Host "`n⏭️  Step 2: Skipping image build (using existing images)" -ForegroundColor Yellow
}

# Step 3: Deploy based on type
Write-Host "`n🌐 Step 3: Deploying application ($DEPLOYMENT_TYPE)..."

switch ($DEPLOYMENT_TYPE) {
    "aci" {
        .\azure\aci\deploy-aci.ps1 -ResourceGroup $RESOURCE_GROUP -RegistryName $ACR_NAME -Location $AZURE_DEFAULT_LOCATION -ImageTag $IMAGE_TAG
    }
    "aks" {
        # Check kubectl for AKS
        try {
            kubectl version --client | Out-Null
            Write-Host "   ✅ kubectl is available" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ kubectl is required for AKS deployment" -ForegroundColor Red
            exit 1
        }
        .\azure\aks\deploy-aks.ps1 -ResourceGroup $RESOURCE_GROUP -ClusterName $AKS_CLUSTER_NAME -RegistryName $ACR_NAME -Location $AZURE_DEFAULT_LOCATION -NodeCount $AKS_NODE_COUNT -NodeSize $AKS_NODE_SIZE -ImageTag $IMAGE_TAG
    }
    "app-service" {
        .\azure\app-service\deploy-app-service.ps1 -ResourceGroup $RESOURCE_GROUP -AppServicePlan $APP_SERVICE_PLAN -BackendAppName $BACKEND_APP_NAME -FrontendAppName $FRONTEND_APP_NAME -RegistryName $ACR_NAME -Location $AZURE_DEFAULT_LOCATION -Sku $APP_SERVICE_SKU -ImageTag $IMAGE_TAG
    }
    "arm" {
        .\azure\arm-templates\deploy-arm.ps1 -ResourceGroup $RESOURCE_GROUP -Location $AZURE_DEFAULT_LOCATION
        
        # Get ACR name from ARM outputs and build images
        $armOutputs = Get-Content "./azure/arm-templates/deployment-outputs.json" | ConvertFrom-Json
        if (-not $SkipBuild) {
            .\azure\build-and-push.ps1 -RegistryName $armOutputs.acrName -ResourceGroup $RESOURCE_GROUP -Location $AZURE_DEFAULT_LOCATION -ImageTag $IMAGE_TAG
        }
    }
}

# Step 4: Verify deployment
Write-Host "`n📊 Step 4: Verifying deployment..."
Start-Sleep -Seconds 30  # Wait for services to start
.\azure\status.ps1 -ResourceGroup $RESOURCE_GROUP -DeploymentType $DEPLOYMENT_TYPE

# Step 5: Show results
Write-Host "`n🎉 Deployment completed successfully!" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Green

Write-Host "`n📋 Deployment Summary:" -ForegroundColor Cyan
Write-Host "   Resource Group: $RESOURCE_GROUP"
Write-Host "   Deployment Type: $DEPLOYMENT_TYPE"
Write-Host "   Environment: $ENVIRONMENT"
Write-Host "   Location: $AZURE_DEFAULT_LOCATION"

# Show access URLs based on deployment type
switch ($DEPLOYMENT_TYPE) {
    "app-service" {
        $frontendUrl = "https://$FRONTEND_APP_NAME.azurewebsites.net"
        $backendUrl = "https://$BACKEND_APP_NAME.azurewebsites.net"
        Write-Host "`n🌐 Your application URLs:"
        Write-Host "   Frontend: $frontendUrl" -ForegroundColor Green
        Write-Host "   Backend API: $backendUrl" -ForegroundColor Green
        Write-Host "   GraphQL Playground: $backendUrl/graphql" -ForegroundColor Green
    }
    "aci" {
        Write-Host "`n🐳 Container Instance IPs are shown above"
    }
    "aks" {
        Write-Host "`n☸️  AKS cluster details are shown above"
        Write-Host "   Use: kubectl get services -n pharmacy-inventory"
    }
    "arm" {
        $armOutputs = Get-Content "./azure/arm-templates/deployment-outputs.json" | ConvertFrom-Json
        Write-Host "`n🌐 Your application URLs:"
        Write-Host "   Frontend: $($armOutputs.frontendUrl)" -ForegroundColor Green
        Write-Host "   Backend API: $($armOutputs.backendUrl)" -ForegroundColor Green
    }
}

Write-Host "`n💡 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Test your application using the URLs above"
Write-Host "   2. Monitor resources in Azure Portal"
Write-Host "   3. Set up monitoring and alerts"
Write-Host "   4. Configure custom domains if needed"

Write-Host "`n📝 Useful Commands:" -ForegroundColor Cyan
Write-Host "   Check status: .\azure\status.ps1 -ResourceGroup '$RESOURCE_GROUP'"
Write-Host "   View costs: az consumption usage list --top 10"
Write-Host "   Clean up: .\azure\cleanup.ps1 -ResourceGroup '$RESOURCE_GROUP' -Force"

Write-Host "`n💾 Configuration saved to: .\azure\config.ps1" -ForegroundColor Yellow
Write-Host "⚠️  Remember to clean up resources when done to avoid charges!" -ForegroundColor Red
