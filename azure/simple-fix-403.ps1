# Simple 403 Error Fix Script
param(
    [string]$ResourceGroup = "pharmacy-inventory"
)

Write-Host "Fixing 403 Error (QuotaExceeded) for Azure Web Apps" -ForegroundColor Green

# Check current web app status
Write-Host "Checking current web app status..." -ForegroundColor Yellow
$webApps = az webapp list --resource-group $ResourceGroup | ConvertFrom-Json

foreach ($app in $webApps) {
    $details = az webapp show --resource-group $ResourceGroup --name $app.name | ConvertFrom-Json
    
    if ($details.state -eq "QuotaExceeded") {
        Write-Host "$($app.name): QuotaExceeded - Will restart" -ForegroundColor Red
    } elseif ($details.state -eq "Running") {
        Write-Host "$($app.name): Running" -ForegroundColor Green
    } else {
        Write-Host "$($app.name): $($details.state)" -ForegroundColor Yellow
    }
}

# Restart all apps to fix quota issues
Write-Host ""
Write-Host "Restarting all web apps..." -ForegroundColor Yellow
foreach ($app in $webApps) {
    Write-Host "Restarting: $($app.name)" -ForegroundColor Cyan
    az webapp restart --resource-group $ResourceGroup --name $app.name
}

Write-Host ""
Write-Host "Waiting for apps to restart..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# Check final status
Write-Host "Final status check..." -ForegroundColor Yellow
$finalApps = az webapp list --resource-group $ResourceGroup | ConvertFrom-Json

foreach ($app in $finalApps) {
    $details = az webapp show --resource-group $ResourceGroup --name $app.name | ConvertFrom-Json
    
    if ($details.state -eq "Running") {
        Write-Host "$($app.name): Running" -ForegroundColor Green
        Write-Host "  URL: https://$($app.defaultHostName)" -ForegroundColor Cyan
    } else {
        Write-Host "$($app.name): $($details.state)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Fix complete!" -ForegroundColor Green
