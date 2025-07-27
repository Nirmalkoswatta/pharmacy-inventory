# Quick ZIP Deployment to Azure
param(
    [Parameter(Mandatory=$true)]
    [string]$BackendAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$FrontendAppName,
    
    [string]$ResourceGroup = "pharmacy-inventory"
)

$ErrorActionPreference = "Stop"

Write-Host "=== ZIP Deployment to Azure ===" -ForegroundColor Green

# Build and prepare backend
Write-Host ""
Write-Host "Building backend..." -ForegroundColor Yellow
Set-Location "backend"

# Create deployment package for backend
Write-Host "Creating backend deployment package..."
if (Test-Path "deploy") { Remove-Item "deploy" -Recurse -Force }
New-Item -ItemType Directory -Path "deploy" | Out-Null

# Copy necessary backend files
Copy-Item "package.json" "deploy/"
Copy-Item "index.js" "deploy/"
Copy-Item "schema.js" "deploy/"
Copy-Item "resolvers.js" "deploy/"
Copy-Item "models" "deploy/" -Recurse

# Create simple web.config for Azure App Service
$webConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <add name="iisnode" path="index.js" verb="*" modules="iisnode"/>
    </handlers>
    <rewrite>
      <rules>
        <rule name="NodeInspector" patternSyntax="ECMAScript" stopProcessing="true">
          <match url="^index.js\/debug[\/]?" />
        </rule>
        <rule name="StaticContent">
          <action type="Rewrite" url="public{REQUEST_URI}"/>
        </rule>
        <rule name="DynamicContent">
          <conditions>
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="True"/>
          </conditions>
          <action type="Rewrite" url="index.js"/>
        </rule>
      </rules>
    </rewrite>
    <security>
      <requestFiltering>
        <hiddenSegments>
          <remove segment="bin"/>
        </hiddenSegments>
      </requestFiltering>
    </security>
    <httpErrors existingResponse="PassThrough" />
    <iisnode watchedFiles="web.config;*.js"/>
  </system.webServer>
</configuration>
"@

$webConfig | Out-File -FilePath "deploy/web.config" -Encoding utf8

# Zip backend
Write-Host "Creating backend.zip..."
if (Test-Path "backend.zip") { Remove-Item "backend.zip" -Force }
Compress-Archive -Path "deploy/*" -DestinationPath "backend.zip"

# Deploy backend
Write-Host "Deploying backend to $BackendAppName..." -ForegroundColor Green
az webapp deployment source config-zip --resource-group $ResourceGroup --name $BackendAppName --src "backend.zip"

# Clean up
Remove-Item "deploy" -Recurse -Force
Remove-Item "backend.zip" -Force

# Move to frontend
Set-Location "../frontend"

Write-Host ""
Write-Host "Building frontend..." -ForegroundColor Yellow

# Install dependencies and build (if not already done)
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing frontend dependencies..."
    npm install
}

Write-Host "Building React app..."
npm run build

# Create deployment package for frontend
Write-Host "Creating frontend deployment package..."
if (Test-Path "deploy") { Remove-Item "deploy" -Recurse -Force }
New-Item -ItemType Directory -Path "deploy" | Out-Null

# Copy build files
Copy-Item "build/*" "deploy/" -Recurse
Copy-Item "package.json" "deploy/"

# Create startup script for frontend
$startupScript = @"
const express = require('express');
const path = require('path');
const app = express();

// Serve static files from build directory
app.use(express.static(path.join(__dirname, 'build')));

// Handle React Router - serve index.html for all non-API routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build', 'index.html'));
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log('Frontend server running on port', port);
});
"@

$startupScript | Out-File -FilePath "deploy/server.js" -Encoding utf8

# Update package.json for deployment
$packageJson = Get-Content "deploy/package.json" | ConvertFrom-Json
$packageJson.scripts = @{
    "start" = "node server.js"
}
$packageJson.dependencies.express = "^4.18.0"
$packageJson | ConvertTo-Json -Depth 10 | Out-File -FilePath "deploy/package.json" -Encoding utf8

# Zip frontend
Write-Host "Creating frontend.zip..."
if (Test-Path "frontend.zip") { Remove-Item "frontend.zip" -Force }
Compress-Archive -Path "deploy/*" -DestinationPath "frontend.zip"

# Deploy frontend
Write-Host "Deploying frontend to $FrontendAppName..." -ForegroundColor Green
az webapp deployment source config-zip --resource-group $ResourceGroup --name $FrontendAppName --src "frontend.zip"

# Clean up
Remove-Item "deploy" -Recurse -Force
Remove-Item "frontend.zip" -Force

# Return to root
Set-Location ".."

Write-Host ""
Write-Host "=== DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Your apps are being deployed..." -ForegroundColor Cyan
Write-Host "Frontend: https://$FrontendAppName.azurewebsites.net" -ForegroundColor White
Write-Host "Backend:  https://$BackendAppName.azurewebsites.net" -ForegroundColor White
Write-Host ""
Write-Host "Note: It may take 5-10 minutes for the apps to be fully available." -ForegroundColor Yellow
Write-Host "You can check the deployment status in the Azure portal." -ForegroundColor Yellow
