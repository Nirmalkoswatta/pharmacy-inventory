# Health Check for South India Deployment
param(
    [string]$ResourceGroup = "pharmacy-southindia-3094"
)

Write-Host "🇮🇳 Pharmacy Inventory Health Check - South India" -ForegroundColor Green

# Test South India backend specifically
$southIndiaUrl = "https://pharmacy-backend-si-1189.azurewebsites.net"
Write-Host ""
Write-Host "Testing South India Backend:" -ForegroundColor Cyan
Write-Host "URL: $southIndiaUrl" -ForegroundColor White

try {
    $response = Invoke-WebRequest -Uri $southIndiaUrl -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "Status: Healthy (200 OK)" -ForegroundColor Green
    } else {
        Write-Host "Status: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    if ($_.Exception.Message -contains "403") {
        Write-Host "Status: 403 Forbidden (App may be stopped)" -ForegroundColor Red
        Write-Host "TIP: Run simple-fix-403.ps1 to resolve this issue" -ForegroundColor Yellow
    } elseif ($_.Exception.Message -contains "503") {
        Write-Host "Status: 503 Service Unavailable (App may be starting)" -ForegroundColor Yellow
        Write-Host "TIP: Wait 5-10 minutes for the app to fully start" -ForegroundColor Yellow
    } else {
        Write-Host "Status: Error - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test health endpoint
Write-Host ""
Write-Host "Testing Health Endpoint:" -ForegroundColor Cyan
try {
    $healthResponse = Invoke-WebRequest -Uri "$southIndiaUrl/health" -TimeoutSec 10 -UseBasicParsing
    Write-Host "Health Check: PASSED" -ForegroundColor Green
} catch {
    Write-Host "Health Check: FAILED (App may still be starting)" -ForegroundColor Yellow
}

# Also check all web apps in the resource group
Write-Host ""
Write-Host "All Web Apps in South India Resource Group:" -ForegroundColor Cyan

try {
    $webApps = az webapp list --resource-group $ResourceGroup --query "[].{name:name, defaultHostName:defaultHostName}" | ConvertFrom-Json
    
    foreach ($app in $webApps) {
        $url = "https://$($app.defaultHostName)"
        Write-Host "  $($app.name): $url" -ForegroundColor White
    }
} catch {
    Write-Host "  No additional apps found or resource group not accessible" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 Quick URLs for South India:" -ForegroundColor Green
Write-Host "  Backend: $southIndiaUrl" -ForegroundColor White
Write-Host "  Health: $southIndiaUrl/health" -ForegroundColor White
Write-Host "  GraphQL: $southIndiaUrl/graphql" -ForegroundColor White
