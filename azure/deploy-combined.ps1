# Combined Frontend + Backend Deployment
# This script creates a single app that serves both frontend and backend to avoid quota issues

param(
    [string]$ResourceGroup = "pharmacy-inventory",
    [string]$AppName = "pharmacy-combined-07270422"
)

Write-Host "Creating Combined Frontend + Backend Deployment" -ForegroundColor Green
Write-Host "This will serve the React frontend from the Express backend to save quota" -ForegroundColor Cyan

# Create a new app service for the combined deployment
Write-Host ""
Write-Host "Creating new app service..." -ForegroundColor Yellow
az webapp create --resource-group $ResourceGroup --plan "pharmacy-plan-07270422" --name $AppName --runtime "NODE|18-lts"

# Set up environment variables
Write-Host "Configuring app settings..." -ForegroundColor Yellow
az webapp config appsettings set --resource-group $ResourceGroup --name $AppName --settings `
    NODE_ENV=production `
    MONGODB_URI="mongodb+srv://admin:admin123@cluster0.mongodb.net/pharmacy" `
    FRONTEND_URL="https://$AppName.azurewebsites.net"

Write-Host ""
Write-Host "App created successfully!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Copy your React build files to the backend/public directory" -ForegroundColor White
Write-Host "2. Modify backend/index.js to serve static files" -ForegroundColor White
Write-Host "3. Deploy the combined application" -ForegroundColor White

Write-Host ""
Write-Host "App URL: https://$AppName.azurewebsites.net" -ForegroundColor Green
