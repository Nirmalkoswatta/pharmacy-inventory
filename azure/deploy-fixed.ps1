# Fixed ZIP Deployment
param(
    [string]$BackendAppName = "pharmacy-backend-07270422",
    [string]$FrontendAppName = "pharmacy-frontend-07270422", 
    [string]$ResourceGroup = "pharmacy-inventory"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Fixed ZIP Deployment ===" -ForegroundColor Green

# Backend deployment
Write-Host "Deploying backend..." -ForegroundColor Yellow
Set-Location "backend"

# Create deploy directory
if (Test-Path "deploy") { Remove-Item "deploy" -Recurse -Force }
New-Item -ItemType Directory -Path "deploy" | Out-Null

# Copy files
Copy-Item "package.json" "deploy/"
Copy-Item "index.js" "deploy/"
Copy-Item "schema.js" "deploy/"
Copy-Item "resolvers.js" "deploy/"
Copy-Item "models" "deploy/models" -Recurse

# Create web.config for Azure App Service
$webConfig = @'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <add name="iisnode" path="index.js" verb="*" modules="iisnode"/>
    </handlers>
    <rewrite>
      <rules>
        <rule name="DynamicContent">
          <conditions>
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="True"/>
          </conditions>
          <action type="Rewrite" url="index.js"/>
        </rule>
      </rules>
    </rewrite>
    <iisnode node_env="production"/>
  </system.webServer>
</configuration>
'@

$webConfig | Out-File -FilePath "deploy/web.config" -Encoding utf8

# Zip and deploy
Compress-Archive -Path "deploy/*" -DestinationPath "backend.zip" -Force
az webapp deploy --resource-group $ResourceGroup --name $BackendAppName --src-path "backend.zip" --type zip

# Clean up
Remove-Item "deploy" -Recurse -Force
Remove-Item "backend.zip" -Force

Write-Host "Backend deployed!" -ForegroundColor Green

# Frontend deployment
Set-Location "../frontend"
Write-Host "Deploying frontend..." -ForegroundColor Yellow

# Create simple deployment
if (Test-Path "deploy") { Remove-Item "deploy" -Recurse -Force }
New-Item -ItemType Directory -Path "deploy" | Out-Null

# Simple index.html
$indexHtml = @"
<!DOCTYPE html>
<html>
<head>
    <title>Pharmacy Inventory</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; padding: 40px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; min-height: 100vh;
        }
        .container { 
            max-width: 800px; margin: 0 auto; text-align: center; 
            background: rgba(255,255,255,0.1); padding: 40px; 
            border-radius: 20px; backdrop-filter: blur(10px);
        }
        .status { color: #4ade80; margin: 20px 0; font-size: 1.2em; }
        .url { 
            background: rgba(255,255,255,0.2); padding: 10px; 
            border-radius: 8px; margin: 10px 0; 
        }
        a { color: #93c5fd; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .step { text-align: left; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏥 Pharmacy Inventory System</h1>
        <div class="status">✅ Successfully Deployed to Azure!</div>
        
        <h3>🔗 Your App URLs:</h3>
        <div class="url">
            <strong>Frontend:</strong> <a href="https://$FrontendAppName.azurewebsites.net">$FrontendAppName.azurewebsites.net</a>
        </div>
        <div class="url">
            <strong>Backend API:</strong> <a href="https://$BackendAppName.azurewebsites.net">$BackendAppName.azurewebsites.net</a>
        </div>
        
        <h3>📋 Next Steps:</h3>
        <div class="step">
            <p><strong>1. Build React App:</strong></p>
            <p>In your local frontend directory, run: <code>npm run build</code></p>
        </div>
        <div class="step">
            <p><strong>2. Redeploy with React Build:</strong></p>
            <p>Run the deployment script again to upload the built React app</p>
        </div>
        <div class="step">
            <p><strong>3. Set up Database:</strong></p>
            <p>Use MongoDB Atlas (free tier) for your database</p>
        </div>
        
        <h3>ℹ️ Student Subscription Notes:</h3>
        <p>• Apps sleep after 20 minutes of inactivity</p>
        <p>• First request after sleep may take 30+ seconds</p>
        <p>• Free tier has limited CPU and bandwidth</p>
        
        <p style="margin-top: 40px; font-size: 0.9em; opacity: 0.8;">
            Deployed on $(Get-Date -Format "yyyy-MM-dd HH:mm") UTC
        </p>
    </div>
</body>
</html>
"@

$indexHtml | Out-File -FilePath "deploy/index.html" -Encoding utf8

# Simple package.json for frontend
$frontendPackage = @'
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
'@

$frontendPackage | Out-File -FilePath "deploy/package.json" -Encoding utf8

# Simple Express server
$serverJs = @'
const express = require('express');
const path = require('path');
const app = express();

app.use(express.static(__dirname));

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Frontend server running on port ${port}`);
});
'@

$serverJs | Out-File -FilePath "deploy/server.js" -Encoding utf8

# Deploy frontend
Compress-Archive -Path "deploy/*" -DestinationPath "frontend.zip" -Force
az webapp deploy --resource-group $ResourceGroup --name $FrontendAppName --src-path "frontend.zip" --type zip

# Clean up
Remove-Item "deploy" -Recurse -Force
Remove-Item "frontend.zip" -Force

Set-Location ".."

Write-Host ""
Write-Host "=== DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 Your apps are deployed!" -ForegroundColor Cyan
Write-Host "Frontend: https://$FrontendAppName.azurewebsites.net" -ForegroundColor White
Write-Host "Backend:  https://$BackendAppName.azurewebsites.net" -ForegroundColor White
Write-Host ""
Write-Host "Visit the frontend URL to see the status page!" -ForegroundColor Yellow
