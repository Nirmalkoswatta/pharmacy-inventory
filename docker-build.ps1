# Docker Build and Push Script for Pharmacy Inventory System (PowerShell)
# This script builds and pushes Docker images to Docker Hub

# Configuration
$DOCKER_USERNAME = "nirmalkoswatta"  # Replace with your Docker Hub username
$BACKEND_IMAGE = "pharmacy-backend"
$FRONTEND_IMAGE = "pharmacy-frontend"
$VERSION = "v1.0.0"

Write-Host "🐳 Building Docker Images for Pharmacy Inventory System" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

try {
    # Build Backend Image
    Write-Host "📦 Building Backend Image..." -ForegroundColor Yellow
    docker build -t "${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION}" ./backend
    docker tag "${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION}" "${DOCKER_USERNAME}/${BACKEND_IMAGE}:latest"

    # Build Frontend Image
    Write-Host "📦 Building Frontend Image..." -ForegroundColor Yellow
    docker build -t "${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION}" ./frontend
    docker tag "${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION}" "${DOCKER_USERNAME}/${FRONTEND_IMAGE}:latest"

    Write-Host "✅ Docker Images Built Successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Built Images:" -ForegroundColor Cyan
    Write-Host "  - ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION}"
    Write-Host "  - ${DOCKER_USERNAME}/${BACKEND_IMAGE}:latest"
    Write-Host "  - ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION}"
    Write-Host "  - ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:latest"
    Write-Host ""

    # Ask for push confirmation
    $response = Read-Host "🚀 Do you want to push images to Docker Hub? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        Write-Host "📤 Pushing Images to Docker Hub..." -ForegroundColor Yellow
        
        # Login to Docker Hub
        Write-Host "🔐 Please login to Docker Hub:" -ForegroundColor Cyan
        docker login
        
        # Push Backend Images
        Write-Host "📤 Pushing Backend Images..." -ForegroundColor Yellow
        docker push "${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION}"
        docker push "${DOCKER_USERNAME}/${BACKEND_IMAGE}:latest"
        
        # Push Frontend Images
        Write-Host "📤 Pushing Frontend Images..." -ForegroundColor Yellow
        docker push "${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION}"
        docker push "${DOCKER_USERNAME}/${FRONTEND_IMAGE}:latest"
        
        Write-Host "✅ All Images Pushed Successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🌐 Images are now available at:" -ForegroundColor Cyan
        Write-Host "  - https://hub.docker.com/r/${DOCKER_USERNAME}/${BACKEND_IMAGE}"
        Write-Host "  - https://hub.docker.com/r/${DOCKER_USERNAME}/${FRONTEND_IMAGE}"
    } else {
        Write-Host "⏭️  Skipping push to Docker Hub" -ForegroundColor Yellow
    }

} catch {
    Write-Host "❌ Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Docker build process completed!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 To run the application locally:" -ForegroundColor Cyan
Write-Host "   docker-compose up --build"
Write-Host ""
Write-Host "💡 To use the images in Kubernetes:" -ForegroundColor Cyan
Write-Host "   Update k8s/*.yaml files with your Docker Hub username"
Write-Host "   kubectl apply -f k8s/"
