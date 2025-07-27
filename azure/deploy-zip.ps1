# Simple ZIP Deployment for Azure Student Subscription
param(
    [string]$BackendAppName = "pharmacy-backend-07270422",
    [string]$FrontendAppName = "pharmacy-frontend-07270422", 
    [string]$ResourceGroup = "pharmacy-inventory"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Simple ZIP Deployment ===" -ForegroundColor Green
Write-Host "Deploying to Azure App Service using ZIP packages"
Write-Host ""

# Deploy Backend
Write-Host "Preparing backend deployment..." -ForegroundColor Yellow
Set-Location "backend"

# Create a simple deployment package
Write-Host "Creating backend package..."
$backendFiles = @(
    "package.json",
    "index.js", 
    "schema.js",
    "resolvers.js",
    "models"
)

# Check if files exist
foreach ($file in $backendFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "Missing required file: $file" -ForegroundColor Red
        return
    }
}

# Clean and create deploy directory
if (Test-Path "deploy") { Remove-Item "deploy" -Recurse -Force }
New-Item -ItemType Directory -Path "deploy" | Out-Null

# Copy files
Copy-Item "package.json" "deploy/"
Copy-Item "index.js" "deploy/"  
Copy-Item "schema.js" "deploy/"
Copy-Item "resolvers.js" "deploy/"
Copy-Item "models" "deploy/models" -Recurse

# Create startup command file for Azure
$startupCommand = "node index.js"
$startupCommand | Out-File -FilePath "deploy/startup.txt" -Encoding utf8

Write-Host "Zipping backend..."
if (Test-Path "backend.zip") { Remove-Item "backend.zip" -Force }
Compress-Archive -Path "deploy/*" -DestinationPath "backend.zip"

Write-Host "Deploying backend to Azure..." -ForegroundColor Green
az webapp deployment source config-zip --resource-group $ResourceGroup --name $BackendAppName --src "backend.zip"

# Clean up backend
Remove-Item "deploy" -Recurse -Force
Remove-Item "backend.zip" -Force

Write-Host "Backend deployed!" -ForegroundColor Green

# Deploy Frontend
Set-Location "../frontend"
Write-Host ""
Write-Host "Preparing frontend deployment..." -ForegroundColor Yellow

# Check if build directory exists, if not create a simple index
if (-not (Test-Path "build")) {
    Write-Host "No build directory found. Creating simple index..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "build" -Force | Out-Null
    
    $simpleIndex = @"
<!DOCTYPE html>
<html>
<head>
    <title>Pharmacy Inventory</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 600px; margin: 0 auto; text-align: center; }
        .status { color: #28a745; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Pharmacy Inventory System</h1>
        <div class="status">✅ Frontend deployed successfully!</div>
        <p>This is a basic deployment. The React app build will be available once you:</p>
        <ol style="text-align: left;">
            <li>Run <code>npm run build</code> in the frontend directory</li>
            <li>Redeploy using the deployment script</li>
        </ol>
        <p><strong>Backend API:</strong> <a href="https://$BackendAppName.azurewebsites.net">$BackendAppName.azurewebsites.net</a></p>
    </div>
</body>
</html>
"@
    
    $simpleIndex | Out-File -FilePath "build/index.html" -Encoding utf8
}

# Create deployment package
if (Test-Path "deploy") { Remove-Item "deploy" -Recurse -Force }
New-Item -ItemType Directory -Path "deploy" | Out-Null

# Copy build files
Copy-Item "build/*" "deploy/" -Recurse
Copy-Item "package.json" "deploy/"

# Create a simple Express server for serving the React app
$serverJs = @"
const express = require('express');
const path = require('path');
const app = express();

// Serve static files from build directory
app.use(express.static(path.join(__dirname, '.')));

// Handle React Router - serve index.html for all routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log('Pharmacy frontend server running on port', port);
});
"@

$serverJs | Out-File -FilePath "deploy/server.js" -Encoding utf8

# Update package.json for deployment
$packageJson = Get-Content "deploy/package.json" | ConvertFrom-Json
$packageJson.scripts = @{
    "start" = "node server.js"
}
if (-not $packageJson.dependencies) {
    $packageJson | Add-Member -MemberType NoteProperty -Name "dependencies" -Value @{}
}
$packageJson.dependencies.express = "^4.18.0"
$packageJson | ConvertTo-Json -Depth 10 | Out-File -FilePath "deploy/package.json" -Encoding utf8

Write-Host "Zipping frontend..."
if (Test-Path "frontend.zip") { Remove-Item "frontend.zip" -Force }
Compress-Archive -Path "deploy/*" -DestinationPath "frontend.zip"

Write-Host "Deploying frontend to Azure..." -ForegroundColor Green
az webapp deployment source config-zip --resource-group $ResourceGroup --name $FrontendAppName --src "frontend.zip"

# Clean up frontend
Remove-Item "deploy" -Recurse -Force
Remove-Item "frontend.zip" -Force

Set-Location ".."

Write-Host ""
Write-Host "=== DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 Your pharmacy inventory system is deployed!" -ForegroundColor Cyan
Write-Host ""
Write-Host "📱 App URLs:" -ForegroundColor White
Write-Host "   Frontend: https://$FrontendAppName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "   Backend:  https://$BackendAppName.azurewebsites.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "⏰ Note: Apps may take 2-3 minutes to start up after deployment" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔧 Next Steps:" -ForegroundColor White
Write-Host "   1. Visit the frontend URL to see your app"
Write-Host "   2. Set up a database (MongoDB Atlas free tier recommended)"  
Write-Host "   3. Update backend with database connection string"
Write-Host ""
Write-Host "💡 Student Subscription Info:" -ForegroundColor Yellow
Write-Host "   • Free tier: Limited CPU/bandwidth"
Write-Host "   • Apps sleep after 20 min of inactivity" 
Write-Host "   • First request after sleep may be slow"
Write-Host ""
Write-Host "✅ Ready to use!" -ForegroundColor Green
