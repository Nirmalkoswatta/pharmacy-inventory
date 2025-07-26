# Development Guide

## Prerequisites

- Node.js 18+ 
- Docker & Docker Compose
- Git
- MongoDB (optional, can use Docker)

## Getting Started

### 1. Clone the Repository
```bash
git clone <repository-url>
cd pharmacy-inventory
```

### 2. Environment Setup

#### Backend Setup
```bash
cd backend
cp .env.example .env
npm install
```

#### Frontend Setup
```bash
cd frontend
cp .env.example .env
npm install
```

### 3. Database Setup

#### Option A: Using Docker Compose (Recommended)
```bash
docker-compose up -d mongo
```

#### Option B: Local MongoDB
Install MongoDB locally and run:
```bash
mongod --dbpath /path/to/data
```

### 4. Running the Application

#### Development Mode (Local)
```bash
# Terminal 1 - Backend
cd backend
npm run dev

# Terminal 2 - Frontend
cd frontend
npm start
```

#### Using Docker Compose
```bash
docker-compose up --build
```

## Available Scripts

### Backend Scripts
- `npm start` - Start production server
- `npm run dev` - Start development server with nodemon
- `npm test` - Run tests
- `npm run lint` - Lint code

### Frontend Scripts
- `npm start` - Start development server
- `npm run build` - Build for production
- `npm test` - Run tests
- `npm run lint` - Lint code

## API Endpoints

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:4000
- **GraphQL Playground**: http://localhost:4000/graphql
- **MongoDB**: localhost:27017
- **Mongo Express**: http://localhost:8081 (admin/admin123)

## Database Schema

### Collections:
1. **medicines** - Medicine inventory
2. **suppliers** - Supplier information
3. **orders** - Purchase orders

### Sample Data
The MongoDB initialization script (`scripts/mongo-init.js`) creates sample data for testing.

## Development Workflow

### 1. Feature Development
```bash
git checkout -b feature/feature-name
# Make changes
git add .
git commit -m "feat: add feature description"
git push origin feature/feature-name
```

### 2. Testing
```bash
# Backend tests
cd backend && npm test

# Frontend tests
cd frontend && npm test
```

### 3. Building Docker Images
```bash
# Backend
docker build -t pharmacy-backend ./backend

# Frontend
docker build -t pharmacy-frontend ./frontend
```

## Debugging

### Backend Debugging
- Check logs: `docker-compose logs backend`
- MongoDB connection: Verify MONGO_URI in .env
- GraphQL queries: Use GraphQL Playground

### Frontend Debugging
- Check browser console for errors
- Verify API endpoints in Network tab
- Check environment variables

## Code Style

### Backend
- Use ESLint configuration
- Follow GraphQL best practices
- Use proper error handling

### Frontend
- Use Material-UI components
- Follow React best practices
- Use proper state management

## Common Issues

### Port Conflicts
If ports are in use:
```bash
# Check what's using the port
lsof -i :3000
lsof -i :4000

# Kill the process
kill -9 <PID>
```

### Database Connection Issues
- Ensure MongoDB is running
- Check connection string in .env
- Verify network connectivity

### Docker Issues
```bash
# Clean up Docker
docker-compose down -v
docker system prune

# Rebuild containers
docker-compose up --build
```

## Performance Optimization

### Backend
- Use database indexes
- Implement query optimization
- Add caching where appropriate

### Frontend
- Use React.memo for components
- Implement virtual scrolling for large lists
- Optimize bundle size

## Security Considerations

- Never commit .env files
- Use environment variables for secrets
- Implement proper authentication
- Validate all inputs
- Use HTTPS in production

## Monitoring

### Health Checks
- Backend: http://localhost:4000/health
- Frontend: http://localhost:3000/health (in production)

### Logs
- Application logs in console
- Database logs via mongo-express
- Docker logs via `docker-compose logs`

## Deployment

See main README.md for deployment instructions using:
- Docker Compose (local/staging)
- Kubernetes (production)
- CI/CD pipeline via GitHub Actions
