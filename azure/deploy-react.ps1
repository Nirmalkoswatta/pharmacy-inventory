# Deploy React Build to Azure
param(
    [string]$FrontendAppName = "pharmacy-frontend-07270422",
    [string]$BackendAppName = "pharmacy-backend-07270422", 
    [string]$ResourceGroup = "pharmacy-inventory"
)

Write-Host "=== Deploying React Build to Azure ===" -ForegroundColor Green

Set-Location "frontend"

# Check if build directory exists
if (-not (Test-Path "build")) {
    Write-Host "❌ Build directory not found!" -ForegroundColor Red
    Write-Host "Please run 'npm run build' first" -ForegroundColor Yellow
    return
}

Write-Host "✅ Found React build directory" -ForegroundColor Green

# Create deployment package
if (Test-Path "deploy") { Remove-Item "deploy" -Recurse -Force }
New-Item -ItemType Directory -Path "deploy" | Out-Null

Write-Host "📦 Copying React build files..." -ForegroundColor Yellow

# Copy all build files
Copy-Item "build/*" "deploy/" -Recurse

# Update the index.html to include backend URL
$indexPath = "deploy/index.html"
if (Test-Path $indexPath) {
    $indexContent = Get-Content $indexPath -Raw
    
    # Add backend configuration script
    $configScript = @"
<script>
  window.BACKEND_URL = 'https://$BackendAppName.azurewebsites.net';
  window.GRAPHQL_URI = 'https://$BackendAppName.azurewebsites.net/graphql';
  console.log('Backend configured:', window.BACKEND_URL);
</script>
</head>
"@
    
    $indexContent = $indexContent -replace "</head>", $configScript
    $indexContent | Out-File -FilePath $indexPath -Encoding utf8
    
    Write-Host "✅ Updated index.html with backend configuration" -ForegroundColor Green
}

# Create package.json for Express server
$packageJson = @'
{
  "name": "pharmacy-frontend",
  "version": "1.0.0",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.0",
    "path": "^0.12.7"
  }
}
'@

$packageJson | Out-File -FilePath "deploy/package.json" -Encoding utf8

# Create Express server to serve React app
$serverJs = @'
const express = require('express');
const path = require('path');
const app = express();

// Serve static files from the current directory (build files)
app.use(express.static(__dirname));

// Enable CORS for API calls
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  next();
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    frontend: 'React App',
    backend: process.env.BACKEND_URL || 'Not configured'
  });
});

// Handle React Router - serve index.html for all non-API routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`🏥 Pharmacy Frontend (React) running on port ${port}`);
  console.log(`📊 Backend URL: ${process.env.BACKEND_URL || 'Not configured'}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'production'}`);
});
'@

$serverJs | Out-File -FilePath "deploy/server.js" -Encoding utf8

Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow

# Create ZIP file
if (Test-Path "react-app.zip") { Remove-Item "react-app.zip" -Force }
Compress-Archive -Path "deploy/*" -DestinationPath "react-app.zip" -Force

Write-Host "🚀 Deploying React app to Azure..." -ForegroundColor Green

# Deploy to Azure
az webapp deploy --resource-group $ResourceGroup --name $FrontendAppName --src-path "react-app.zip" --type zip

# Set environment variables
Write-Host "⚙️ Setting environment variables..." -ForegroundColor Yellow
az webapp config appsettings set --resource-group $ResourceGroup --name $FrontendAppName --settings "BACKEND_URL=https://$BackendAppName.azurewebsites.net" "NODE_ENV=production"

# Clean up
Remove-Item "deploy" -Recurse -Force
Remove-Item "react-app.zip" -Force

Set-Location ".."

Write-Host ""
Write-Host "=== REACT APP DEPLOYED SUCCESSFULLY ===" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 Your pharmacy inventory React app is live!" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔗 App URLs:" -ForegroundColor White
Write-Host "   Frontend (React): https://$FrontendAppName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "   Backend API:      https://$BackendAppName.azurewebsites.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Features deployed:" -ForegroundColor Green
Write-Host "   • Complete React application"
Write-Host "   • Medicine management forms"
Write-Host "   • Dashboard interface"
Write-Host "   • Responsive design"
Write-Host "   • Backend API integration ready"
Write-Host ""
Write-Host "⏰ Note: App may take 30-60 seconds to start after deployment" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔧 Next steps:" -ForegroundColor White
Write-Host "   • Visit the frontend URL to see your React app"
Write-Host "   • Set up MongoDB database for persistent data"
Write-Host "   • Configure GraphQL backend for full functionality"
Write-Host ""
Write-Host "🎯 Ready to use!" -ForegroundColor Green
