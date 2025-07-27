# ARM Template Deployment Script
# Deploys the complete Azure infrastructure using ARM templates

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [string]$Location = "East US",
    [string]$TemplateFile = "./azure/arm-templates/azuredeploy.json",
    [string]$ParametersFile = "./azure/arm-templates/azuredeploy.parameters.json"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting ARM template deployment..." -ForegroundColor Green

# Create Resource Group if it doesn't exist
Write-Host "📦 Creating/updating resource group: $ResourceGroup"
az group create --name $ResourceGroup --location $Location

# Deploy ARM template
Write-Host "🏗️ Deploying ARM template..."
$deploymentName = "pharmacy-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

$deployment = az deployment group create `
    --resource-group $ResourceGroup `
    --name $deploymentName `
    --template-file $TemplateFile `
    --parameters $ParametersFile `
    --output json | ConvertFrom-Json

if ($deployment.properties.provisioningState -eq "Succeeded") {
    Write-Host "✅ ARM template deployment completed successfully!" -ForegroundColor Green
    
    # Extract outputs
    $outputs = $deployment.properties.outputs
    $acrName = $outputs.acrName.value
    $acrLoginServer = $outputs.acrLoginServer.value
    $backendUrl = $outputs.backendUrl.value
    $frontendUrl = $outputs.frontendUrl.value
    $cosmosAccountName = $outputs.cosmosAccountName.value
    $appInsightsKey = $outputs.applicationInsightsKey.value
    
    Write-Host "`n📋 Deployment Outputs:" -ForegroundColor Cyan
    Write-Host "   ACR Name: $acrName"
    Write-Host "   ACR Login Server: $acrLoginServer"
    Write-Host "   Backend URL: $backendUrl"
    Write-Host "   Frontend URL: $frontendUrl"
    Write-Host "   Cosmos DB Account: $cosmosAccountName"
    Write-Host "   Application Insights Key: $appInsightsKey"
    
    # Save deployment outputs
    $deploymentInfo = @{
        deploymentName = $deploymentName
        resourceGroup = $ResourceGroup
        location = $Location
        acrName = $acrName
        acrLoginServer = $acrLoginServer
        backendUrl = $backendUrl
        frontendUrl = $frontendUrl
        cosmosAccountName = $cosmosAccountName
        applicationInsightsKey = $appInsightsKey
        deploymentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $deploymentInfo | ConvertTo-Json | Out-File -FilePath "./azure/arm-templates/deployment-outputs.json"
    
    Write-Host "`n💾 Deployment outputs saved to: ./azure/arm-templates/deployment-outputs.json" -ForegroundColor Yellow
    
    Write-Host "`n📝 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Build and push Docker images to ACR:"
    Write-Host "      .\azure\build-and-push.ps1 -RegistryName $acrName -ResourceGroup $ResourceGroup"
    Write-Host "   2. Your application will be available at: $frontendUrl"
    Write-Host "   3. GraphQL endpoint: $backendUrl/graphql"
    
} else {
    Write-Host "❌ ARM template deployment failed!" -ForegroundColor Red
    Write-Host "Deployment State: $($deployment.properties.provisioningState)"
    exit 1
}
