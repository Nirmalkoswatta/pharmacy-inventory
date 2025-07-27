# Quick Health Check for Pharmacy Inventory App
param(
    [string]$ResourceGroup = "pharmacy-inventory"
)

Write-Host "Pharmacy Inventory Health Check" -ForegroundColor Green

$webApps = az webapp list --resource-group $ResourceGroup --query "[].{name:name, defaultHostName:defaultHostName}" | ConvertFrom-Json

foreach ($app in $webApps) {
    $url = "https://$($app.defaultHostName)"
    Write-Host ""
    Write-Host "Testing: $($app.name)" -ForegroundColor Cyan
    Write-Host "URL: $url" -ForegroundColor White
    
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "Status: Healthy (200 OK)" -ForegroundColor Green
        } else {
            Write-Host "Status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        if ($_.Exception.Message -contains "403") {
            Write-Host "Status: 403 Forbidden (App may be stopped)" -ForegroundColor Red
            Write-Host "TIP: Run fix-403-error.ps1 to resolve this issue" -ForegroundColor Yellow
        } else {
            Write-Host "Status: Error - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Quick URLs for testing:" -ForegroundColor Cyan
foreach ($app in $webApps) {
    Write-Host "$($app.name): https://$($app.defaultHostName)" -ForegroundColor White
}
