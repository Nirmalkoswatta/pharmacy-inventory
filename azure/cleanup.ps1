# Azure Cleanup Script
# Removes all Azure resources created during deployment

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "🧹 Azure Resources Cleanup Script" -ForegroundColor Red
Write-Host "📦 Resource Group: $ResourceGroup" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No resources will be deleted" -ForegroundColor Green
}

# Check if resource group exists
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    Write-Host "❌ Resource group '$ResourceGroup' does not exist." -ForegroundColor Red
    exit 1
}

# List all resources in the resource group
Write-Host "`n📋 Resources to be deleted:" -ForegroundColor Yellow
$resources = az resource list --resource-group $ResourceGroup --output table

if ($resources) {
    Write-Host $resources
} else {
    Write-Host "No resources found in the resource group." -ForegroundColor Green
    exit 0
}

if ($DryRun) {
    Write-Host "`n✅ DRY RUN completed. No resources were deleted." -ForegroundColor Green
    exit 0
}

# Confirm deletion unless Force is specified
if (-not $Force) {
    Write-Host "`n⚠️  WARNING: This will DELETE ALL resources in the resource group '$ResourceGroup'" -ForegroundColor Red
    $confirmation = Read-Host "Are you sure you want to continue? (yes/no)"
    if ($confirmation -ne "yes") {
        Write-Host "❌ Operation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "`n🗑️ Deleting resource group and all resources..." -ForegroundColor Red

try {
    az group delete --name $ResourceGroup --yes --no-wait
    Write-Host "✅ Resource group deletion initiated. This may take several minutes to complete." -ForegroundColor Green
    Write-Host "📋 You can monitor the deletion progress in the Azure Portal." -ForegroundColor Cyan
    
    # Optional: Wait for deletion to complete
    $waitForCompletion = Read-Host "`nWait for deletion to complete? (y/n)"
    if ($waitForCompletion -eq "y") {
        Write-Host "⏳ Waiting for deletion to complete..."
        
        do {
            Start-Sleep -Seconds 30
            $rgExists = az group exists --name $ResourceGroup
            Write-Host "." -NoNewline
        } while ($rgExists -eq "true")
        
        Write-Host "`n✅ Resource group has been successfully deleted." -ForegroundColor Green
    }
    
} catch {
    Write-Host "❌ Error during deletion: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Clean up local deployment files
$cleanupLocal = Read-Host "`nDelete local deployment info files? (y/n)"
if ($cleanupLocal -eq "y") {
    $filesToClean = @(
        "./azure/acr-credentials.json",
        "./azure/aci/deployment-info.json",
        "./azure/aks/deployment-info.json",
        "./azure/app-service/deployment-info.json",
        "./azure/arm-templates/deployment-outputs.json"
    )
    
    foreach ($file in $filesToClean) {
        if (Test-Path $file) {
            Remove-Item $file -Force
            Write-Host "🗑️ Deleted: $file" -ForegroundColor Yellow
        }
    }
    
    Write-Host "✅ Local deployment files cleaned up." -ForegroundColor Green
}

Write-Host "`n🎉 Cleanup completed!" -ForegroundColor Green
