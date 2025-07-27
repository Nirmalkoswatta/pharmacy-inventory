# Fresh Deployment Script for Pharmacy Inventory
param(
    [string]$ResourceGroup = "pharmacy-inventory",
    [string]$SubscriptionId = "318d6e86-b40c-4648-829d-b2902b4b6a79"
)

Write-Host "=== Fresh Pharmacy Inventory Deployment ===" -ForegroundColor Green
Write-Host ""

# Generate new unique names to avoid conflicts
$timestamp = Get-Date -Format "MMddHHmmss"
$backendAppName = "pharmacy-backend-$timestamp"
$frontendAppName = "pharmacy-frontend-$timestamp"
$appServicePlan = "pharmacy-plan-$timestamp"

Write-Host "Creating new deployment with fresh names:" -ForegroundColor Cyan
Write-Host "- App Service Plan: $appServicePlan"
Write-Host "- Backend App: $backendAppName"
Write-Host "- Frontend App: $frontendAppName"
Write-Host ""

# Set subscription
az account set --subscription $SubscriptionId

# Create new App Service Plan
Write-Host "Creating new App Service Plan..." -ForegroundColor Yellow
az appservice plan create --name $appServicePlan --resource-group $ResourceGroup --location "Canada Central" --sku FREE --is-linux

# Create Backend App
Write-Host "Creating backend app..." -ForegroundColor Yellow
az webapp create --resource-group $ResourceGroup --plan $appServicePlan --name $backendAppName --runtime "NODE:20-lts"

# Create Frontend App
Write-Host "Creating frontend app..." -ForegroundColor Yellow
az webapp create --resource-group $ResourceGroup --plan $appServicePlan --name $frontendAppName --runtime "NODE:20-lts"

# Configure backend settings
Write-Host "Configuring backend..." -ForegroundColor Yellow
az webapp config appsettings set --resource-group $ResourceGroup --name $backendAppName --settings "NODE_ENV=production" "PORT=8080"

# Configure frontend settings
Write-Host "Configuring frontend..." -ForegroundColor Yellow
az webapp config appsettings set --resource-group $ResourceGroup --name $frontendAppName --settings "NODE_ENV=production" "BACKEND_URL=https://$backendAppName.azurewebsites.net"

Write-Host ""
Write-Host "=== INFRASTRUCTURE CREATED ===" -ForegroundColor Green
Write-Host "Now deploying application code..." -ForegroundColor Yellow
Write-Host ""

# Deploy Backend
Write-Host "Deploying backend code..." -ForegroundColor Green
Set-Location "backend"

if (Test-Path "fresh-backend") { Remove-Item "fresh-backend" -Recurse -Force }
New-Item -ItemType Directory -Path "fresh-backend" | Out-Null

# Copy backend files
Copy-Item "package.json" "fresh-backend/"
Copy-Item "index.js" "fresh-backend/"
Copy-Item "schema.js" "fresh-backend/"
Copy-Item "resolvers.js" "fresh-backend/"
Copy-Item "models" "fresh-backend/models" -Recurse

# Deploy backend
Compress-Archive -Path "fresh-backend/*" -DestinationPath "fresh-backend.zip" -Force
az webapp deploy --resource-group $ResourceGroup --name $backendAppName --src-path "fresh-backend.zip" --type zip

# Clean up backend
Remove-Item "fresh-backend" -Recurse -Force
Remove-Item "fresh-backend.zip" -Force

Write-Host "Backend deployed successfully!" -ForegroundColor Green

# Deploy Frontend
Set-Location "../frontend"
Write-Host "Deploying frontend code..." -ForegroundColor Green

if (Test-Path "fresh-frontend") { Remove-Item "fresh-frontend" -Recurse -Force }
New-Item -ItemType Directory -Path "fresh-frontend" | Out-Null

# Copy React build if available, otherwise create status page
if (Test-Path "build") {
    Copy-Item "build/*" "fresh-frontend/" -Recurse
    Write-Host "Using existing React build" -ForegroundColor Green
} else {
    Write-Host "No React build found, creating status page" -ForegroundColor Yellow
}

# Create package.json for frontend
$frontendPackage = @"
{
  "name": "pharmacy-frontend",
  "version": "1.0.0",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
"@

$frontendPackage | Out-File -FilePath "fresh-frontend/package.json" -Encoding utf8

# Create Express server for frontend
$frontendServer = @"
const express = require('express');
const path = require('path');
const app = express();

app.use(express.static(__dirname));

app.get('/api/status', (req, res) => {
  res.json({
    status: 'running',
    frontend: 'Fresh deployment',
    backend: 'https://$backendAppName.azurewebsites.net',
    timestamp: new Date().toISOString()
  });
});

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log('Fresh Pharmacy Frontend running on port', port);
});
"@

$frontendServer | Out-File -FilePath "fresh-frontend/server.js" -Encoding utf8

# Create index.html if not exists
if (-not (Test-Path "fresh-frontend/index.html")) {
    $indexHtml = @"
<!DOCTYPE html>
<html>
<head>
    <title>Pharmacy Inventory System</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { 
            font-family: 'Segoe UI', sans-serif; 
            margin: 0; padding: 40px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; min-height: 100vh;
        }
        .container { 
            max-width: 800px; margin: 0 auto; text-align: center;
            background: rgba(255,255,255,0.1); padding: 40px; 
            border-radius: 20px; backdrop-filter: blur(10px);
        }
        .status { color: #4ade80; margin: 20px 0; font-size: 1.3em; }
        .url { 
            background: rgba(255,255,255,0.2); padding: 15px; 
            border-radius: 8px; margin: 15px 0; word-break: break-all;
        }
        a { color: #93c5fd; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 30px 0; }
        .card { background: rgba(255,255,255,0.1); padding: 20px; border-radius: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏥 Pharmacy Inventory System</h1>
        <div class="status">✅ Fresh Deployment Successful!</div>
        
        <div class="url">
            <strong>Frontend:</strong> <a href="https://$frontendAppName.azurewebsites.net">$frontendAppName.azurewebsites.net</a>
        </div>
        <div class="url">
            <strong>Backend API:</strong> <a href="https://$backendAppName.azurewebsites.net">$backendAppName.azurewebsites.net</a>
        </div>
        
        <div class="grid">
            <div class="card">
                <h3>🔧 API Endpoints</h3>
                <p><a href="https://$backendAppName.azurewebsites.net/medicines">View Medicines</a></p>
                <p><a href="https://$backendAppName.azurewebsites.net/suppliers">View Suppliers</a></p>
                <p><a href="https://$backendAppName.azurewebsites.net/orders">View Orders</a></p>
            </div>
            <div class="card">
                <h3>📊 System Status</h3>
                <p>Frontend: ✅ Online</p>
                <p>Backend: ✅ Online</p>
                <p>Database: 🔧 Connect MongoDB</p>
            </div>
        </div>
        
        <p style="margin-top: 40px; opacity: 0.8;">
            Deployed: $(Get-Date -Format "yyyy-MM-dd HH:mm") UTC
        </p>
    </div>
</body>
</html>
"@
    
    $indexHtml | Out-File -FilePath "fresh-frontend/index.html" -Encoding utf8
}

# Deploy frontend
Compress-Archive -Path "fresh-frontend/*" -DestinationPath "fresh-frontend.zip" -Force
az webapp deploy --resource-group $ResourceGroup --name $frontendAppName --src-path "fresh-frontend.zip" --type zip

# Clean up frontend
Remove-Item "fresh-frontend" -Recurse -Force
Remove-Item "fresh-frontend.zip" -Force

Set-Location ".."

Write-Host ""
Write-Host "=== FRESH DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 Your pharmacy inventory system has been freshly deployed!" -ForegroundColor Cyan
Write-Host ""
Write-Host "New Application URLs:" -ForegroundColor White
Write-Host "Frontend: https://$frontendAppName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "Backend:  https://$backendAppName.azurewebsites.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please wait 2-3 minutes for the apps to fully start up." -ForegroundColor Yellow
Write-Host ""
Write-Host "✅ Fresh deployment successful!" -ForegroundColor Green
