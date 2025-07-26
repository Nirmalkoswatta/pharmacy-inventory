# Deployment Guide

## Overview

This guide covers deployment options for the Pharmacy Inventory Management System across different environments.

## Deployment Options

### 1. Local Development (Docker Compose)
### 2. Staging Environment (Docker Compose)
### 3. Production (Kubernetes)
### 4. Cloud Deployments (AWS, GCP, Azure)

---

## 1. Local Development Deployment

### Quick Start
```bash
# Using setup script (recommended)
./setup.sh  # Linux/Mac
# or
./setup.ps1  # Windows PowerShell

# Manual setup
docker-compose up --build -d
```

### Access Points
- **Frontend**: http://localhost:3000
- **Backend**: http://localhost:4000
- **GraphQL Playground**: http://localhost:4000/graphql
- **MongoDB Admin**: http://localhost:8081

### Environment Variables
Copy and customize environment files:
```bash
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
```

---

## 2. Staging Environment

### Using Docker Compose with Overrides

Create `docker-compose.staging.yml`:
```yaml
version: '3.8'
services:
  frontend:
    environment:
      - REACT_APP_GRAPHQL_URI=https://api-staging.yoursite.com/graphql
  
  backend:
    environment:
      - NODE_ENV=staging
      - FRONTEND_URL=https://staging.yoursite.com
```

Deploy:
```bash
docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d
```

---

## 3. Production Deployment (Kubernetes)

### Prerequisites
- Kubernetes cluster (v1.20+)
- kubectl configured
- Docker Hub account for images

### Step 1: Build and Push Images

```bash
# Build and tag images
docker build -t yourusername/pharmacy-backend:v1.0.0 ./backend
docker build -t yourusername/pharmacy-frontend:v1.0.0 ./frontend

# Push to registry
docker push yourusername/pharmacy-backend:v1.0.0
docker push yourusername/pharmacy-frontend:v1.0.0
```

### Step 2: Update Kubernetes Manifests

Update image references in `k8s/*.yaml`:
```bash
sed -i 's|your-dockerhub-username|yourusername|g' k8s/*.yaml
sed -i 's|:latest|:v1.0.0|g' k8s/*.yaml
```

### Step 3: Deploy to Kubernetes

```bash
# Create namespace
kubectl create namespace pharmacy

# Apply manifests
kubectl apply -f k8s/ -n pharmacy

# Check deployment status
kubectl get pods -n pharmacy
kubectl get services -n pharmacy
```

### Step 4: Access the Application

#### Using NodePort
```bash
# Get the NodePort
kubectl get service frontend -n pharmacy

# Access via: http://<node-ip>:30007
```

#### Using Ingress (Recommended)
```bash
# Install NGINX Ingress Controller (if not already installed)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Apply ingress
kubectl apply -f k8s/ingress.yaml -n pharmacy

# Add to /etc/hosts (for local testing)
echo "127.0.0.1 pharmacy.local" >> /etc/hosts

# Access via: http://pharmacy.local
```

---

## 4. Cloud Deployments

### AWS EKS

#### Prerequisites
- AWS CLI configured
- eksctl installed

#### Setup
```bash
# Create EKS cluster
eksctl create cluster --name pharmacy-cluster --region us-west-2

# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name pharmacy-cluster

# Deploy application
kubectl apply -f k8s/ -n pharmacy
```

#### Using ALB Ingress
```bash
# Install AWS Load Balancer Controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

# Update ingress for ALB
# Add annotation: kubernetes.io/ingress.class: alb
```

### Google GKE

#### Setup
```bash
# Create GKE cluster
gcloud container clusters create pharmacy-cluster \
    --zone us-central1-a \
    --num-nodes 3

# Get credentials
gcloud container clusters get-credentials pharmacy-cluster --zone us-central1-a

# Deploy application
kubectl apply -f k8s/ -n pharmacy
```

### Azure AKS

#### Setup
```bash
# Create resource group
az group create --name pharmacy-rg --location eastus

# Create AKS cluster
az aks create \
    --resource-group pharmacy-rg \
    --name pharmacy-cluster \
    --node-count 3 \
    --enable-addons monitoring \
    --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group pharmacy-rg --name pharmacy-cluster

# Deploy application
kubectl apply -f k8s/ -n pharmacy
```

---

## CI/CD Pipeline Deployment

### GitHub Actions Setup

1. **Add secrets to GitHub repository**:
   - `DOCKER_USERNAME`: Your Docker Hub username
   - `DOCKER_PASSWORD`: Your Docker Hub password/token
   - `KUBE_CONFIG`: Base64 encoded kubeconfig file

2. **Generate kubeconfig secret**:
```bash
# Get your kubeconfig
cat ~/.kube/config | base64 -w 0

# Add this as KUBE_CONFIG secret in GitHub
```

3. **Push to main branch** triggers automatic deployment

### Pipeline Features
- ✅ Automated testing
- ✅ Security scanning
- ✅ Multi-architecture builds
- ✅ Kubernetes deployment
- ✅ Rollback capability

---

## Monitoring and Observability

### Health Checks
```bash
# Check application health
curl http://your-domain/health

# Check backend health
curl http://your-domain:4000/health
```

### Kubernetes Monitoring
```bash
# Check pods
kubectl get pods -n pharmacy

# Check logs
kubectl logs -f deployment/backend -n pharmacy
kubectl logs -f deployment/frontend -n pharmacy

# Check resource usage
kubectl top pods -n pharmacy
```

### Prometheus & Grafana (Optional)
```bash
# Install monitoring stack
kubectl create namespace monitoring
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring
```

---

## Backup and Recovery

### Database Backup
```bash
# MongoDB backup
kubectl exec -it deployment/mongo -n pharmacy -- mongodump --db pharmacy --out /tmp/backup

# Copy backup from pod
kubectl cp pharmacy/mongo-pod:/tmp/backup ./backup
```

### Application Data
```bash
# Backup persistent volumes
kubectl get pv
kubectl describe pv <volume-name>
```

---

## Security Best Practices

### 1. Image Security
- Use specific image tags (not `latest`)
- Scan images for vulnerabilities
- Use minimal base images

### 2. Kubernetes Security
- Use namespaces for isolation
- Implement RBAC
- Use network policies
- Set resource limits

### 3. Secrets Management
- Never commit secrets to Git
- Use Kubernetes secrets or external secret managers
- Rotate secrets regularly

### 4. Network Security
- Use HTTPS/TLS
- Implement proper CORS policies
- Use network policies for pod-to-pod communication

---

## Scaling

### Horizontal Pod Autoscaler
Already configured in `k8s/` manifests:
- Backend: 2-10 replicas based on CPU/Memory
- Frontend: 2-5 replicas based on CPU/Memory

### Manual Scaling
```bash
# Scale backend
kubectl scale deployment backend --replicas=5 -n pharmacy

# Scale frontend
kubectl scale deployment frontend --replicas=3 -n pharmacy
```

---

## Troubleshooting

### Common Issues

#### 1. Pods Not Starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n pharmacy

# Check logs
kubectl logs <pod-name> -n pharmacy
```

#### 2. Database Connection Issues
```bash
# Check MongoDB pod
kubectl exec -it deployment/mongo -n pharmacy -- mongosh

# Verify connection string
kubectl get configmap backend-config -n pharmacy -o yaml
```

#### 3. Image Pull Errors
```bash
# Check image name and tag
kubectl describe pod <pod-name> -n pharmacy

# Verify image exists in registry
docker pull yourusername/pharmacy-backend:v1.0.0
```

#### 4. Service Discovery Issues
```bash
# Check services
kubectl get svc -n pharmacy

# Test internal connectivity
kubectl exec -it deployment/backend -n pharmacy -- curl http://mongo:27017
```

---

## Rollback Procedures

### Kubernetes Rollback
```bash
# Check rollout history
kubectl rollout history deployment/backend -n pharmacy

# Rollback to previous version
kubectl rollout undo deployment/backend -n pharmacy

# Rollback to specific revision
kubectl rollout undo deployment/backend --to-revision=2 -n pharmacy
```

### Docker Compose Rollback
```bash
# Stop current version
docker-compose down

# Pull previous image version
docker pull yourusername/pharmacy-backend:v0.9.0

# Update docker-compose.yml with previous version
# Start with previous version
docker-compose up -d
```

---

## Performance Optimization

### Database Optimization
- Ensure proper indexing
- Monitor query performance
- Use connection pooling

### Application Optimization
- Enable gzip compression
- Use CDN for static assets
- Implement caching strategies

### Kubernetes Optimization
- Set appropriate resource requests/limits
- Use node affinity for optimal scheduling
- Monitor cluster resource usage

---

## Support and Maintenance

### Regular Tasks
- Monitor application logs
- Check resource usage
- Update dependencies
- Backup database
- Security updates

### Monitoring Alerts
Set up alerts for:
- Pod restart loops
- High memory/CPU usage
- Database connection failures
- SSL certificate expiration

---

For additional help, check:
- [DEVELOPMENT.md](DEVELOPMENT.md) for development setup
- [README.md](README.md) for project overview
- GitHub Issues for known problems
