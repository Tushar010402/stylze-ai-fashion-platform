const axios = require('axios');
const { expect } = require('chai');

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000';
const TEST_USER = {
  email: 'test@stylze.ai',
  password: 'Test123!@#',
  username: 'testuser',
  firstName: 'Test',
  lastName: 'User'
};

let authToken;
let userId;

describe('Stylze API Integration Tests', () => {
  
  describe('Authentication Flow', () => {
    
    it('should register a new user', async () => {
      const response = await axios.post(`${API_BASE_URL}/api/v1/auth/register`, TEST_USER);
      
      expect(response.status).to.equal(201);
      expect(response.data).to.have.property('user');
      expect(response.data).to.have.property('token');
      expect(response.data.user.email).to.equal(TEST_USER.email);
      
      authToken = response.data.token;
      userId = response.data.user.id;
    });
    
    it('should login with credentials', async () => {
      const response = await axios.post(`${API_BASE_URL}/api/v1/auth/login`, {
        email: TEST_USER.email,
        password: TEST_USER.password
      });
      
      expect(response.status).to.equal(200);
      expect(response.data).to.have.property('token');
      expect(response.data).to.have.property('refreshToken');
    });
    
    it('should refresh access token', async () => {
      const loginResponse = await axios.post(`${API_BASE_URL}/api/v1/auth/login`, {
        email: TEST_USER.email,
        password: TEST_USER.password
      });
      
      const response = await axios.post(`${API_BASE_URL}/api/v1/auth/refresh`, {
        refreshToken: loginResponse.data.refreshToken
      });
      
      expect(response.status).to.equal(200);
      expect(response.data).to.have.property('token');
    });
  });
  
  describe('User Profile', () => {
    
    it('should get user profile', async () => {
      const response = await axios.get(`${API_BASE_URL}/api/v1/users/profile`, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      expect(response.status).to.equal(200);
      expect(response.data).to.have.property('id');
      expect(response.data.email).to.equal(TEST_USER.email);
    });
    
    it('should update user profile', async () => {
      const updates = {
        firstName: 'Updated',
        lastName: 'Name',
        preferredStyles: ['casual', 'business'],
        height: 175,
        weight: 70
      };
      
      const response = await axios.put(`${API_BASE_URL}/api/v1/users/profile`, updates, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      expect(response.status).to.equal(200);
      expect(response.data.firstName).to.equal(updates.firstName);
      expect(response.data.preferredStyles).to.deep.equal(updates.preferredStyles);
    });
  });
  
  describe('Wardrobe Management', () => {
    let itemId;
    
    it('should add item to wardrobe', async () => {
      const item = {
        name: 'Blue Shirt',
        category: 'TOP',
        color: ['blue'],
        size: 'M',
        brand: 'Test Brand',
        imageUrl: 'https://example.com/shirt.jpg'
      };
      
      const response = await axios.post(`${API_BASE_URL}/api/v1/wardrobe/items`, item, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      expect(response.status).to.equal(201);
      expect(response.data).to.have.property('id');
      expect(response.data.name).to.equal(item.name);
      
      itemId = response.data.id;
    });
    
    it('should get wardrobe items', async () => {
      const response = await axios.get(`${API_BASE_URL}/api/v1/wardrobe/items`, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      expect(response.status).to.equal(200);
      expect(response.data).to.be.an('array');
      expect(response.data.length).to.be.greaterThan(0);
    });
    
    it('should delete wardrobe item', async () => {
      const response = await axios.delete(`${API_BASE_URL}/api/v1/wardrobe/items/${itemId}`, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      expect(response.status).to.equal(204);
    });
  });
  
  describe('Avatar Service', () => {
    
    it('should create avatar from image', async () => {
      const avatarData = {
        imageUrl: 'https://example.com/user-photo.jpg',
        generateMesh: true
      };
      
      const response = await axios.post(`${API_BASE_URL}/api/v1/avatar/create`, avatarData, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      expect(response.status).to.equal(201);
      expect(response.data).to.have.property('avatarUrl');
      expect(response.data).to.have.property('meshData');
    });
    
    it('should perform virtual try-on', async () => {
      const tryOnData = {
        avatarId: 'test-avatar-id',
        clothingItemId: 'test-item-id',
        renderQuality: 'high'
      };
      
      const response = await axios.post(`${API_BASE_URL}/api/v1/avatar/try-on`, tryOnData, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      expect(response.status).to.equal(200);
      expect(response.data).to.have.property('renderUrl');
      expect(response.data).to.have.property('processingTime');
    });
  });
  
  describe('Recommendation Service', () => {
    
    it('should get daily outfit recommendations', async () => {
      const response = await axios.post(
        `${API_BASE_URL}/api/v1/recommendations/graphql`,
        {
          query: `
            query GetDailyOutfits($date: String!, $weather: WeatherInput) {
              getDailyOutfits(date: $date, weather: $weather) {
                id
                items {
                  id
                  name
                  category
                }
                occasion
                confidence
              }
            }
          `,
          variables: {
            date: new Date().toISOString(),
            weather: {
              temperature: 22,
              condition: 'sunny'
            }
          }
        },
        {
          headers: { Authorization: `Bearer ${authToken}` }
        }
      );
      
      expect(response.status).to.equal(200);
      expect(response.data.data).to.have.property('getDailyOutfits');
      expect(response.data.data.getDailyOutfits).to.be.an('array');
    });
    
    it('should generate outfit based on event', async () => {
      const response = await axios.post(
        `${API_BASE_URL}/api/v1/recommendations/graphql`,
        {
          query: `
            mutation GenerateOutfit($input: GenerateOutfitInput!) {
              generateOutfit(input: $input) {
                id
                items {
                  id
                  name
                }
                occasion
                confidence
              }
            }
          `,
          variables: {
            input: {
              occasion: 'business_meeting',
              preferences: {
                colorScheme: 'neutral',
                style: 'formal'
              }
            }
          }
        },
        {
          headers: { Authorization: `Bearer ${authToken}` }
        }
      );
      
      expect(response.status).to.equal(200);
      expect(response.data.data).to.have.property('generateOutfit');
      expect(response.data.data.generateOutfit.occasion).to.equal('business_meeting');
    });
  });
  
  describe('Health Checks', () => {
    
    it('should return healthy status for all services', async () => {
      const services = [
        '/health',
        '/api/v1/users/health',
        '/api/v1/wardrobe/health',
        '/api/v1/avatar/health',
        '/api/v1/recommendations/health'
      ];
      
      for (const endpoint of services) {
        const response = await axios.get(`${API_BASE_URL}${endpoint}`);
        expect(response.status).to.equal(200);
        expect(response.data).to.have.property('status');
        expect(response.data.status).to.equal('healthy');
      }
    });
  });
  
  describe('Error Handling', () => {
    
    it('should return 401 for unauthorized requests', async () => {
      try {
        await axios.get(`${API_BASE_URL}/api/v1/users/profile`);
      } catch (error) {
        expect(error.response.status).to.equal(401);
        expect(error.response.data).to.have.property('error');
      }
    });
    
    it('should return 404 for non-existent resources', async () => {
      try {
        await axios.get(`${API_BASE_URL}/api/v1/wardrobe/items/non-existent-id`, {
          headers: { Authorization: `Bearer ${authToken}` }
        });
      } catch (error) {
        expect(error.response.status).to.equal(404);
        expect(error.response.data).to.have.property('error');
      }
    });
    
    it('should return 400 for invalid input', async () => {
      try {
        await axios.post(`${API_BASE_URL}/api/v1/wardrobe/items`, {
          // Missing required fields
          name: 'Invalid Item'
        }, {
          headers: { Authorization: `Bearer ${authToken}` }
        });
      } catch (error) {
        expect(error.response.status).to.equal(400);
        expect(error.response.data).to.have.property('error');
      }
    });
  });
  
  describe('Cleanup', () => {
    
    it('should delete test user', async () => {
      const response = await axios.delete(`${API_BASE_URL}/api/v1/users/profile`, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      expect(response.status).to.equal(204);
    });
  });
});

// Performance Tests
describe('Performance Tests', () => {
  
  it('should handle concurrent requests', async () => {
    const concurrentRequests = 10;
    const promises = [];
    
    for (let i = 0; i < concurrentRequests; i++) {
      promises.push(axios.get(`${API_BASE_URL}/health`));
    }
    
    const responses = await Promise.all(promises);
    responses.forEach(response => {
      expect(response.status).to.equal(200);
    });
  });
  
  it('should respond within acceptable time', async () => {
    const start = Date.now();
    await axios.get(`${API_BASE_URL}/health`);
    const responseTime = Date.now() - start;
    
    expect(responseTime).to.be.lessThan(1000); // Less than 1 second
  });
});