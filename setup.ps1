# Pharmacy Inventory Management System - PowerShell Setup Script
# This script helps you quickly set up the development environment on Windows

Write-Host "🏥 Pharmacy Inventory Management System - Setup Script" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green

# Check if Docker is installed
try {
    docker --version | Out-Null
    Write-Host "✅ Docker is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not installed. Please install Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Check if Docker Compose is installed
try {
    docker-compose --version | Out-Null
    Write-Host "✅ Docker Compose is available" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Compose is not available. Please install Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Check if Node.js is installed
try {
    node --version | Out-Null
    Write-Host "✅ Node.js is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js is not installed. Please install Node.js 18+ first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Prerequisites check passed!" -ForegroundColor Green

# Function to setup environment files
function Setup-EnvFiles {
    Write-Host "📝 Setting up environment files..." -ForegroundColor Yellow
    
    if (!(Test-Path "backend\.env")) {
        Copy-Item "backend\.env.example" "backend\.env"
        Write-Host "✅ Backend .env file created" -ForegroundColor Green
    }
    
    if (!(Test-Path "frontend\.env")) {
        Copy-Item "frontend\.env.example" "frontend\.env"
        Write-Host "✅ Frontend .env file created" -ForegroundColor Green
    }
}

# Function to install dependencies
function Install-Dependencies {
    Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
    
    Write-Host "  🔧 Installing backend dependencies..." -ForegroundColor Cyan
    Set-Location backend
    npm install
    Set-Location ..
    
    Write-Host "  🎨 Installing frontend dependencies..." -ForegroundColor Cyan
    Set-Location frontend
    npm install
    Set-Location ..
    
    Write-Host "✅ Dependencies installed successfully!" -ForegroundColor Green
}

# Function to start services
function Start-Services {
    Write-Host "🚀 Starting services with Docker Compose..." -ForegroundColor Yellow
    docker-compose up -d
    
    Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    # Check if services are running
    $status = docker-compose ps
    if ($status -match "Up") {
        Write-Host "✅ Services started successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🌐 Application URLs:" -ForegroundColor Cyan
        Write-Host "   Frontend:        http://localhost:3000" -ForegroundColor White
        Write-Host "   Backend API:     http://localhost:4000" -ForegroundColor White
        Write-Host "   GraphQL:         http://localhost:4000/graphql" -ForegroundColor White
        Write-Host "   MongoDB Admin:   http://localhost:8081 (admin/admin123)" -ForegroundColor White
        Write-Host ""
        Write-Host "📝 To view logs: docker-compose logs -f" -ForegroundColor Yellow
        Write-Host "🛑 To stop: docker-compose down" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Some services failed to start. Check logs with: docker-compose logs" -ForegroundColor Red
    }
}

# Function to run tests
function Run-Tests {
    Write-Host "🧪 Running tests..." -ForegroundColor Yellow
    
    Write-Host "  🔧 Running backend tests..." -ForegroundColor Cyan
    Set-Location backend
    npm test
    Set-Location ..
    
    Write-Host "  🎨 Running frontend tests..." -ForegroundColor Cyan
    Set-Location frontend
    npm test -- --watchAll=false
    Set-Location ..
    
    Write-Host "✅ All tests passed!" -ForegroundColor Green
}

# Main menu loop
while ($true) {
    Write-Host ""
    Write-Host "What would you like to do?" -ForegroundColor Cyan
    Write-Host "1) 🛠️  Full setup (env files + dependencies + start services)" -ForegroundColor White
    Write-Host "2) 📝 Setup environment files only" -ForegroundColor White
    Write-Host "3) 📦 Install dependencies only" -ForegroundColor White
    Write-Host "4) 🚀 Start services only" -ForegroundColor White
    Write-Host "5) 🧪 Run tests" -ForegroundColor White
    Write-Host "6) 📊 Show service status" -ForegroundColor White
    Write-Host "7) 🛑 Stop services" -ForegroundColor White
    Write-Host "8) 🧹 Clean up (stop services and remove volumes)" -ForegroundColor White
    Write-Host "9) ❌ Exit" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (1-9)"

    switch ($choice) {
        "1" {
            Setup-EnvFiles
            Install-Dependencies
            Start-Services
        }
        "2" {
            Setup-EnvFiles
        }
        "3" {
            Install-Dependencies
        }
        "4" {
            Start-Services
        }
        "5" {
            Run-Tests
        }
        "6" {
            Write-Host "📊 Service Status:" -ForegroundColor Cyan
            docker-compose ps
        }
        "7" {
            Write-Host "🛑 Stopping services..." -ForegroundColor Yellow
            docker-compose stop
            Write-Host "✅ Services stopped!" -ForegroundColor Green
        }
        "8" {
            Write-Host "🧹 Cleaning up..." -ForegroundColor Yellow
            docker-compose down -v
            docker system prune -f
            Write-Host "✅ Cleanup completed!" -ForegroundColor Green
        }
        "9" {
            Write-Host "👋 Goodbye!" -ForegroundColor Green
            exit 0
        }
        default {
            Write-Host "❌ Invalid option. Please try again." -ForegroundColor Red
        }
    }
}
