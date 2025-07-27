# Azure Resource Optimization Script
# This script helps optimize your Azure resources to stay within quota limits

param(
    [string]$ResourceGroup = "pharmacy-inventory"
)

Write-Host "Azure Resource Optimization Tool" -ForegroundColor Green
Write-Host "This script will help you optimize resources to stay within Azure for Students limits" -ForegroundColor Cyan

# Check current resources
Write-Host ""
Write-Host "Current Resources:" -ForegroundColor Yellow
az resource list --resource-group $ResourceGroup --query "[].{Name:name, Type:type}" --output table

Write-Host ""
Write-Host "Current App Service Plans:" -ForegroundColor Yellow
az appservice plan list --resource-group $ResourceGroup --query "[].{Name:name, Sku:sku.name, Apps:numberOfSites}" --output table

Write-Host ""
Write-Host "Optimization Recommendations:" -ForegroundColor Cyan
Write-Host "1. Use only one App Service Plan for both frontend and backend" -ForegroundColor White
Write-Host "2. Consider using Azure Static Web Apps for the frontend (free tier)" -ForegroundColor White
Write-Host "3. Use Azure Container Instances instead of App Service for lower cost" -ForegroundColor White
Write-Host "4. Deploy frontend as static files served by the backend" -ForegroundColor White

Write-Host ""
Write-Host "Quick Actions:" -ForegroundColor Yellow
Write-Host "A - Combine frontend and backend into one app" -ForegroundColor White
Write-Host "B - Deploy frontend to Azure Static Web Apps (free)" -ForegroundColor White
Write-Host "C - Use Container Instances instead" -ForegroundColor White
Write-Host "D - Check quota usage" -ForegroundColor White

$choice = Read-Host "Enter your choice (A/B/C/D) or press Enter to skip"

switch ($choice.ToUpper()) {
    "A" {
        Write-Host "To combine apps, you can serve React build files from your Express backend" -ForegroundColor Green
        Write-Host "Add this to your backend index.js:" -ForegroundColor Cyan
        Write-Host "app.use(express.static('build'));" -ForegroundColor White
        Write-Host "app.get('*', (req, res) => res.sendFile(path.join(__dirname, 'build/index.html')));" -ForegroundColor White
    }
    "B" {
        Write-Host "Azure Static Web Apps provides free hosting for frontend apps" -ForegroundColor Green
        Write-Host "Run: az staticwebapp create --name pharmacy-frontend --source . --location centralus" -ForegroundColor Cyan
    }
    "C" {
        Write-Host "Container Instances can be more cost-effective" -ForegroundColor Green
        Write-Host "Check the scripts in the 'aci' folder for deployment" -ForegroundColor Cyan
    }
    "D" {
        Write-Host "Checking quota information..." -ForegroundColor Green
        az account show --query "{Name:name, State:state, Type:user.type}" --output table
        Write-Host "Azure for Students provides $100 credit per month" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "For immediate access, try the backend URL:" -ForegroundColor Green
Write-Host "https://pharmacy-backend-07270422.azurewebsites.net" -ForegroundColor Cyan
