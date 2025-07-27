# Azure Container Instances Deployment Script
# Deploys the pharmacy inventory app using Azure Container Instances

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$RegistryName,
    
    [string]$Location = "East US",
    [string]$ImageTag = "latest",
    [string]$DnsNameLabel = "pharmacy-inventory"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Azure Container Instances deployment..." -ForegroundColor Green

# Get ACR credentials
Write-Host "🔑 Retrieving ACR credentials..."
$acrCredentials = az acr credential show --name $RegistryName | ConvertFrom-Json
$loginServer = az acr show --name $RegistryName --resource-group $ResourceGroup --query "loginServer" --output tsv

# Deploy MongoDB Container
Write-Host "📦 Deploying MongoDB container..."
az container create `
    --resource-group $ResourceGroup `
    --name "pharmacy-mongo" `
    --image "mongo:6.0" `
    --ports 27017 `
    --environment-variables "MONGO_INITDB_DATABASE=pharmacy" `
    --cpu 1 `
    --memory 2 `
    --restart-policy Always

# Wait for MongoDB to be ready
Write-Host "⏳ Waiting for MongoDB to be ready..."
Start-Sleep -Seconds 30

# Get MongoDB IP
$mongoIp = az container show --resource-group $ResourceGroup --name "pharmacy-mongo" --query "ipAddress.ip" --output tsv

# Deploy Backend Container
Write-Host "🔧 Deploying backend container..."
az container create `
    --resource-group $ResourceGroup `
    --name "pharmacy-backend" `
    --image "$loginServer/pharmacy-backend:$ImageTag" `
    --registry-login-server $loginServer `
    --registry-username $acrCredentials.username `
    --registry-password $acrCredentials.passwords[0].value `
    --ports 4000 `
    --environment-variables "NODE_ENV=production" "MONGO_URI=mongodb://$($mongoIp):27017/pharmacy" "PORT=4000" "FRONTEND_URL=https://$DnsNameLabel-frontend.eastus.azurecontainer.io" `
    --cpu 1 `
    --memory 1.5 `
    --restart-policy Always

# Get backend IP
$backendIp = az container show --resource-group $ResourceGroup --name "pharmacy-backend" --query "ipAddress.ip" --output tsv

# Deploy Frontend Container
Write-Host "🎨 Deploying frontend container..."
az container create `
    --resource-group $ResourceGroup `
    --name "pharmacy-frontend" `
    --image "$loginServer/pharmacy-frontend:$ImageTag" `
    --registry-login-server $loginServer `
    --registry-username $acrCredentials.username `
    --registry-password $acrCredentials.passwords[0].value `
    --ports 80 `
    --dns-name-label "$DnsNameLabel-frontend" `
    --environment-variables "REACT_APP_GRAPHQL_URI=http://$($backendIp):4000/graphql" `
    --cpu 1 `
    --memory 1 `
    --restart-policy Always

# Get deployment information
$frontendFqdn = az container show --resource-group $ResourceGroup --name "pharmacy-frontend" --query "ipAddress.fqdn" --output tsv

Write-Host "`n✅ Deployment completed successfully!" -ForegroundColor Green
Write-Host "📋 Deployment Details:" -ForegroundColor Cyan
Write-Host "   MongoDB IP: $mongoIp"
Write-Host "   Backend IP: $backendIp"
Write-Host "   Frontend URL: http://$frontendFqdn"

# Save deployment info
$deploymentInfo = @{
    resourceGroup = $ResourceGroup
    location = $Location
    mongodbIp = $mongoIp
    backendIp = $backendIp
    frontendUrl = "http://$frontendFqdn"
    deploymentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

$deploymentInfo | ConvertTo-Json | Out-File -FilePath "./azure/aci/deployment-info.json"

Write-Host "💾 Deployment info saved to: ./azure/aci/deployment-info.json" -ForegroundColor Yellow
Write-Host "`n🌐 Your application is available at: http://$frontendFqdn" -ForegroundColor Green
