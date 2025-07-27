# Force Start Apps - Advanced 403 Fix
# Uses multiple methods to try to force start the web apps

param(
    [string]$ResourceGroup = "pharmacy-inventory"
)

Write-Host "🔧 Advanced 403 Error Fix - Force Start Method" -ForegroundColor Green

# Method 1: Scale down and up
Write-Host "`n📉 Method 1: Scale down and scale up..." -ForegroundColor Yellow
$apps = az webapp list --resource-group $ResourceGroup --query "[].name" --output tsv

foreach ($app in $apps) {
    Write-Host "Scaling down: $app" -ForegroundColor Cyan
    az webapp stop --resource-group $ResourceGroup --name $app
    Start-Sleep -Seconds 5
}

Write-Host "Waiting 10 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

foreach ($app in $apps) {
    Write-Host "Scaling up: $app" -ForegroundColor Cyan
    az webapp start --resource-group $ResourceGroup --name $app
}

# Method 2: Restart the App Service Plan
Write-Host "`n🔄 Method 2: Restart App Service Plan..." -ForegroundColor Yellow
$plans = az appservice plan list --resource-group $ResourceGroup --query "[].name" --output tsv
foreach ($plan in $plans) {
    Write-Host "Restarting plan: $plan" -ForegroundColor Cyan
    # Note: There's no direct restart for plans, so we restart all apps
    az webapp restart --resource-group $ResourceGroup --name $app
}

# Method 3: Force deployment refresh
Write-Host "`n🔄 Method 3: Force deployment refresh..." -ForegroundColor Yellow
foreach ($app in $apps) {
    Write-Host "Sync triggers for: $app" -ForegroundColor Cyan
    try {
        az webapp deployment list-publishing-profiles --resource-group $ResourceGroup --name $app --query "[0].publishUrl" --output tsv
    } catch {
        Write-Host "Could not sync triggers for $app" -ForegroundColor Yellow
    }
}

# Method 4: Check and fix app settings
Write-Host "`n⚙️  Method 4: Verify app settings..." -ForegroundColor Yellow
foreach ($app in $apps) {
    Write-Host "Checking settings for: $app" -ForegroundColor Cyan
    $settings = az webapp config appsettings list --resource-group $ResourceGroup --name $app --query "length(@)" --output tsv
    Write-Host "  Settings count: $settings" -ForegroundColor White
    
    # Ensure basic settings are present
    if ($app -like "*backend*") {
        az webapp config appsettings set --resource-group $ResourceGroup --name $app --settings `
            NODE_ENV=production `
            WEBSITES_ENABLE_APP_SERVICE_STORAGE=false `
            WEBSITE_NODE_DEFAULT_VERSION="~18"
    }
}

# Final check
Write-Host "`n🔍 Final Status Check..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

foreach ($app in $apps) {
    $details = az webapp show --resource-group $ResourceGroup --name $app --query "{name:name, state:state, availabilityState:availabilityState}" --output json | ConvertFrom-Json
    
    $color = switch ($details.state) {
        "Running" { "Green" }
        "QuotaExceeded" { "Red" }
        default { "Yellow" }
    }
    
    Write-Host "$($details.name): $($details.state) ($($details.availabilityState))" -ForegroundColor $color
}

Write-Host "`nIf apps are still not working:" -ForegroundColor Cyan
Write-Host "1. Try the create-fresh-deployment.ps1 script" -ForegroundColor White
Write-Host "2. Consider upgrading to a paid Azure subscription" -ForegroundColor White
Write-Host "3. Use Azure Container Instances instead" -ForegroundColor White
Write-Host "4. Deploy to other cloud providers (Heroku, Vercel, etc.)" -ForegroundColor White
