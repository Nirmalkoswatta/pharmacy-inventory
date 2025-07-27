# Quick Health Check for Pharmacy Inventory App
# Run this script to quickly check if your Azure deployment is healthy

param(
    [string]$ResourceGroup = "pharmacy-inventory"
)

Write-Host "🏥 Pharmacy Inventory Health Check" -ForegroundColor Green

# Get web apps
$webApps = az webapp list --resource-group $ResourceGroup --query "[].{name:name, defaultHostName:defaultHostName}" | ConvertFrom-Json

foreach ($app in $webApps) {
    $url = "https://$($app.defaultHostName)"
    Write-Host "`n🔗 Testing: $($app.name)" -ForegroundColor Cyan
    Write-Host "   URL: $url" -ForegroundColor White
    
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "   [OK] Status: Healthy (200 OK)" -ForegroundColor Green
        } else {
            Write-Host "   [WARN] Status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        if ($_.Exception.Message -contains "403") {
            Write-Host "   [ERROR] Status: 403 Forbidden (App may be stopped)" -ForegroundColor Red
            Write-Host "   [TIP] Run fix-403-error.ps1 to resolve this issue" -ForegroundColor Yellow
        } else {
            Write-Host "   [ERROR] Status: Error - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n🎯 Quick URLs for testing:" -ForegroundColor Cyan
foreach ($app in $webApps) {
    Write-Host "   $($app.name): https://$($app.defaultHostName)" -ForegroundColor White
}
