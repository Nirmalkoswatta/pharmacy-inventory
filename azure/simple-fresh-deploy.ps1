# Simple Fresh Deployment Script
param(
    [string]$NewResourceGroup = "pharmacy-fresh-$(Get-Random -Minimum 1000 -Maximum 9999)",
    [string]$Location = "southindia"
)

Write-Host "Creating Fresh Deployment to Bypass Quota Issues" -ForegroundColor Green
Write-Host "Location: $Location" -ForegroundColor Cyan
Write-Host "Resource Group: $NewResourceGroup" -ForegroundColor Cyan

# Create new resource group
Write-Host ""
Write-Host "Creating new resource group..." -ForegroundColor Yellow
az group create --name $NewResourceGroup --location $Location

# Create app service plan
Write-Host "Creating app service plan..." -ForegroundColor Yellow
$planName = "plan-$(Get-Random -Minimum 1000 -Maximum 9999)"
az appservice plan create --name $planName --resource-group $NewResourceGroup --sku F1 --is-linux

# Create backend app
Write-Host "Creating backend app..." -ForegroundColor Yellow
$backendName = "pharmacy-backend-$(Get-Random -Minimum 1000 -Maximum 9999)"
az webapp create --resource-group $NewResourceGroup --plan $planName --name $backendName --runtime "NODE:18-lts"

# Configure app settings
Write-Host "Configuring app settings..." -ForegroundColor Yellow
az webapp config appsettings set --resource-group $NewResourceGroup --name $backendName --settings NODE_ENV=production MONGODB_URI="mongodb+srv://admin:admin123@cluster0.mongodb.net/pharmacy"

Write-Host ""
Write-Host "Fresh deployment created successfully!" -ForegroundColor Green
Write-Host "Backend URL: https://$backendName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "Health Check: https://$backendName.azurewebsites.net/health" -ForegroundColor Cyan

Write-Host ""
Write-Host "To deploy your code:" -ForegroundColor Yellow
Write-Host "1. cd ../backend" -ForegroundColor White
Write-Host "2. Compress-Archive -Path * -DestinationPath backend.zip -Force" -ForegroundColor White
Write-Host "3. az webapp deploy --resource-group $NewResourceGroup --name $backendName --src-path backend.zip --type zip" -ForegroundColor White

# Save info
"ResourceGroup=$NewResourceGroup`nBackendApp=$backendName`nLocation=$Location" | Out-File "fresh-deployment.txt"
Write-Host ""
Write-Host "Details saved to fresh-deployment.txt" -ForegroundColor Green
