# Fresh Deployment Script for South India
param(
    [string]$NewResourceGroup = "pharmacy-southindia-$(Get-Random -Minimum 1000 -Maximum 9999)",
    [string]$Location = "southindia"
)

Write-Host "Creating Fresh Deployment in South India" -ForegroundColor Green
Write-Host "Location: $Location" -ForegroundColor Cyan
Write-Host "Resource Group: $NewResourceGroup" -ForegroundColor Cyan

# Create new resource group in South India
Write-Host ""
Write-Host "Creating new resource group in South India..." -ForegroundColor Yellow
az group create --name $NewResourceGroup --location $Location

# Create app service plan
Write-Host "Creating app service plan..." -ForegroundColor Yellow
$planName = "plan-southindia-$(Get-Random -Minimum 1000 -Maximum 9999)"
az appservice plan create --name $planName --resource-group $NewResourceGroup --sku F1 --is-linux

# Create backend app
Write-Host "Creating backend app..." -ForegroundColor Yellow
$backendName = "pharmacy-backend-si-$(Get-Random -Minimum 1000 -Maximum 9999)"
az webapp create --resource-group $NewResourceGroup --plan $planName --name $backendName --runtime "NODE:20-lts"

# Configure app settings
Write-Host "Configuring app settings..." -ForegroundColor Yellow
az webapp config appsettings set --resource-group $NewResourceGroup --name $backendName --settings NODE_ENV=production MONGODB_URI="mongodb+srv://admin:admin123@cluster0.mongodb.net/pharmacy"

Write-Host ""
Write-Host "South India deployment created successfully!" -ForegroundColor Green
Write-Host "Backend URL: https://$backendName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "Health Check: https://$backendName.azurewebsites.net/health" -ForegroundColor Cyan
Write-Host "GraphQL Endpoint: https://$backendName.azurewebsites.net/graphql" -ForegroundColor Cyan

Write-Host ""
Write-Host "To deploy your code:" -ForegroundColor Yellow
Write-Host "1. Compress-Archive -Path * -DestinationPath backend-deploy.zip -Force" -ForegroundColor White
Write-Host "2. az webapp deploy --resource-group $NewResourceGroup --name $backendName --src-path backend-deploy.zip --type zip" -ForegroundColor White

# Save info for South India deployment
"ResourceGroup=$NewResourceGroup`nBackendApp=$backendName`nLocation=$Location`nRegion=South India" | Out-File "southindia-deployment.txt"
Write-Host ""
Write-Host "South India deployment details saved to southindia-deployment.txt" -ForegroundColor Green
