# Simple Backend Deployment
param(
    [string]$BackendAppName = "pharmacy-backend-07270422",
    [string]$ResourceGroup = "pharmacy-inventory"
)

Write-Host "=== Simple Backend Deployment ===" -ForegroundColor Green

Set-Location "backend"

# Create a minimal backend for Azure
if (Test-Path "deploy") { Remove-Item "deploy" -Recurse -Force }
New-Item -ItemType Directory -Path "deploy" | Out-Null

# Create minimal package.json for Azure
$minimalPackage = @'
{
  "name": "pharmacy-backend",
  "version": "1.0.0",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.0",
    "cors": "^2.8.5"
  }
}
'@

$minimalPackage | Out-File -FilePath "deploy/package.json" -Encoding utf8

# Create simple Express server that works on Azure
$simpleServer = @'
const express = require('express');
const cors = require('cors');
const app = express();

// Enable CORS
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Pharmacy Inventory Backend API',
    status: 'running',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    endpoints: {
      health: '/',
      medicines: '/medicines',
      suppliers: '/suppliers',
      orders: '/orders'
    }
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Mock medicines endpoint
app.get('/medicines', (req, res) => {
  res.json({
    data: [
      {
        id: '1',
        name: 'Aspirin',
        description: 'Pain reliever and fever reducer',
        price: 9.99,
        quantity: 100,
        category: 'Over-the-counter'
      },
      {
        id: '2', 
        name: 'Ibuprofen',
        description: 'Anti-inflammatory pain reliever',
        price: 12.50,
        quantity: 75,
        category: 'Over-the-counter'
      }
    ],
    message: 'Sample medicines data - connect to MongoDB for real data'
  });
});

// Mock suppliers endpoint
app.get('/suppliers', (req, res) => {
  res.json({
    data: [
      {
        id: '1',
        name: 'MediSupply Corp',
        contact: 'contact@medisupply.com',
        phone: '555-0123'
      },
      {
        id: '2',
        name: 'PharmaDirect Ltd',
        contact: 'info@pharmadirect.com', 
        phone: '555-0456'
      }
    ],
    message: 'Sample suppliers data - connect to MongoDB for real data'
  });
});

// Mock orders endpoint
app.get('/orders', (req, res) => {
  res.json({
    data: [
      {
        id: '1',
        medicine: 'Aspirin',
        quantity: 50,
        supplier: 'MediSupply Corp',
        status: 'pending',
        orderDate: '2025-07-26'
      }
    ],
    message: 'Sample orders data - connect to MongoDB for real data'
  });
});

// GraphQL placeholder endpoint
app.get('/graphql', (req, res) => {
  res.json({
    message: 'GraphQL endpoint ready',
    note: 'Deploy the full GraphQL server for complete functionality'
  });
});

app.post('/graphql', (req, res) => {
  res.json({
    message: 'GraphQL endpoint ready',
    note: 'Deploy the full GraphQL server for complete functionality'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    availableEndpoints: ['/', '/health', '/medicines', '/suppliers', '/orders', '/graphql']
  });
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log(`🏥 Pharmacy Backend API running on port ${port}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
});
'@

$simpleServer | Out-File -FilePath "deploy/server.js" -Encoding utf8

# Deploy
Compress-Archive -Path "deploy/*" -DestinationPath "simple-backend.zip" -Force
az webapp deploy --resource-group $ResourceGroup --name $BackendAppName --src-path "simple-backend.zip" --type zip

# Clean up
Remove-Item "deploy" -Recurse -Force
Remove-Item "simple-backend.zip" -Force

Set-Location ".."

Write-Host ""
Write-Host "=== SIMPLE BACKEND DEPLOYED ===" -ForegroundColor Green
Write-Host ""
Write-Host "Backend API: https://$BackendAppName.azurewebsites.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available endpoints:" -ForegroundColor Yellow
Write-Host "• GET  / - API info and status"
Write-Host "• GET  /health - Health check"  
Write-Host "• GET  /medicines - Sample medicines data"
Write-Host "• GET  /suppliers - Sample suppliers data"
Write-Host "• GET  /orders - Sample orders data"
Write-Host "• GET/POST /graphql - GraphQL placeholder"
Write-Host ""
Write-Host "Basic backend is now running!" -ForegroundColor Green
Write-Host "To deploy full GraphQL backend, copy your schema.js and resolvers.js" -ForegroundColor Yellow
