#!/bin/bash

# Docker Build and Push Script for Pharmacy Inventory System
# This script builds and pushes Docker images to Docker Hub

# Exit on any error
set -e

# Configuration
DOCKER_USERNAME="nirmalkoswatta"  # Replace with your Docker Hub username
BACKEND_IMAGE="pharmacy-backend"
FRONTEND_IMAGE="pharmacy-frontend"
VERSION="v1.0.0"

echo "🐳 Building Docker Images for Pharmacy Inventory System"
echo "======================================================="

# Build Backend Image
echo "📦 Building Backend Image..."
docker build -t ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION} ./backend
docker tag ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION} ${DOCKER_USERNAME}/${BACKEND_IMAGE}:latest

# Build Frontend Image
echo "📦 Building Frontend Image..."
docker build -t ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION} ./frontend
docker tag ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION} ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:latest

echo "✅ Docker Images Built Successfully!"
echo ""
echo "📋 Built Images:"
echo "  - ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION}"
echo "  - ${DOCKER_USERNAME}/${BACKEND_IMAGE}:latest"
echo "  - ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION}"
echo "  - ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:latest"
echo ""

# Ask for push confirmation
read -p "🚀 Do you want to push images to Docker Hub? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📤 Pushing Images to Docker Hub..."
    
    # Login to Docker Hub (you'll be prompted for credentials)
    echo "🔐 Please login to Docker Hub:"
    docker login
    
    # Push Backend Images
    echo "📤 Pushing Backend Images..."
    docker push ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION}
    docker push ${DOCKER_USERNAME}/${BACKEND_IMAGE}:latest
    
    # Push Frontend Images
    echo "📤 Pushing Frontend Images..."
    docker push ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION}
    docker push ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:latest
    
    echo "✅ All Images Pushed Successfully!"
    echo ""
    echo "🌐 Images are now available at:"
    echo "  - https://hub.docker.com/r/${DOCKER_USERNAME}/${BACKEND_IMAGE}"
    echo "  - https://hub.docker.com/r/${DOCKER_USERNAME}/${FRONTEND_IMAGE}"
else
    echo "⏭️  Skipping push to Docker Hub"
fi

echo ""
echo "🎉 Docker build process completed!"
echo ""
echo "💡 To run the application locally:"
echo "   docker-compose up --build"
echo ""
echo "💡 To use the images in Kubernetes:"
echo "   Update k8s/*.yaml files with your Docker Hub username"
echo "   kubectl apply -f k8s/"
