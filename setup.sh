#!/bin/bash

# Pharmacy Inventory Management System - Quick Setup Script
# This script helps you quickly set up the development environment

set -e

echo "🏥 Pharmacy Inventory Management System - Setup Script"
echo "=================================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

echo "✅ Prerequisites check passed!"

# Function to setup environment files
setup_env_files() {
    echo "📝 Setting up environment files..."
    
    if [ ! -f "backend/.env" ]; then
        cp backend/.env.example backend/.env
        echo "✅ Backend .env file created"
    fi
    
    if [ ! -f "frontend/.env" ]; then
        cp frontend/.env.example frontend/.env
        echo "✅ Frontend .env file created"
    fi
}

# Function to install dependencies
install_dependencies() {
    echo "📦 Installing dependencies..."
    
    echo "  🔧 Installing backend dependencies..."
    cd backend && npm install && cd ..
    
    echo "  🎨 Installing frontend dependencies..."
    cd frontend && npm install && cd ..
    
    echo "✅ Dependencies installed successfully!"
}

# Function to start services
start_services() {
    echo "🚀 Starting services with Docker Compose..."
    docker-compose up -d
    
    echo "⏳ Waiting for services to be ready..."
    sleep 10
    
    # Check if services are running
    if docker-compose ps | grep -q "Up"; then
        echo "✅ Services started successfully!"
        echo ""
        echo "🌐 Application URLs:"
        echo "   Frontend:        http://localhost:3000"
        echo "   Backend API:     http://localhost:4000"
        echo "   GraphQL:         http://localhost:4000/graphql"
        echo "   MongoDB Admin:   http://localhost:8081 (admin/admin123)"
        echo ""
        echo "📝 To view logs: docker-compose logs -f"
        echo "🛑 To stop: docker-compose down"
    else
        echo "❌ Some services failed to start. Check logs with: docker-compose logs"
    fi
}

# Function to run tests
run_tests() {
    echo "🧪 Running tests..."
    
    echo "  🔧 Running backend tests..."
    cd backend && npm test && cd ..
    
    echo "  🎨 Running frontend tests..."
    cd frontend && npm test -- --watchAll=false && cd ..
    
    echo "✅ All tests passed!"
}

# Main menu
while true; do
    echo ""
    echo "What would you like to do?"
    echo "1) 🛠️  Full setup (env files + dependencies + start services)"
    echo "2) 📝 Setup environment files only"
    echo "3) 📦 Install dependencies only"
    echo "4) 🚀 Start services only"
    echo "5) 🧪 Run tests"
    echo "6) 📊 Show service status"
    echo "7) 🛑 Stop services"
    echo "8) 🧹 Clean up (stop services and remove volumes)"
    echo "9) ❌ Exit"
    echo ""
    read -p "Enter your choice (1-9): " choice

    case $choice in
        1)
            setup_env_files
            install_dependencies
            start_services
            ;;
        2)
            setup_env_files
            ;;
        3)
            install_dependencies
            ;;
        4)
            start_services
            ;;
        5)
            run_tests
            ;;
        6)
            echo "📊 Service Status:"
            docker-compose ps
            ;;
        7)
            echo "🛑 Stopping services..."
            docker-compose stop
            echo "✅ Services stopped!"
            ;;
        8)
            echo "🧹 Cleaning up..."
            docker-compose down -v
            docker system prune -f
            echo "✅ Cleanup completed!"
            ;;
        9)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please try again."
            ;;
    esac
done
