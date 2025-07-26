# 💊 Pharmacy Inventory Management System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![React](https://img.shields.io/badge/React-18+-blue.svg)](https://reactjs.org/)
[![GraphQL](https://img.shields.io/badge/GraphQL-16+-pink.svg)](https://graphql.org/)
[![MongoDB](https://img.shields.io/badge/MongoDB-6+-green.svg)](https://mongodb.com/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://docker.com/)

A modern, full-stack **DevOps-based Inventory Management System** specifically designed for pharmacies. Built with enterprise-grade architecture featuring React frontend, Node.js GraphQL backend, MongoDB database, and complete DevOps pipeline with Docker and Kubernetes.

## ✨ Features

### 🏥 Core Functionality

- **Medicine Management**: Complete CRUD operations for pharmaceutical inventory
- **Real-time Stock Tracking**: Live inventory monitoring with low-stock alerts
- **Supplier Management**: Comprehensive supplier database and relationship tracking
- **Order Management**: Full order lifecycle from creation to fulfillment
- **Advanced Search & Filtering**: Multi-criteria search across medicines and suppliers
- **Stock Analytics**: Visual dashboards with charts and insights

### 🎨 Modern UI/UX

- **Responsive Design**: Mobile-first approach with Material-UI components
- **SCSS Animations**: Smooth transitions with Framer Motion and React Spring
- **Interactive Cards**: Animated medicine cards with hover effects and status indicators
- **Dark/Light Theme**: Customizable theme support
- **Accessibility**: ARIA compliant with keyboard navigation

### 🔒 Security & Best Practices

- **Environment Variables**: All sensitive data externalized
- **JWT Authentication**: Ready for user authentication implementation
- **Input Validation**: Comprehensive data validation on both frontend and backend
- **CORS Configuration**: Secure cross-origin resource sharing
- **Error Handling**: Graceful error management throughout the application

## 🏗️ Architecture

### Tech Stack

- **Frontend**: React 18, Material-UI v5, Apollo Client, SCSS
- **Backend**: Node.js 18, Express.js, Apollo Server, GraphQL
- **Database**: MongoDB with Mongoose ODM
- **DevOps**: Docker, Kubernetes, GitHub Actions, Docker Hub
- **Animations**: Framer Motion, React Spring, AOS, Lottie

### Project Structure

```
pharmacy-inventory/
├── frontend/          # React app for pharmacy UI
├── backend/           # Node.js + GraphQL for APIs
├── k8s/               # Kubernetes YAMLs
├── .github/workflows/ # GitHub Actions CI/CD
├── docker-compose.yml # Local development setup
└── README.md
```

## Features

- **Medicine Management**: Add, edit, delete, and search medicines

1. **Backend setup**

   ```bash
   cd backend
   npm install
   npm run dev
   ```

2. **Frontend setup** (in new terminal)

   ```bash
   cd frontend
   npm install
   npm start
   ```

3. **MongoDB setup**
   - Install MongoDB locally or use MongoDB Atlas
   - Update connection string in `backend/.env`

## 🚀 Deployment

### 📦 Docker Deployment

```bash
# Build and push to Docker Hub
docker build -t yourusername/pharmacy-backend ./backend
docker build -t yourusername/pharmacy-frontend ./frontend
docker push yourusername/pharmacy-backend
docker push yourusername/pharmacy-frontend
```

### ☸️ Kubernetes Deployment

```bash
# Update image names in k8s manifests
sed -i 's|your-dockerhub-username|yourusername|g' k8s/*.yaml

# Deploy to Kubernetes
kubectl apply -f k8s/
```

### 🔄 CI/CD with GitHub Actions

- Push to `main` branch triggers automatic deployment
- Configure GitHub Secrets:
  - `DOCKER_USERNAME`
  - `DOCKER_PASSWORD`
  - `KUBE_CONFIG`

## 🔒 Security Guidelines

⚠️ **Important**: Never commit sensitive information to version control!

### Environment Variables

- Copy `.env.example` files and update with your values
- Use strong passwords and unique secrets
- Rotate credentials regularly

### Production Security

- Use HTTPS in production
- Implement proper authentication and authorization
- Use Kubernetes secrets for sensitive data
- Enable MongoDB authentication
- Configure proper CORS policies

## 📊 API Documentation

### GraphQL Endpoints

- **Medicines**: CRUD operations, stock management
- **Suppliers**: Supplier management and relationships
- **Orders**: Order creation and tracking

### Sample Queries

```graphql
# Get all medicines
query GetMedicines {
  medicines {
    id
    name
    stock
    price
    expiryDate
  }
}

# Add new medicine
mutation AddMedicine($input: MedicineInput!) {
  addMedicine(input: $input) {
    id
    name
    stock
  }
}
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [React](https://reactjs.org/) - Frontend framework
- [Node.js](https://nodejs.org/) - Backend runtime
- [GraphQL](https://graphql.org/) - API query language
- [MongoDB](https://mongodb.com/) - Database
- [Material-UI](https://mui.com/) - UI components
- [Docker](https://docker.com/) - Containerization
- [Kubernetes](https://kubernetes.io/) - Orchestration

## 📞 Support

For support, email dev@pharmacy.com or create an issue in this repository.

---

**Built with ❤️ for modern pharmacy management**

## 🚀 Quick Start

### Prerequisites

- **Node.js** 18+ ([Download](https://nodejs.org/))
- **Docker & Docker Compose** ([Download](https://docker.com/))
- **Git** ([Download](https://git-scm.com/))
- **Kubernetes** cluster (for production deployment)

### 🔧 Environment Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/Nirmalkoswatta/pharmacy-inventory.git
   cd pharmacy-inventory
   ```

2. **Set up environment variables**

   ```bash
   # Backend environment
   cp backend/.env.example backend/.env

   # Frontend environment
   cp frontend/.env.example frontend/.env

   # Update the values in both .env files with your configuration
   ```

3. **Configure Docker Compose secrets**
   ```bash
   # Create .env file in root directory
   echo "MONGO_EXPRESS_USERNAME=your_admin_username" >> .env
   echo "MONGO_EXPRESS_PASSWORD=your_secure_password" >> .env
   ```

### 🐳 Local Development with Docker Compose

1. **Start the complete stack**

   ```bash
   docker-compose up --build
   ```

2. **Access the applications**
   - 🌐 **Frontend**: [http://localhost:3000](http://localhost:3000)
   - 🚀 **Backend GraphQL**: [http://localhost:4000/graphql](http://localhost:4000/graphql)
   - 🗄️ **MongoDB Express**: [http://localhost:8081](http://localhost:8081)
   - 📊 **Database**: `mongodb://localhost:27017/pharmacy_inventory`

### 💻 Manual Development Setup

### Production Deployment (Kubernetes)

1. Apply Kubernetes manifests:
   ```bash
   kubectl apply -f k8s/
   ```
2. Access the frontend: http://localhost:30007

## Development

### Backend Development

```bash
cd backend
npm install
npm run dev
```

### Frontend Development

```bash
cd frontend
npm install
npm start
```

## CI/CD

The project uses GitHub Actions for automated builds and deployments. On every push to the main branch:

1. Docker images are built and pushed to Docker Hub
2. Kubernetes manifests can be automatically deployed (optional)

## Monitoring & Observability

- Health checks for all services
- Logging with structured output
- Ready for Prometheus/Grafana integration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License
#   p h a r m a c y - i n v e n t o r y 
 
 
