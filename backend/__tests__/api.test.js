const request = require('supertest');
const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');

describe('Backend API Tests', () => {
  let mongoServer;
  let app;

  beforeAll(async () => {
    // Start in-memory MongoDB instance
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    
    // Connect to the in-memory database
    await mongoose.connect(mongoUri);
    
    // Import and create app after database connection
    const createApp = require('../index');
    app = await createApp();
  }, 60000); // 60 second timeout

  afterAll(async () => {
    try {
      if (mongoose.connection.readyState !== 0) {
        await mongoose.connection.dropDatabase();
        await mongoose.connection.close();
      }
      if (mongoServer) await mongoServer.stop();
      console.log('Cleanup complete');
    } catch (err) {
      console.error('Error during afterAll cleanup:', err);
    }
  }, 60000); // 60 second timeout

  describe('Health Check', () => {
    test('should return 200 for health check', async () => {
      const response = await request(app)
        .get('/health');
      
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('OK');
      expect(response.body.service).toBe('pharmacy-inventory-backend');
    });
  });

  describe('GraphQL Endpoint', () => {
    test('should respond to basic GraphQL introspection query', async () => {
      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            query {
              __schema {
                types {
                  name
                }
              }
            }
          `
        });
      
      expect(response.status).toBe(200);
      expect(response.body.data).toBeDefined();
      expect(response.body.data.__schema).toBeDefined();
    });
  });

  describe('Medicine Queries', () => {
    test('should fetch medicines successfully', async () => {
      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            query {
              medicines {
                id
                name
              }
            }
          `
        });
      
      expect(response.status).toBe(200);
      expect(response.body.data).toBeDefined();
      expect(response.body.data.medicines).toBeDefined();
    });
  });

  describe('Supplier Queries', () => {
    test('should fetch suppliers successfully', async () => {
      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            query {
              suppliers {
                id
                name
              }
            }
          `
        });
      
      expect(response.status).toBe(200);
      expect(response.body.data).toBeDefined();
      expect(response.body.data.suppliers).toBeDefined();
    });
  });
});
