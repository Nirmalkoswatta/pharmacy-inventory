# Azure Kubernetes Service (AKS) Deployment Script
# Creates AKS cluster and deploys the pharmacy inventory application

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$ClusterName,
    
    [Parameter(Mandatory=$true)]
    [string]$RegistryName,
    
    [string]$Location = "East US",
    [string]$NodeCount = "2",
    [string]$NodeSize = "Standard_B2s",
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Azure Kubernetes Service deployment..." -ForegroundColor Green

# Check if kubectl is installed
$kubectlVersion = kubectl version --client 2>$null
if (!$kubectlVersion) {
    Write-Host "❌ kubectl is not installed. Please install kubectl first." -ForegroundColor Red
    Write-Host "   Download from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/"
    exit 1
}

# Create AKS cluster
Write-Host "🏗️ Creating AKS cluster: $ClusterName"
az aks create `
    --resource-group $ResourceGroup `
    --name $ClusterName `
    --node-count $NodeCount `
    --node-vm-size $NodeSize `
    --location $Location `
    --enable-addons monitoring `
    --generate-ssh-keys `
    --attach-acr $RegistryName

# Get AKS credentials
Write-Host "🔑 Getting AKS credentials..."
az aks get-credentials --resource-group $ResourceGroup --name $ClusterName --overwrite-existing

# Verify connection
Write-Host "✅ Verifying cluster connection..."
kubectl cluster-info

# Get ACR login server
$loginServer = az acr show --name $RegistryName --resource-group $ResourceGroup --query "loginServer" --output tsv

# Create Docker registry secret
Write-Host "🔐 Creating Docker registry secret..."
$acrCredentials = az acr credential show --name $RegistryName | ConvertFrom-Json

# Create namespace
kubectl create namespace pharmacy-inventory --dry-run=client -o yaml | kubectl apply -f -

# Create ACR secret
kubectl create secret docker-registry acr-secret `
    --namespace=pharmacy-inventory `
    --docker-server=$loginServer `
    --docker-username=$acrCredentials.username `
    --docker-password=$acrCredentials.passwords[0].value

# Update the Kubernetes manifest with actual image names
$manifestContent = Get-Content "./azure/aks/pharmacy-aks.yaml" -Raw
$manifestContent = $manifestContent -replace "image: # This will be populated by the deployment script", "image: $loginServer/pharmacy-backend:$ImageTag"
$manifestContent = $manifestContent -replace "image: # This will be populated by the deployment script", "image: $loginServer/pharmacy-frontend:$ImageTag"

# Apply the updated manifest
Write-Host "📦 Deploying application to AKS..."
$manifestContent | kubectl apply -f -

# Wait for deployments to be ready
Write-Host "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/pharmacy-mongo -n pharmacy-inventory
kubectl wait --for=condition=available --timeout=300s deployment/pharmacy-backend -n pharmacy-inventory
kubectl wait --for=condition=available --timeout=300s deployment/pharmacy-frontend -n pharmacy-inventory

# Get service information
Write-Host "📋 Getting service information..."
kubectl get services -n pharmacy-inventory

# Get ingress information
$ingressInfo = kubectl get ingress pharmacy-ingress -n pharmacy-inventory -o json | ConvertFrom-Json
$ingressIp = $ingressInfo.status.loadBalancer.ingress[0].ip

Write-Host "`n✅ AKS deployment completed successfully!" -ForegroundColor Green
Write-Host "📋 Cluster Details:" -ForegroundColor Cyan
Write-Host "   Cluster Name: $ClusterName"
Write-Host "   Resource Group: $ResourceGroup"
Write-Host "   Node Count: $NodeCount"
Write-Host "   Node Size: $NodeSize"

if ($ingressIp) {
    Write-Host "   Ingress IP: $ingressIp"
    Write-Host "🌐 Your application will be available at: http://$ingressIp"
} else {
    Write-Host "⏳ Ingress IP is still being assigned. Check status with:"
    Write-Host "   kubectl get ingress pharmacy-ingress -n pharmacy-inventory"
}

# Save deployment info
$deploymentInfo = @{
    clusterName = $ClusterName
    resourceGroup = $ResourceGroup
    location = $Location
    nodeCount = $NodeCount
    nodeSize = $NodeSize
    registryName = $RegistryName
    ingressIp = $ingressIp
    deploymentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

$deploymentInfo | ConvertTo-Json | Out-File -FilePath "./azure/aks/deployment-info.json"

Write-Host "`n💾 Deployment info saved to: ./azure/aks/deployment-info.json" -ForegroundColor Yellow
Write-Host "`n📝 Useful commands:" -ForegroundColor Cyan
Write-Host "   View pods: kubectl get pods -n pharmacy-inventory"
Write-Host "   View services: kubectl get services -n pharmacy-inventory"
Write-Host "   View logs: kubectl logs -f deployment/pharmacy-backend -n pharmacy-inventory"
Write-Host "   Scale deployment: kubectl scale deployment pharmacy-backend --replicas=3 -n pharmacy-inventory"
