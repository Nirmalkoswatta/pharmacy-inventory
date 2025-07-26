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
    
    // Import app after database connection
    app = require('../index');
  });

  afterAll(async () => {
    // Cleanup
    await mongoose.connection.dropDatabase();
    await mongoose.connection.close();
    await mongoServer.stop();
  });

  describe('Health Check', () => {
    test('should return 200 for health check', async () => {
      // Since we're using GraphQL, we'll test a basic GraphQL query
      const response = await request(app)
        .post('/graphql')
        .send({
          query: `
            query {
              __typename
            }
          `
        });
      
      expect(response.status).toBe(200);
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
