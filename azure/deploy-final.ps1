# Simple Enhanced Frontend Deploy
param(
    [string]$FrontendAppName = "pharmacy-frontend-07270422",
    [string]$ResourceGroup = "pharmacy-inventory"
)

Write-Host "=== Enhanced Frontend Deploy ===" -ForegroundColor Green

Set-Location "frontend"

if (Test-Path "simple") { Remove-Item "simple" -Recurse -Force }
New-Item -ItemType Directory -Path "simple" | Out-Null

# Copy React build if it exists
if (Test-Path "build") {
    Copy-Item "build/*" "simple/" -Recurse
    Write-Host "React build copied" -ForegroundColor Green
}

# Create simple package.json
$pkg = '{"name":"pharmacy-frontend","version":"1.0.0","scripts":{"start":"node server.js"},"dependencies":{"express":"^4.18.0"}}'
$pkg | Out-File -FilePath "simple/package.json" -Encoding utf8

# Create simple server
$srv = 'const express = require("express");
const path = require("path");
const app = express();

app.use(express.static(__dirname));

app.get("/api/status", (req, res) => {
  res.json({ 
    status: "running",
    frontend: "React + Express",
    backend: "https://pharmacy-backend-07270422.azurewebsites.net",
    timestamp: new Date().toISOString()
  });
});

app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log("Pharmacy Frontend running on port", port);
});'

$srv | Out-File -FilePath "simple/server.js" -Encoding utf8

# Deploy
Compress-Archive -Path "simple/*" -DestinationPath "simple.zip" -Force
az webapp deployment source config-zip --resource-group $ResourceGroup --name $FrontendAppName --src "simple.zip"

# Clean up
Remove-Item "simple" -Recurse -Force
Remove-Item "simple.zip" -Force

Set-Location ".."

Write-Host ""
Write-Host "=== DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host "Frontend: https://$FrontendAppName.azurewebsites.net" -ForegroundColor Cyan
