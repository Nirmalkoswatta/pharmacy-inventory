# 🚀 GET STARTED - Deploy Pharmacy Inventory to Azure
# Simple script to get you up and running quickly

Write-Host "🚀 Welcome to Pharmacy Inventory Azure Deployment!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green

Write-Host "`n📋 Your Azure Subscription: 318d6e86-b40c-4648-829d-b2902b4b6a79" -ForegroundColor Cyan

Write-Host "`n🎯 Choose your deployment option:" -ForegroundColor Yellow
Write-Host "   1. Quick Dev Deployment (Azure Container Instances) - ~$60/month"
Write-Host "   2. Production Ready (Azure App Service) - ~$125/month [RECOMMENDED]"
Write-Host "   3. Enterprise Scale (Azure Kubernetes Service) - ~$165/month"
Write-Host "   4. Infrastructure as Code (ARM Templates) - ~$125/month"

$choice = Read-Host "`nEnter your choice (1-4)"

$deploymentType = switch ($choice) {
    "1" { "aci" }
    "2" { "app-service" }
    "3" { "aks" }
    "4" { "arm" }
    default { 
        Write-Host "Invalid choice. Using App Service (recommended)" -ForegroundColor Yellow
        "app-service"
    }
}

$environment = Read-Host "`nEnter environment (dev/staging/prod) [dev]"
if ([string]::IsNullOrWhiteSpace($environment)) {
    $environment = "dev"
}

Write-Host "`n🚀 Starting deployment with:" -ForegroundColor Green
Write-Host "   Type: $deploymentType"
Write-Host "   Environment: $environment"

$confirmation = Read-Host "`nProceed with deployment? (y/n) [y]"
if ([string]::IsNullOrWhiteSpace($confirmation)) {
    $confirmation = "y"
}

if ($confirmation -eq "y" -or $confirmation -eq "yes") {
    Write-Host "`n🏃 Running deployment..." -ForegroundColor Green
    .\azure\deploy-now.ps1 -DeploymentType $deploymentType -Environment $environment
} else {
    Write-Host "`n❌ Deployment cancelled." -ForegroundColor Yellow
    Write-Host "`n📝 To deploy later, run:"
    Write-Host "   .\azure\deploy-now.ps1 -DeploymentType $deploymentType -Environment $environment"
}
