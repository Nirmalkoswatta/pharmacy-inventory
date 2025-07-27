# Azure Deployment Status Checker
# Monitors the health and status of deployed Azure resources

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [ValidateSet("aci", "aks", "app-service", "all")]
    [string]$DeploymentType = "all"
)

$ErrorActionPreference = "Stop"

Write-Host "📊 Azure Deployment Status Checker" -ForegroundColor Green
Write-Host "📦 Resource Group: $ResourceGroup" -ForegroundColor Cyan
Write-Host "🔍 Deployment Type: $DeploymentType" -ForegroundColor Cyan

# Check if resource group exists
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    Write-Host "❌ Resource group '$ResourceGroup' does not exist." -ForegroundColor Red
    exit 1
}

Write-Host "`n🔍 Checking resource status..." -ForegroundColor Yellow

# Get all resources in the resource group
$resources = az resource list --resource-group $ResourceGroup | ConvertFrom-Json

if (-not $resources) {
    Write-Host "❌ No resources found in resource group." -ForegroundColor Red
    exit 1
}

# Function to check health endpoint
function Test-HealthEndpoint {
    param([string]$Url)
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 10 -UseBasicParsing
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

# Check different deployment types
if ($DeploymentType -eq "aci" -or $DeploymentType -eq "all") {
    Write-Host "`n🐳 Azure Container Instances Status:" -ForegroundColor Cyan
    
    $containers = $resources | Where-Object { $_.type -eq "Microsoft.ContainerInstance/containerGroups" }
    
    if ($containers) {
        foreach ($container in $containers) {
            $containerDetails = az container show --resource-group $ResourceGroup --name $container.name | ConvertFrom-Json
            $status = $containerDetails.instanceView.state
            $ip = $containerDetails.ipAddress.ip
            
            Write-Host "  📦 $($container.name): $status" -ForegroundColor $(if ($status -eq "Running") { "Green" } else { "Red" })
            
            if ($ip) {
                Write-Host "     🌐 IP: $ip"
                
                # Try to check health endpoint
                if ($container.name -like "*backend*") {
                    $healthUrl = "http://$ip`:4000/health"
                    $isHealthy = Test-HealthEndpoint -Url $healthUrl
                    Write-Host "     ❤️  Health: $(if ($isHealthy) { 'Healthy' } else { 'Unhealthy' })" -ForegroundColor $(if ($isHealthy) { "Green" } else { "Red" })
                }
            }
        }
    } else {
        Write-Host "  ℹ️  No Container Instances found"
    }
}

if ($DeploymentType -eq "aks" -or $DeploymentType -eq "all") {
    Write-Host "`n☸️ Azure Kubernetes Service Status:" -ForegroundColor Cyan
    
    $aksClusters = $resources | Where-Object { $_.type -eq "Microsoft.ContainerService/managedClusters" }
    
    if ($aksClusters) {
        foreach ($cluster in $aksClusters) {
            $clusterDetails = az aks show --resource-group $ResourceGroup --name $cluster.name | ConvertFrom-Json
            $status = $clusterDetails.powerState.code
            
            Write-Host "  ☸️  $($cluster.name): $status" -ForegroundColor $(if ($status -eq "Running") { "Green" } else { "Red" })
            
            # Try to get cluster credentials and check pods
            try {
                az aks get-credentials --resource-group $ResourceGroup --name $cluster.name --overwrite-existing 2>$null
                $pods = kubectl get pods -n pharmacy-inventory -o json 2>$null | ConvertFrom-Json
                
                if ($pods.items) {
                    Write-Host "     📦 Pods:"
                    foreach ($pod in $pods.items) {
                        $podStatus = $pod.status.phase
                        $podName = $pod.metadata.name
                        Write-Host "       - $podName`: $podStatus" -ForegroundColor $(if ($podStatus -eq "Running") { "Green" } else { "Red" })
                    }
                }
            } catch {
                Write-Host "     ⚠️  Could not retrieve pod information"
            }
        }
    } else {
        Write-Host "  ℹ️  No AKS clusters found"
    }
}

if ($DeploymentType -eq "app-service" -or $DeploymentType -eq "all") {
    Write-Host "`n🌐 Azure App Service Status:" -ForegroundColor Cyan
    
    $appServices = $resources | Where-Object { $_.type -eq "Microsoft.Web/sites" }
    
    if ($appServices) {
        foreach ($app in $appServices) {
            $appDetails = az webapp show --resource-group $ResourceGroup --name $app.name | ConvertFrom-Json
            $status = $appDetails.state
            $url = "https://$($appDetails.defaultHostName)"
            
            Write-Host "  🌐 $($app.name): $status" -ForegroundColor $(if ($status -eq "Running") { "Green" } else { "Red" })
            Write-Host "     🔗 URL: $url"
            
            # Check if app is responding
            $isResponding = Test-HealthEndpoint -Url $url
            Write-Host "     ❤️  Response: $(if ($isResponding) { 'Responding' } else { 'Not Responding' })" -ForegroundColor $(if ($isResponding) { "Green" } else { "Red" })
            
            # Check if it's a backend app and test health endpoint
            if ($app.name -like "*backend*") {
                $healthUrl = "$url/health"
                $isHealthy = Test-HealthEndpoint -Url $healthUrl
                Write-Host "     🏥 Health: $(if ($isHealthy) { 'Healthy' } else { 'Unhealthy' })" -ForegroundColor $(if ($isHealthy) { "Green" } else { "Red" })
            }
        }
    } else {
        Write-Host "  ℹ️  No App Services found"
    }
}

# Check database status
Write-Host "`n🗄️ Database Status:" -ForegroundColor Cyan

$cosmosAccounts = $resources | Where-Object { $_.type -eq "Microsoft.DocumentDB/databaseAccounts" }
if ($cosmosAccounts) {
    foreach ($cosmos in $cosmosAccounts) {
        $cosmosDetails = az cosmosdb show --resource-group $ResourceGroup --name $cosmos.name | ConvertFrom-Json
        $status = $cosmosDetails.readLocations[0].provisioningState
        
        Write-Host "  🌍 $($cosmos.name) (Cosmos DB): $status" -ForegroundColor $(if ($status -eq "Succeeded") { "Green" } else { "Red" })
    }
} else {
    Write-Host "  ℹ️  No Cosmos DB accounts found"
}

# Check Container Registry
Write-Host "`n🐳 Container Registry Status:" -ForegroundColor Cyan

$registries = $resources | Where-Object { $_.type -eq "Microsoft.ContainerRegistry/registries" }
if ($registries) {
    foreach ($registry in $registries) {
        $registryDetails = az acr show --resource-group $ResourceGroup --name $registry.name | ConvertFrom-Json
        $status = $registryDetails.provisioningState
        
        Write-Host "  📦 $($registry.name): $status" -ForegroundColor $(if ($status -eq "Succeeded") { "Green" } else { "Red" })
        
        # List images
        try {
            $images = az acr repository list --name $registry.name | ConvertFrom-Json
            if ($images) {
                Write-Host "     🖼️  Images: $($images -join ', ')"
            }
        } catch {
            Write-Host "     ⚠️  Could not retrieve image list"
        }
    }
} else {
    Write-Host "  ℹ️  No Container Registries found"
}

# Summary
Write-Host "`n📊 Deployment Summary:" -ForegroundColor Green

$healthyServices = 0
$totalServices = 0

# Count healthy services based on resource types
foreach ($resource in $resources) {
    switch ($resource.type) {
        "Microsoft.ContainerInstance/containerGroups" {
            $totalServices++
            $containerDetails = az container show --resource-group $ResourceGroup --name $resource.name | ConvertFrom-Json
            if ($containerDetails.instanceView.state -eq "Running") { $healthyServices++ }
        }
        "Microsoft.Web/sites" {
            $totalServices++
            $appDetails = az webapp show --resource-group $ResourceGroup --name $resource.name | ConvertFrom-Json
            if ($appDetails.state -eq "Running") { $healthyServices++ }
        }
        "Microsoft.ContainerService/managedClusters" {
            $totalServices++
            $clusterDetails = az aks show --resource-group $ResourceGroup --name $resource.name | ConvertFrom-Json
            if ($clusterDetails.powerState.code -eq "Running") { $healthyServices++ }
        }
    }
}

Write-Host "  ✅ Healthy Services: $healthyServices/$totalServices"
Write-Host "  💰 Estimated Monthly Cost: Check Azure Cost Management"
Write-Host "  📅 Last Checked: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

if ($healthyServices -eq $totalServices -and $totalServices -gt 0) {
    Write-Host "`n🎉 All services are running healthy!" -ForegroundColor Green
} elseif ($healthyServices -eq 0) {
    Write-Host "`n❌ No services are running. Check deployment logs." -ForegroundColor Red
} else {
    Write-Host "`n⚠️  Some services need attention." -ForegroundColor Yellow
}

Write-Host "`n📝 Useful Commands:" -ForegroundColor Cyan
Write-Host "   Monitor costs: az consumption usage list --top 10"
Write-Host "   View activity log: az monitor activity-log list --resource-group $ResourceGroup"
Write-Host "   Check quotas: az vm list-usage --location 'East US'"
