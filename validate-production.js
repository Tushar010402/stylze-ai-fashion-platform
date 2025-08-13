#!/usr/bin/env node

const axios = require('axios');
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);
const fs = require('fs').promises;
const path = require('path');

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

class ProductionValidator {
  constructor() {
    this.results = {
      services: [],
      database: false,
      redis: false,
      apis: [],
      configuration: [],
      security: [],
      overall: 0
    };
  }

  log(message, color = 'reset') {
    console.log(`${colors[color]}${message}${colors.reset}`);
  }

  async checkService(name, port, endpoint = '/health') {
    try {
      const response = await axios.get(`http://localhost:${port}${endpoint}`, {
        timeout: 5000
      });
      
      if (response.status === 200) {
        this.log(`✅ ${name} service: HEALTHY (port ${port})`, 'green');
        return { name, status: 'healthy', port };
      }
    } catch (error) {
      this.log(`❌ ${name} service: NOT RUNNING (port ${port})`, 'red');
      return { name, status: 'down', port, error: error.message };
    }
  }

  async checkAllServices() {
    this.log('\n📡 CHECKING SERVICES...', 'cyan');
    
    const services = [
      { name: 'User Service', port: 3001 },
      { name: 'Wardrobe Service', port: 3002 },
      { name: 'Avatar Service', port: 3003 },
      { name: 'Recommendation Service', port: 3004 },
      { name: 'Notification Service', port: 3005 },
      { name: 'AI Service', port: 8000 },
      { name: 'API Gateway', port: 3010 }
    ];

    for (const service of services) {
      const result = await this.checkService(service.name, service.port);
      this.results.services.push(result);
    }
  }

  async checkDatabase() {
    this.log('\n💾 CHECKING DATABASE...', 'cyan');
    
    try {
      const { stdout } = await execAsync(
        'PGPASSWORD=stylze_secure_password_2025 docker exec stylze-postgres psql -U stylze_user -d stylze_db -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = \'public\';" 2>&1'
      );
      
      if (stdout.includes('count')) {
        this.log('✅ PostgreSQL: CONNECTED & INITIALIZED', 'green');
        this.results.database = true;
        
        // Check tables
        const { stdout: tables } = await execAsync(
          'PGPASSWORD=stylze_secure_password_2025 docker exec stylze-postgres psql -U stylze_user -d stylze_db -c "\\dt" 2>&1'
        );
        
        const tableCount = (tables.match(/\d+ rows?\)/)?.[0] || '0 rows').replace(' rows)', '');
        this.log(`   Tables found: ${tableCount}`, 'green');
      }
    } catch (error) {
      this.log('❌ PostgreSQL: NOT CONNECTED', 'red');
      this.log(`   Error: ${error.message}`, 'yellow');
      this.results.database = false;
    }
  }

  async checkRedis() {
    this.log('\n🗄️  CHECKING REDIS...', 'cyan');
    
    try {
      const { stdout } = await execAsync('docker exec stylze-redis redis-cli ping');
      
      if (stdout.trim() === 'PONG') {
        this.log('✅ Redis: CONNECTED', 'green');
        this.results.redis = true;
      }
    } catch (error) {
      this.log('❌ Redis: NOT CONNECTED', 'red');
      this.results.redis = false;
    }
  }

  async checkAPIs() {
    this.log('\n🔑 CHECKING API INTEGRATIONS...', 'cyan');
    
    // Check environment variables
    const envPath = path.join(__dirname, '.env.production');
    
    try {
      const envContent = await fs.readFile(envPath, 'utf-8');
      
      // Check Gemini API key
      if (envContent.includes('GEMINI_API_KEY=AIza')) {
        this.log('✅ Gemini API Key: CONFIGURED', 'green');
        this.results.apis.push({ name: 'Gemini', status: 'configured' });
      } else {
        this.log('❌ Gemini API Key: NOT CONFIGURED', 'red');
        this.results.apis.push({ name: 'Gemini', status: 'missing' });
      }
      
      // Check Google Cloud credentials
      if (envContent.includes('GOOGLE_APPLICATION_CREDENTIALS=')) {
        const credPath = envContent.match(/GOOGLE_APPLICATION_CREDENTIALS=([^\n]+)/)?.[1];
        if (credPath && await fs.access(credPath).then(() => true).catch(() => false)) {
          this.log('✅ Google Cloud Credentials: CONFIGURED', 'green');
          this.results.apis.push({ name: 'GCP', status: 'configured' });
        } else {
          this.log('⚠️  Google Cloud Credentials: PATH SET BUT FILE NOT FOUND', 'yellow');
          this.results.apis.push({ name: 'GCP', status: 'partial' });
        }
      }
    } catch (error) {
      this.log('❌ Environment file not found', 'red');
    }
  }

  async checkConfiguration() {
    this.log('\n⚙️  CHECKING CONFIGURATION...', 'cyan');
    
    // Check mock flags
    const configPath = path.join(__dirname, 'ai-styling-backend/services/wardrobe-service/app/config.py');
    
    try {
      const configContent = await fs.readFile(configPath, 'utf-8');
      
      if (configContent.includes('USE_MOCK_VISION_API: bool = False')) {
        this.log('✅ Mock Vision API: DISABLED', 'green');
        this.results.configuration.push({ name: 'Mock Vision', status: 'disabled' });
      } else {
        this.log('❌ Mock Vision API: STILL ENABLED', 'red');
        this.results.configuration.push({ name: 'Mock Vision', status: 'enabled' });
      }
      
      if (configContent.includes('DEBUG: bool = False')) {
        this.log('✅ Debug Mode: DISABLED', 'green');
        this.results.configuration.push({ name: 'Debug', status: 'disabled' });
      } else {
        this.log('⚠️  Debug Mode: STILL ENABLED', 'yellow');
        this.results.configuration.push({ name: 'Debug', status: 'enabled' });
      }
      
      if (configContent.includes('USE_LOCAL_STORAGE: bool = False')) {
        this.log('✅ Cloud Storage: ENABLED', 'green');
        this.results.configuration.push({ name: 'Cloud Storage', status: 'enabled' });
      } else {
        this.log('⚠️  Local Storage: STILL IN USE', 'yellow');
        this.results.configuration.push({ name: 'Cloud Storage', status: 'disabled' });
      }
    } catch (error) {
      this.log('❌ Configuration file not found', 'red');
    }
  }

  async checkSecurity() {
    this.log('\n🔐 CHECKING SECURITY...', 'cyan');
    
    // Check for HTTPS
    this.log('⚠️  HTTPS: NOT CONFIGURED (local development)', 'yellow');
    this.results.security.push({ name: 'HTTPS', status: 'not configured' });
    
    // Check JWT secret
    const envPath = path.join(__dirname, '.env.production');
    try {
      const envContent = await fs.readFile(envPath, 'utf-8');
      if (envContent.includes('JWT_SECRET=') && !envContent.includes('JWT_SECRET=dev')) {
        this.log('✅ JWT Secret: PRODUCTION KEY SET', 'green');
        this.results.security.push({ name: 'JWT', status: 'secure' });
      } else {
        this.log('❌ JWT Secret: USING DEFAULT KEY', 'red');
        this.results.security.push({ name: 'JWT', status: 'insecure' });
      }
    } catch (error) {
      this.log('❌ Security configuration not found', 'red');
    }
  }

  calculateReadiness() {
    let score = 0;
    let total = 0;
    
    // Services (35% weight)
    const healthyServices = this.results.services.filter(s => s.status === 'healthy').length;
    score += (healthyServices / this.results.services.length) * 35;
    total += 35;
    
    // Database (15% weight)
    if (this.results.database) score += 15;
    total += 15;
    
    // Redis (10% weight)
    if (this.results.redis) score += 10;
    total += 10;
    
    // APIs (20% weight)
    const configuredAPIs = this.results.apis.filter(a => a.status === 'configured').length;
    if (this.results.apis.length > 0) {
      score += (configuredAPIs / this.results.apis.length) * 20;
    }
    total += 20;
    
    // Configuration (15% weight)
    const correctConfig = this.results.configuration.filter(c => 
      c.name === 'Mock Vision' ? c.status === 'disabled' : 
      c.name === 'Debug' ? c.status === 'disabled' :
      c.status === 'enabled'
    ).length;
    if (this.results.configuration.length > 0) {
      score += (correctConfig / this.results.configuration.length) * 15;
    }
    total += 15;
    
    // Security (5% weight)
    const secureItems = this.results.security.filter(s => s.status === 'secure' || s.status === 'configured').length;
    if (this.results.security.length > 0) {
      score += (secureItems / this.results.security.length) * 5;
    }
    total += 5;
    
    this.results.overall = Math.round(score);
    return this.results.overall;
  }

  async validate() {
    this.log('🏭 STYLZE PRODUCTION VALIDATION', 'cyan');
    this.log('================================', 'cyan');
    
    await this.checkAllServices();
    await this.checkDatabase();
    await this.checkRedis();
    await this.checkAPIs();
    await this.checkConfiguration();
    await this.checkSecurity();
    
    const readiness = this.calculateReadiness();
    
    this.log('\n📊 PRODUCTION READINESS SCORE', 'cyan');
    this.log('================================', 'cyan');
    
    if (readiness >= 90) {
      this.log(`🎉 ${readiness}% - PRODUCTION READY!`, 'green');
    } else if (readiness >= 70) {
      this.log(`⚠️  ${readiness}% - ALMOST READY (minor fixes needed)`, 'yellow');
    } else if (readiness >= 50) {
      this.log(`🔧 ${readiness}% - SIGNIFICANT WORK NEEDED`, 'yellow');
    } else {
      this.log(`❌ ${readiness}% - NOT READY FOR PRODUCTION`, 'red');
    }
    
    // Summary
    this.log('\n📝 SUMMARY', 'cyan');
    this.log('----------', 'cyan');
    this.log(`Services Running: ${this.results.services.filter(s => s.status === 'healthy').length}/${this.results.services.length}`, 
      this.results.services.filter(s => s.status === 'healthy').length === this.results.services.length ? 'green' : 'yellow');
    this.log(`Database: ${this.results.database ? 'Connected' : 'Not Connected'}`, 
      this.results.database ? 'green' : 'red');
    this.log(`Redis: ${this.results.redis ? 'Connected' : 'Not Connected'}`, 
      this.results.redis ? 'green' : 'red');
    this.log(`APIs Configured: ${this.results.apis.filter(a => a.status === 'configured').length}/${this.results.apis.length}`,
      this.results.apis.every(a => a.status === 'configured') ? 'green' : 'yellow');
    this.log(`Production Config: ${this.results.configuration.filter(c => c.status === 'disabled' || c.status === 'enabled').length}/${this.results.configuration.length}`,
      'yellow');
    
    return readiness;
  }
}

// Run validation
if (require.main === module) {
  const validator = new ProductionValidator();
  validator.validate().then(readiness => {
    process.exit(readiness >= 70 ? 0 : 1);
  }).catch(error => {
    console.error('Validation failed:', error);
    process.exit(1);
  });
}

module.exports = ProductionValidator;