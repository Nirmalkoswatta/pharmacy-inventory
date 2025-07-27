# Azure Deployment Guide for Pharmacy Inventory

This guide provides comprehensive instructions for deploying the Pharmacy Inventory application to Microsoft Azure using various deployment methods.

## 📋 Prerequisites

Before starting the deployment, ensure you have:

1. **Azure CLI** installed and configured

   ```powershell
   # Install Azure CLI
   # Download from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

   # Login to Azure
   az login

   # Set your subscription (if you have multiple)
   az account set --subscription "Your Subscription Name"
   ```

2. **Docker Desktop** (for local builds)

   - Download from: https://www.docker.com/products/docker-desktop

3. **kubectl** (for AKS deployment)

   - Download from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/

4. **PowerShell 5.1 or later**

## 🚀 Quick Start

### Option 1: One-Command Deployment

Use the main deployment script to deploy using your preferred method:

```powershell
# Azure Container Instances (Simplest)
.\azure\deploy.ps1 -DeploymentType "aci" -ResourceGroup "my-pharmacy-rg"

# Azure Kubernetes Service (Production-ready)
.\azure\deploy.ps1 -DeploymentType "aks" -ResourceGroup "my-pharmacy-rg"

# Azure App Service (Platform-as-a-Service)
.\azure\deploy.ps1 -DeploymentType "app-service" -ResourceGroup "my-pharmacy-rg"

# ARM Templates (Infrastructure as Code)
.\azure\deploy.ps1 -DeploymentType "arm" -ResourceGroup "my-pharmacy-rg"
```

## 📦 Deployment Methods

### 1. Azure Container Instances (ACI)

**Best for**: Development, testing, simple deployments

**Pros**:

- Fastest to deploy
- Pay-per-second billing
- No cluster management

**Cons**:

- Limited scalability
- No load balancing
- Basic networking

```powershell
# Deploy to ACI
.\azure\aci\deploy-aci.ps1 -ResourceGroup "pharmacy-aci-rg" -RegistryName "pharmacyacr123"
```

### 2. Azure Kubernetes Service (AKS)

**Best for**: Production, high availability, scalability

**Pros**:

- Full Kubernetes features
- Auto-scaling
- Rolling updates
- Advanced networking

**Cons**:

- More complex
- Higher cost
- Requires Kubernetes knowledge

```powershell
# Deploy to AKS
.\azure\aks\deploy-aks.ps1 -ResourceGroup "pharmacy-aks-rg" -ClusterName "pharmacy-cluster" -RegistryName "pharmacyacr123"
```

### 3. Azure App Service

**Best for**: Web applications, managed platform

**Pros**:

- Managed platform
- Built-in CI/CD
- SSL certificates
- Custom domains

**Cons**:

- Limited to web workloads
- Less control over environment

```powershell
# Deploy to App Service
.\azure\app-service\deploy-app-service.ps1 -ResourceGroup "pharmacy-app-rg" -AppServicePlan "pharmacy-plan" -BackendAppName "pharmacy-backend-app" -FrontendAppName "pharmacy-frontend-app" -RegistryName "pharmacyacr123"
```

### 4. ARM Templates

**Best for**: Infrastructure as Code, repeatable deployments

**Pros**:

- Version controlled infrastructure
- Consistent deployments
- Easy rollbacks

```powershell
# Deploy using ARM templates
.\azure\arm-templates\deploy-arm.ps1 -ResourceGroup "pharmacy-arm-rg"
```

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Azure CDN     │    │  Application     │    │   Cosmos DB     │
│   (Optional)    │───▶│   Gateway        │───▶│   (MongoDB API) │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                        ┌───────▼───────┐
                        │  Load Balancer │
                        └───────┬───────┘
                                │
                    ┌───────────▼───────────┐
                    │                       │
            ┌───────▼────────┐    ┌─────────▼────────┐
            │   Frontend      │    │    Backend       │
            │   (React)       │    │   (Node.js)      │
            │   Container     │    │   Container      │
            └────────────────┘    └──────────────────┘
```

## 💰 Cost Estimation

### Development/Testing (ACI)

- **Container Instances**: ~$30-50/month
- **Container Registry**: ~$5/month
- **Cosmos DB**: ~$25/month (400 RU/s)
- **Total**: ~$60-80/month

### Production (AKS)

- **AKS Cluster**: ~$75/month (2 B2s nodes)
- **Container Registry**: ~$20/month
- **Cosmos DB**: ~$50/month (1000 RU/s)
- **Load Balancer**: ~$20/month
- **Total**: ~$165/month

### Production (App Service)

- **App Service Plan**: ~$55/month (B1)
- **Container Registry**: ~$20/month
- **Cosmos DB**: ~$50/month (1000 RU/s)
- **Total**: ~$125/month

## 🔧 Configuration

### Environment Variables

The application uses the following environment variables:

**Backend**:

- `NODE_ENV`: Environment (development/production)
- `PORT`: Server port (default: 4000)
- `MONGO_URI`: MongoDB connection string
- `FRONTEND_URL`: Frontend application URL

**Frontend**:

- `REACT_APP_GRAPHQL_URI`: GraphQL endpoint URL

### Database Configuration

The application supports both:

- **MongoDB**: Traditional MongoDB instance
- **Azure Cosmos DB**: MongoDB API with global distribution

## 📊 Monitoring and Logging

### Application Insights

All deployments include Azure Application Insights for:

- Application performance monitoring
- Error tracking
- User analytics
- Custom metrics

### Log Analytics

- Container logs
- Performance metrics
- Security auditing

## 🔒 Security

### Network Security

- Virtual networks for isolation
- Network security groups
- Private endpoints for databases

### Authentication

- Managed Identity for Azure resources
- Azure AD integration (optional)
- SSL/TLS encryption

### Secrets Management

- Azure Key Vault integration
- Container registry credentials
- Database connection strings

## 🚀 CI/CD Pipeline

### Azure DevOps

The included `azure-pipelines.yml` provides:

- Automated testing
- Docker image building
- Multi-environment deployment
- Rollback capabilities

### GitHub Actions (Alternative)

```yaml
# .github/workflows/azure-deploy.yml
name: Deploy to Azure
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      - name: Deploy to Azure
        run: |
          az acr build --registry ${{ secrets.ACR_NAME }} --image pharmacy-backend .
```

## 🔄 Scaling

### Horizontal Scaling

```powershell
# AKS Scaling
kubectl scale deployment pharmacy-backend --replicas=5 -n pharmacy-inventory

# App Service Scaling
az appservice plan update --name pharmacy-plan --resource-group pharmacy-rg --number-of-workers 3
```

### Vertical Scaling

```powershell
# App Service - Scale up
az appservice plan update --name pharmacy-plan --resource-group pharmacy-rg --sku P1V2

# AKS - Update node size (requires node pool update)
az aks nodepool update --cluster-name pharmacy-cluster --name agentpool --resource-group pharmacy-rg
```

## 🛠️ Troubleshooting

### Common Issues

1. **ACR Authentication Failed**

   ```powershell
   az acr login --name your-registry-name
   ```

2. **Container Failed to Start**

   ```powershell
   # Check logs
   az container logs --resource-group pharmacy-rg --name pharmacy-backend

   # For App Service
   az webapp log tail --name pharmacy-backend --resource-group pharmacy-rg
   ```

3. **Database Connection Issues**
   - Verify connection string
   - Check firewall rules
   - Validate credentials

### Useful Commands

```powershell
# List all resources
az resource list --resource-group pharmacy-rg --output table

# Get container logs
az container logs --resource-group pharmacy-rg --name container-name

# Restart app service
az webapp restart --name app-name --resource-group pharmacy-rg

# Check AKS cluster status
kubectl get nodes
kubectl get pods -n pharmacy-inventory

# Monitor deployment
az group deployment operation list --resource-group pharmacy-rg --name deployment-name
```

## 🧹 Cleanup

To remove all resources and avoid charges:

```powershell
# Delete everything
.\azure\cleanup.ps1 -ResourceGroup "pharmacy-rg" -Force

# Dry run (see what would be deleted)
.\azure\cleanup.ps1 -ResourceGroup "pharmacy-rg" -DryRun
```

## 📞 Support

For issues and questions:

1. Check the troubleshooting section
2. Review Azure documentation
3. Open an issue in the repository
4. Contact your Azure support team

---

## 📚 Additional Resources

- [Azure Container Instances Documentation](https://docs.microsoft.com/en-us/azure/container-instances/)
- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure Resource Manager Templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/)
- [Azure DevOps Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/)
