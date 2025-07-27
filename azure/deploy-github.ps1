# Direct GitHub Deployment
param(
    [string]$BackendAppName = "pharmacy-backend-07270422",
    [string]$FrontendAppName = "pharmacy-frontend-07270422",
    [string]$ResourceGroup = "pharmacy-inventory",
    [string]$GitHubRepo = "" # User will need to provide this
)

Write-Host "=== Direct Deployment to Azure App Service ===" -ForegroundColor Green
Write-Host ""

if ($GitHubRepo -eq "") {
    Write-Host "GitHub Repository URL needed for deployment." -ForegroundColor Yellow
    Write-Host "Please provide your GitHub repository URL (e.g., https://github.com/username/repo)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Alternative: Use local ZIP deployment instead:" -ForegroundColor Yellow
    Write-Host "Run: .\azure\deploy-zip.ps1 -BackendAppName '$BackendAppName' -FrontendAppName '$FrontendAppName'"
    return
}

Write-Host "Setting up GitHub deployment for:" -ForegroundColor Cyan
Write-Host "Backend:  $BackendAppName"
Write-Host "Frontend: $FrontendAppName"
Write-Host "GitHub:   $GitHubRepo"
Write-Host ""

# Configure backend for GitHub deployment
Write-Host "Configuring backend GitHub deployment..." -ForegroundColor Green
az webapp deployment source config --name $BackendAppName --resource-group $ResourceGroup --repo-url $GitHubRepo --branch main --manual-integration

# Configure frontend for GitHub deployment  
Write-Host "Configuring frontend GitHub deployment..." -ForegroundColor Green
az webapp deployment source config --name $FrontendAppName --resource-group $ResourceGroup --repo-url $GitHubRepo --branch main --manual-integration

Write-Host ""
Write-Host "=== GITHUB DEPLOYMENT CONFIGURED ===" -ForegroundColor Green
Write-Host ""
Write-Host "Your apps will pull from GitHub on each deployment:" -ForegroundColor Cyan
Write-Host "Backend:  https://$BackendAppName.azurewebsites.net"
Write-Host "Frontend: https://$FrontendAppName.azurewebsites.net"
Write-Host ""
Write-Host "To trigger deployment:" -ForegroundColor Yellow
Write-Host "1. Push your code to the main branch of your GitHub repo"
Write-Host "2. Azure will automatically detect and deploy changes"
Write-Host ""
Write-Host "Manual sync command (if needed):" -ForegroundColor Cyan
Write-Host "az webapp deployment source sync --name $BackendAppName --resource-group $ResourceGroup"
Write-Host "az webapp deployment source sync --name $FrontendAppName --resource-group $ResourceGroup"
