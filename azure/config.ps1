# Azure Deployment Configuration
# Store your Azure subscription and deployment preferences

# Azure Subscription Details
$AZURE_SUBSCRIPTION_ID = "318d6e86-b40c-4648-829d-b2902b4b6a79"
$AZURE_DEFAULT_LOCATION = "South India"

# Project Configuration
$PROJECT_NAME = "pharmacy-inventory"
$ENVIRONMENT = "dev"  # dev, staging, prod

# Generate unique resource names (to avoid naming conflicts)
$UNIQUE_SUFFIX = Get-Random -Minimum 1000 -Maximum 9999
$RESOURCE_GROUP = "$PROJECT_NAME-$ENVIRONMENT-rg-$UNIQUE_SUFFIX"
$ACR_NAME = "$PROJECT_NAME$ENVIRONMENT$UNIQUE_SUFFIX"  # Must be globally unique, alphanumeric only

# Deployment Preferences
$DEPLOYMENT_TYPE = "app-service"  # aci, aks, app-service, arm
$IMAGE_TAG = "v1.0"

# App Service Specific Configuration
$APP_SERVICE_PLAN = "$PROJECT_NAME-$ENVIRONMENT-plan"
$BACKEND_APP_NAME = "$PROJECT_NAME-$ENVIRONMENT-backend-$UNIQUE_SUFFIX"
$FRONTEND_APP_NAME = "$PROJECT_NAME-$ENVIRONMENT-frontend-$UNIQUE_SUFFIX"
$APP_SERVICE_SKU = "B1"  # F1 (Free), B1 (Basic), S1 (Standard), P1V2 (Premium)

# AKS Specific Configuration
$AKS_CLUSTER_NAME = "$PROJECT_NAME-$ENVIRONMENT-aks"
$AKS_NODE_COUNT = "2"
$AKS_NODE_SIZE = "Standard_B2s"

Write-Host "📋 Azure Configuration Loaded:" -ForegroundColor Green
Write-Host "   Subscription: $AZURE_SUBSCRIPTION_ID" -ForegroundColor Cyan
Write-Host "   Resource Group: $RESOURCE_GROUP" -ForegroundColor Cyan
Write-Host "   ACR Name: $ACR_NAME" -ForegroundColor Cyan
Write-Host "   Location: $AZURE_DEFAULT_LOCATION" -ForegroundColor Cyan
Write-Host "   Deployment Type: $DEPLOYMENT_TYPE" -ForegroundColor Cyan
