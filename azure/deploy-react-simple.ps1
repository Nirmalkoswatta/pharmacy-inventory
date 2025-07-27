# Simple React Deploy to Azure
param(
    [string]$FrontendAppName = "pharmacy-frontend-07270422",
    [string]$ResourceGroup = "pharmacy-inventory"
)

Write-Host "=== Deploying React Build ===" -ForegroundColor Green

Set-Location "frontend"

if (-not (Test-Path "build")) {
    Write-Host "Build directory not found! Please run 'npm run build' first" -ForegroundColor Red
    return
}

Write-Host "Found React build directory" -ForegroundColor Green

# Create deployment package
if (Test-Path "deploy") { Remove-Item "deploy" -Recurse -Force }
New-Item -ItemType Directory -Path "deploy" | Out-Null

# Copy build files
Copy-Item "build/*" "deploy/" -Recurse

# Create simple package.json
$package = '{"name":"pharmacy-frontend","version":"1.0.0","scripts":{"start":"node server.js"},"dependencies":{"express":"^4.18.0"}}'
$package | Out-File -FilePath "deploy/package.json" -Encoding utf8

# Create simple server
$server = 'const express = require("express");
const path = require("path");
const app = express();

app.use(express.static(__dirname));

app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log("Pharmacy React app running on port", port);
});'

$server | Out-File -FilePath "deploy/server.js" -Encoding utf8

# Deploy
Compress-Archive -Path "deploy/*" -DestinationPath "react.zip" -Force
az webapp deploy --resource-group $ResourceGroup --name $FrontendAppName --src-path "react.zip" --type zip

# Clean up
Remove-Item "deploy" -Recurse -Force
Remove-Item "react.zip" -Force

Set-Location ".."

Write-Host ""
Write-Host "=== REACT APP DEPLOYED ===" -ForegroundColor Green
Write-Host "Frontend: https://$FrontendAppName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "Visit the URL to see your React pharmacy app!" -ForegroundColor Yellow
