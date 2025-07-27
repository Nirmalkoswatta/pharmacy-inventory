# Main Azure Deployment Script
# Provides options for different Azure deployment methods

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("aci", "aks", "app-service", "arm")]
    [string]$DeploymentType,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [string]$Location = "East US",
    [string]$RegistryName,
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Pharmacy Inventory Azure Deployment" -ForegroundColor Green
Write-Host "📋 Deployment Type: $DeploymentType" -ForegroundColor Cyan
Write-Host "📦 Resource Group: $ResourceGroup" -ForegroundColor Cyan
Write-Host "🌍 Location: $Location" -ForegroundColor Cyan

# Generate unique names if not provided
if (-not $RegistryName) {
    $RegistryName = "pharmacy$((Get-Random -Minimum 1000 -Maximum 9999))"
}

Write-Host "`n🔍 Checking prerequisites..." -ForegroundColor Yellow

# Check if Azure CLI is installed
$azVersion = az version 2>$null
if (!$azVersion) {
    Write-Host "❌ Azure CLI is not installed. Please install Azure CLI first." -ForegroundColor Red
    Write-Host "   Download from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
} else {
    Write-Host "✅ Azure CLI is installed" -ForegroundColor Green
}

# Check if logged in to Azure
$loginStatus = az account show 2>$null
if (!$loginStatus) {
    Write-Host "🔐 Please log in to Azure..."
    az login
}

$currentSubscription = az account show --query "name" --output tsv
Write-Host "✅ Logged in to Azure subscription: $currentSubscription" -ForegroundColor Green

# Check if Docker is running (for local builds)
$dockerStatus = docker info 2>$null
if (!$dockerStatus) {
    Write-Host "⚠️  Docker is not running. Some deployment types may require Docker." -ForegroundColor Yellow
}

Write-Host "`n🚀 Starting deployment..." -ForegroundColor Green

switch ($DeploymentType) {
    "aci" {
        Write-Host "📦 Deploying to Azure Container Instances..."
        
        # First build and push images
        Write-Host "🔨 Building and pushing Docker images..."
        .\azure\build-and-push.ps1 -RegistryName $RegistryName -ResourceGroup $ResourceGroup -Location $Location -ImageTag $ImageTag
        
        # Deploy to ACI
        .\azure\aci\deploy-aci.ps1 -ResourceGroup $ResourceGroup -RegistryName $RegistryName -Location $Location -ImageTag $ImageTag
    }
    
    "aks" {
        Write-Host "☸️ Deploying to Azure Kubernetes Service..."
        
        $clusterName = "$ResourceGroup-aks"
        
        # Check if kubectl is installed
        $kubectlVersion = kubectl version --client 2>$null
        if (!$kubectlVersion) {
            Write-Host "❌ kubectl is not installed. Please install kubectl first." -ForegroundColor Red
            Write-Host "   Download from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/"
            exit 1
        }
        
        # First build and push images
        Write-Host "🔨 Building and pushing Docker images..."
        .\azure\build-and-push.ps1 -RegistryName $RegistryName -ResourceGroup $ResourceGroup -Location $Location -ImageTag $ImageTag
        
        # Deploy to AKS
        .\azure\aks\deploy-aks.ps1 -ResourceGroup $ResourceGroup -ClusterName $clusterName -RegistryName $RegistryName -Location $Location -ImageTag $ImageTag
    }
    
    "app-service" {
        Write-Host "🌐 Deploying to Azure App Service..."
        
        $appServicePlan = "$ResourceGroup-plan"
        $backendAppName = "$ResourceGroup-backend-$((Get-Random -Minimum 1000 -Maximum 9999))"
        $frontendAppName = "$ResourceGroup-frontend-$((Get-Random -Minimum 1000 -Maximum 9999))"
        
        # First build and push images
        Write-Host "🔨 Building and pushing Docker images..."
        .\azure\build-and-push.ps1 -RegistryName $RegistryName -ResourceGroup $ResourceGroup -Location $Location -ImageTag $ImageTag
        
        # Deploy to App Service
        .\azure\app-service\deploy-app-service.ps1 -ResourceGroup $ResourceGroup -AppServicePlan $appServicePlan -BackendAppName $backendAppName -FrontendAppName $frontendAppName -RegistryName $RegistryName -Location $Location -ImageTag $ImageTag
    }
    
    "arm" {
        Write-Host "🏗️ Deploying using ARM templates..."
        
        # Deploy infrastructure using ARM templates
        .\azure\arm-templates\deploy-arm.ps1 -ResourceGroup $ResourceGroup -Location $Location
        
        # Read the ARM deployment outputs to get ACR name
        $armOutputs = Get-Content "./azure/arm-templates/deployment-outputs.json" | ConvertFrom-Json
        $acrName = $armOutputs.acrName
        
        # Build and push images to the created ACR
        Write-Host "🔨 Building and pushing Docker images to created ACR..."
        .\azure\build-and-push.ps1 -RegistryName $acrName -ResourceGroup $ResourceGroup -Location $Location -ImageTag $ImageTag
        
        Write-Host "✅ ARM deployment completed. Apps are being deployed automatically." -ForegroundColor Green
    }
}

Write-Host "`n🎉 Deployment process completed!" -ForegroundColor Green
Write-Host "`n📝 Useful Azure Commands:" -ForegroundColor Cyan
Write-Host "   View resource group: az group show --name $ResourceGroup"
Write-Host "   List all resources: az resource list --resource-group $ResourceGroup --output table"
Write-Host "   Delete resource group: az group delete --name $ResourceGroup --yes --no-wait"

Write-Host "`n💡 Tips:" -ForegroundColor Yellow
Write-Host "   • Monitor your resources in the Azure Portal"
Write-Host "   • Set up alerts for cost management"
Write-Host "   • Use Azure Application Insights for monitoring"
Write-Host "   • Consider setting up CI/CD pipelines for automated deployments"
