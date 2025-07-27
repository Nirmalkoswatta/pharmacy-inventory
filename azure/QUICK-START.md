# 🚀 Azure Deployment Quick Reference

## Prerequisites

- Azure CLI installed and logged in (`az login`)
- Docker Desktop running
- PowerShell 5.1+

## 🎯 Quick Deploy Commands

### 1. Simple Development Deployment (ACI)

```powershell
.\azure\deploy.ps1 -DeploymentType "aci" -ResourceGroup "pharmacy-dev-rg"
```

**Time**: ~10 minutes | **Cost**: ~$60/month

### 2. Production Deployment (App Service)

```powershell
.\azure\deploy.ps1 -DeploymentType "app-service" -ResourceGroup "pharmacy-prod-rg"
```

**Time**: ~15 minutes | **Cost**: ~$125/month

### 3. Scalable Production (AKS)

```powershell
.\azure\deploy.ps1 -DeploymentType "aks" -ResourceGroup "pharmacy-k8s-rg"
```

**Time**: ~25 minutes | **Cost**: ~$165/month

### 4. Infrastructure as Code (ARM)

```powershell
.\azure\deploy.ps1 -DeploymentType "arm" -ResourceGroup "pharmacy-iac-rg"
```

**Time**: ~20 minutes | **Cost**: ~$125/month

## 📊 Check Status

```powershell
.\azure\status.ps1 -ResourceGroup "your-resource-group"
```

## 🧹 Cleanup

```powershell
.\azure\cleanup.ps1 -ResourceGroup "your-resource-group" -Force
```

## 🔗 Access Your Application

After deployment, your application will be available at:

- **ACI**: IP address shown in deployment output
- **App Service**: `https://your-frontend-app.azurewebsites.net`
- **AKS**: IP address from ingress controller
- **ARM**: URLs shown in deployment output

## 📞 Support

- Check deployment logs in Azure Portal
- Use `.\azure\status.ps1` for health checks
- Review troubleshooting in `azure\README.md`
