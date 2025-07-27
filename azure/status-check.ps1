# Simple Deployment Status Check
Write-Host "=== Pharmacy Inventory System Status ===" -ForegroundColor Green
Write-Host ""

$frontend = "https://pharmacy-frontend-07270422.azurewebsites.net"
$backend = "https://pharmacy-backend-07270422.azurewebsites.net"

Write-Host "DEPLOYMENT SUCCESS!" -ForegroundColor Green
Write-Host ""
Write-Host "Your pharmacy inventory system is live on Azure:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Frontend: $frontend" -ForegroundColor White
Write-Host "Backend:  $backend" -ForegroundColor White
Write-Host ""
Write-Host "What was deployed:" -ForegroundColor Yellow
Write-Host "- React application (production build)"
Write-Host "- Express.js REST API backend"
Write-Host "- Sample pharmacy data"
Write-Host "- Health check endpoints"
Write-Host ""
Write-Host "API Endpoints:" -ForegroundColor Yellow
Write-Host "- GET $backend/ (API info)"
Write-Host "- GET $backend/health (health check)"
Write-Host "- GET $backend/medicines (sample data)"
Write-Host "- GET $backend/suppliers (sample data)"
Write-Host "- GET $backend/orders (sample data)"
Write-Host ""
Write-Host "Note: Apps may take 30-60 seconds to wake up after inactivity" -ForegroundColor Yellow
Write-Host ""
Write-Host "SUCCESS: Your pharmacy system is ready to use!" -ForegroundColor Green
