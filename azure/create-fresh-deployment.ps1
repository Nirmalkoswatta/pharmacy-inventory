# Fresh Deployment Script - Alternative Region
# Creates a new deployment in a different region to bypass quota issues

param(
    [string]$NewResourceGroup = "pharmacy-fresh-$(Get-Random -Minimum 1000 -Maximum 9999)",
    [string]$Location = "eastus"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Creating Fresh Deployment to Bypass Quota Issues" -ForegroundColor Green
Write-Host "📍 Location: $Location" -ForegroundColor Cyan
Write-Host "📦 Resource Group: $NewResourceGroup" -ForegroundColor Cyan

# Create new resource group
Write-Host "`n📁 Creating new resource group..." -ForegroundColor Yellow
az group create --name $NewResourceGroup --location $Location

# Create app service plan with minimal resources
Write-Host "🏗️  Creating minimal app service plan..." -ForegroundColor Yellow
$planName = "plan-$(Get-Random -Minimum 1000 -Maximum 9999)"
az appservice plan create --name $planName --resource-group $NewResourceGroup --sku F1 --is-linux

# Create backend app
Write-Host "🔧 Creating backend app..." -ForegroundColor Yellow
$backendName = "pharmacy-backend-$(Get-Random -Minimum 1000 -Maximum 9999)"
az webapp create --resource-group $NewResourceGroup --plan $planName --name $backendName --runtime "NODE:18-lts"

# Configure app settings
Write-Host "⚙️  Configuring app settings..." -ForegroundColor Yellow
az webapp config appsettings set --resource-group $NewResourceGroup --name $backendName --settings `
    NODE_ENV=production `
    MONGODB_URI="mongodb+srv://admin:admin123@cluster0.mongodb.net/pharmacy"

Write-Host "`n✅ Fresh deployment created successfully!" -ForegroundColor Green
Write-Host "🌐 Backend URL: https://$backendName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "🏥 Health Check: https://$backendName.azurewebsites.net/health" -ForegroundColor Cyan

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Deploy your backend code to: $backendName" -ForegroundColor White
Write-Host "2. Test the health endpoint" -ForegroundColor White
Write-Host "3. If this works, delete the old resource group to free up quota" -ForegroundColor White

Write-Host "`n💡 Deployment Commands:" -ForegroundColor Cyan
Write-Host "cd ../backend" -ForegroundColor White
Write-Host "zip -r backend.zip ." -ForegroundColor White
Write-Host "az webapp deploy --resource-group $NewResourceGroup --name $backendName --src-path backend.zip --type zip" -ForegroundColor White

# Save configuration for future use
@"
ResourceGroup=$NewResourceGroup
BackendApp=$backendName
Location=$Location
Created=$(Get-Date)
"@ | Out-File -FilePath "fresh-deployment-config.txt" -Encoding UTF8

Write-Host "`n📝 Configuration saved to: fresh-deployment-config.txt" -ForegroundColor Green
