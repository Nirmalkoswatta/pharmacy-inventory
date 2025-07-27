# Fix 403 Error (QuotaExceeded) for Azure Web Apps
# This script helps resolve quota exceeded issues in Azure for Students subscriptions

param(
    [string]$ResourceGroup = "pharmacy-inventory"
)

$ErrorActionPreference = "Stop"

Write-Host "🔧 Azure 403 Error Fix Tool" -ForegroundColor Green
Write-Host "📦 Resource Group: $ResourceGroup" -ForegroundColor Cyan

# Check if logged in to Azure
try {
    $account = az account show | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
} catch {
    Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Check current web app status
Write-Host "`n🔍 Checking current web app status..." -ForegroundColor Yellow
$webApps = az webapp list --resource-group $ResourceGroup | ConvertFrom-Json

if (-not $webApps) {
    Write-Host "❌ No web apps found in resource group." -ForegroundColor Red
    exit 1
}

$quotaExceededApps = @()
$runningApps = @()

foreach ($app in $webApps) {
    $details = az webapp show --resource-group $ResourceGroup --name $app.name | ConvertFrom-Json
    
    if ($details.state -eq "QuotaExceeded") {
        $quotaExceededApps += $app
        Write-Host "❌ $($app.name): QuotaExceeded" -ForegroundColor Red
    } elseif ($details.state -eq "Running") {
        $runningApps += $app
        Write-Host "✅ $($app.name): Running" -ForegroundColor Green
    } else {
        Write-Host "⚠️  $($app.name): $($details.state)" -ForegroundColor Yellow
    }
}

# If no quota exceeded apps, we're good
if ($quotaExceededApps.Count -eq 0) {
    Write-Host "`n✅ All web apps are running normally!" -ForegroundColor Green
    Write-Host "`n🌐 Your application URLs:" -ForegroundColor Cyan
    foreach ($app in $runningApps) {
        Write-Host "   $($app.name): https://$($app.defaultHostName)" -ForegroundColor White
    }
    exit 0
}

# Handle quota exceeded scenario
Write-Host "`n🛠️  Fixing quota exceeded issues..." -ForegroundColor Yellow

# Check for duplicate deployments
$frontendApps = $webApps | Where-Object { $_.name -like "*frontend*" }
$backendApps = $webApps | Where-Object { $_.name -like "*backend*" }

if ($frontendApps.Count -gt 1) {
    Write-Host "🔍 Found multiple frontend apps. Keeping the latest..." -ForegroundColor Yellow
    $latestFrontend = $frontendApps | Sort-Object name -Descending | Select-Object -First 1
    $oldFrontends = $frontendApps | Where-Object { $_.name -ne $latestFrontend.name }
    
    foreach ($oldApp in $oldFrontends) {
        Write-Host "🗑️  Stopping old frontend: $($oldApp.name)" -ForegroundColor Yellow
        az webapp stop --resource-group $ResourceGroup --name $oldApp.name
    }
}

if ($backendApps.Count -gt 1) {
    Write-Host "🔍 Found multiple backend apps. Keeping the latest..." -ForegroundColor Yellow
    $latestBackend = $backendApps | Sort-Object name -Descending | Select-Object -First 1
    $oldBackends = $backendApps | Where-Object { $_.name -ne $latestBackend.name }
    
    foreach ($oldApp in $oldBackends) {
        Write-Host "🗑️  Stopping old backend: $($oldApp.name)" -ForegroundColor Yellow
        az webapp stop --resource-group $ResourceGroup --name $oldApp.name
    }
}

# Restart the quota exceeded apps
Write-Host "`n🔄 Restarting quota exceeded apps..." -ForegroundColor Yellow
foreach ($app in $quotaExceededApps) {
    Write-Host "🔄 Restarting: $($app.name)" -ForegroundColor Yellow
    az webapp restart --resource-group $ResourceGroup --name $app.name
}

# Wait for restart
Write-Host "`n⏳ Waiting for apps to restart..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# Check final status
Write-Host "`n🔍 Final status check..." -ForegroundColor Yellow
$finalApps = az webapp list --resource-group $ResourceGroup | ConvertFrom-Json

foreach ($app in $finalApps) {
    $details = az webapp show --resource-group $ResourceGroup --name $app.name | ConvertFrom-Json
    
    if ($details.state -eq "Running") {
        Write-Host "✅ $($app.name): Running" -ForegroundColor Green
        Write-Host "   🌐 URL: https://$($app.defaultHostName)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ $($app.name): $($details.state)" -ForegroundColor Red
    }
}

Write-Host "`n💡 Tips to prevent 403 errors:" -ForegroundColor Cyan
Write-Host "   1. Don't run multiple deployments simultaneously" -ForegroundColor White
Write-Host "   2. Clean up old resources regularly" -ForegroundColor White
Write-Host "   3. Use this script when you encounter 403 errors" -ForegroundColor White
Write-Host "   4. Monitor your Azure for Students quota usage" -ForegroundColor White

Write-Host "`n🎉 Fix complete!" -ForegroundColor Green
