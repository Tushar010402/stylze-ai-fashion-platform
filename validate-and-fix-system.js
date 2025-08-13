#!/usr/bin/env node
/**
 * Industrial Grade System Validator and Fixer
 * This script validates the actual state of the system and attempts to fix critical issues
 */

const axios = require('axios');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

class SystemValidator {
  constructor() {
    this.issues = [];
    this.fixes = [];
    this.services = {
      user: { port: 3001, health: '/health' },
      wardrobe: { port: 3002, health: '/health' },
      avatar: { port: 3003, health: '/health' },
      recommendation: { port: 3004, health: '/health' },
      notification: { port: 3005, health: '/health' },
      ai: { port: 8000, health: '/health' },
      gateway: { port: 3010, health: '/health' }
    };
  }

  log(level, message) {
    const icons = {
      success: colors.green + '✅',
      error: colors.red + '❌',
      warning: colors.yellow + '⚠️',
      info: colors.blue + 'ℹ️',
      fixing: colors.cyan + '🔧'
    };
    console.log(`${icons[level]} ${colors.reset}${message}`);
  }

  async validateAll() {
    console.log(`\n${colors.cyan}🏭 INDUSTRIAL GRADE SYSTEM VALIDATION${colors.reset}`);
    console.log('=' .repeat(60));

    await this.validateServices();
    await this.validateDatabase();
    await this.validateConfiguration();
    await this.validateAPIs();
    await this.validateSecurity();
    await this.validateMonitoring();
    await this.validateTesting();
    
    this.generateReport();
    await this.attemptFixes();
  }

  async validateServices() {
    console.log(`\n${colors.blue}1. SERVICE HEALTH CHECKS${colors.reset}`);
    
    for (const [name, config] of Object.entries(this.services)) {
      try {
        const response = await axios.get(`http://localhost:${config.port}${config.health}`, 
          { timeout: 2000 });
        
        if (response.data.status === 'healthy') {
          this.log('success', `${name} service: HEALTHY`);
        } else {
          this.log('warning', `${name} service: DEGRADED`);
          this.issues.push({ type: 'service', name, issue: 'degraded' });
        }
      } catch (error) {
        this.log('error', `${name} service: NOT RUNNING`);
        this.issues.push({ type: 'service', name, issue: 'not_running', port: config.port });
      }
    }
  }

  async validateDatabase() {
    console.log(`\n${colors.blue}2. DATABASE VALIDATION${colors.reset}`);
    
    try {
      // Check PostgreSQL connection
      const { stdout } = await execPromise('docker exec stylze-postgres psql -U postgres -c "SELECT 1;" 2>&1');
      this.log('success', 'PostgreSQL container: RUNNING');
      
      // Check if stylze_user exists
      try {
        await execPromise('docker exec stylze-postgres psql -U stylze_user -d stylze_db -c "SELECT 1;" 2>&1');
        this.log('success', 'Database user and database: CONFIGURED');
      } catch (error) {
        this.log('error', 'Database user "stylze_user" does not exist');
        this.issues.push({ type: 'database', issue: 'missing_user' });
      }
      
    } catch (error) {
      this.log('error', 'PostgreSQL container: NOT RUNNING');
      this.issues.push({ type: 'database', issue: 'not_running' });
    }

    // Check Redis
    try {
      await execPromise('docker exec stylze-redis redis-cli ping');
      this.log('success', 'Redis: RUNNING');
    } catch (error) {
      this.log('error', 'Redis: NOT RUNNING');
      this.issues.push({ type: 'cache', issue: 'redis_not_running' });
    }
  }

  async validateConfiguration() {
    console.log(`\n${colors.blue}3. CONFIGURATION VALIDATION${colors.reset}`);
    
    // Check for mock flags
    const configFiles = [
      'ai-styling-backend/services/wardrobe-service/app/config.py',
      'ai-styling-backend/services/user-service/.env',
      'ai-styling-ai/.env'
    ];

    for (const file of configFiles) {
      if (fs.existsSync(file)) {
        const content = fs.readFileSync(file, 'utf8');
        
        if (content.includes('USE_MOCK') && content.includes('True')) {
          this.log('error', `Mock mode enabled in ${path.basename(file)}`);
          this.issues.push({ type: 'config', file, issue: 'mock_enabled' });
        }
        
        if (content.includes('DEBUG') && content.includes('True')) {
          this.log('warning', `Debug mode enabled in ${path.basename(file)}`);
          this.issues.push({ type: 'config', file, issue: 'debug_enabled' });
        }
      }
    }

    // Check for API keys
    const requiredEnvVars = [
      'GEMINI_API_KEY',
      'VISION_API_KEY',
      'JWT_SECRET',
      'DATABASE_URL'
    ];

    const missingVars = requiredEnvVars.filter(v => !process.env[v]);
    if (missingVars.length > 0) {
      this.log('error', `Missing environment variables: ${missingVars.join(', ')}`);
      this.issues.push({ type: 'config', issue: 'missing_env_vars', vars: missingVars });
    }
  }

  async validateAPIs() {
    console.log(`\n${colors.blue}4. API ENDPOINT VALIDATION${colors.reset}`);
    
    const testEndpoints = [
      { service: 'user', path: '/api/v1/auth/login', method: 'POST', 
        data: { email: 'test@test.com', password: 'test123' } },
      { service: 'wardrobe', path: '/api/v1/wardrobe/items', method: 'GET' },
      { service: 'avatar', path: '/api/v1/avatar/create', method: 'POST',
        data: { userId: 'test', measurements: { height: 170 } } },
      { service: 'ai', path: '/api/v1/analyze/body', method: 'POST',
        data: { user_id: 'test', image_data: 'mock' } }
    ];

    for (const endpoint of testEndpoints) {
      const port = this.services[endpoint.service]?.port;
      if (!port) continue;

      try {
        const config = {
          method: endpoint.method,
          url: `http://localhost:${port}${endpoint.path}`,
          data: endpoint.data,
          timeout: 2000
        };
        
        const response = await axios(config);
        
        // Check if response is mock data
        const responseStr = JSON.stringify(response.data);
        if (responseStr.includes('mock') || responseStr.includes('test_') || responseStr.includes('fake')) {
          this.log('warning', `${endpoint.service}${endpoint.path}: RETURNS MOCK DATA`);
          this.issues.push({ type: 'api', endpoint: endpoint.path, issue: 'mock_response' });
        } else {
          this.log('success', `${endpoint.service}${endpoint.path}: REAL DATA`);
        }
      } catch (error) {
        if (error.response?.status === 401) {
          this.log('info', `${endpoint.service}${endpoint.path}: Requires authentication`);
        } else {
          this.log('error', `${endpoint.service}${endpoint.path}: FAILED`);
          this.issues.push({ type: 'api', endpoint: endpoint.path, issue: 'endpoint_error' });
        }
      }
    }
  }

  async validateSecurity() {
    console.log(`\n${colors.blue}5. SECURITY VALIDATION${colors.reset}`);
    
    // Check for hardcoded secrets
    const secretPatterns = [
      /JWT_SECRET\s*=\s*["'][\w\-]+["']/,
      /password\s*=\s*["']\w+["']/i,
      /api[_\-]?key\s*=\s*["'][\w\-]+["']/i
    ];

    const sourceFiles = [
      'ai-styling-backend/services/user-service/production-server.js',
      'ai-styling-backend/services/wardrobe-service/app/config.py'
    ];

    for (const file of sourceFiles) {
      if (fs.existsSync(file)) {
        const content = fs.readFileSync(file, 'utf8');
        for (const pattern of secretPatterns) {
          if (pattern.test(content)) {
            this.log('error', `Hardcoded secrets found in ${path.basename(file)}`);
            this.issues.push({ type: 'security', file, issue: 'hardcoded_secrets' });
            break;
          }
        }
      }
    }

    // Check HTTPS
    try {
      await axios.get('https://localhost:3001/health', { timeout: 1000 });
      this.log('success', 'HTTPS: ENABLED');
    } catch (error) {
      this.log('error', 'HTTPS: NOT CONFIGURED');
      this.issues.push({ type: 'security', issue: 'no_https' });
    }

    // Check rate limiting
    const rateLimitTest = await this.testRateLimit();
    if (!rateLimitTest) {
      this.log('error', 'Rate limiting: NOT IMPLEMENTED');
      this.issues.push({ type: 'security', issue: 'no_rate_limiting' });
    }
  }

  async validateMonitoring() {
    console.log(`\n${colors.blue}6. MONITORING & OBSERVABILITY${colors.reset}`);
    
    // Check Prometheus
    try {
      const response = await axios.get('http://localhost:9090/api/v1/targets');
      const activeTargets = response.data.data.activeTargets || [];
      if (activeTargets.length > 0) {
        this.log('success', `Prometheus: ${activeTargets.length} active targets`);
      } else {
        this.log('warning', 'Prometheus: No active targets');
        this.issues.push({ type: 'monitoring', issue: 'no_metrics' });
      }
    } catch (error) {
      this.log('error', 'Prometheus: NOT RUNNING');
      this.issues.push({ type: 'monitoring', issue: 'prometheus_not_running' });
    }

    // Check Grafana
    try {
      await axios.get('http://localhost:3007/api/health');
      this.log('success', 'Grafana: RUNNING');
    } catch (error) {
      this.log('error', 'Grafana: NOT RUNNING');
      this.issues.push({ type: 'monitoring', issue: 'grafana_not_running' });
    }

    // Check logging
    const logFiles = [
      'ai-styling-backend/services/api-gateway/logs/combined.log',
      'ai-styling-backend/services/avatar-service/combined.log'
    ];

    let loggingActive = false;
    for (const logFile of logFiles) {
      if (fs.existsSync(logFile)) {
        const stats = fs.statSync(logFile);
        if (stats.size > 0) {
          loggingActive = true;
          break;
        }
      }
    }

    if (loggingActive) {
      this.log('success', 'Logging: ACTIVE');
    } else {
      this.log('error', 'Logging: NOT CONFIGURED');
      this.issues.push({ type: 'monitoring', issue: 'no_logging' });
    }
  }

  async validateTesting() {
    console.log(`\n${colors.blue}7. TESTING VALIDATION${colors.reset}`);
    
    // Check for test files
    const testDirs = [
      'ai-styling-backend/services/user-service/tests',
      'ai-styling-backend/services/avatar-service/tests',
      'ai-styling-app/tests'
    ];

    let totalTests = 0;
    for (const dir of testDirs) {
      if (fs.existsSync(dir)) {
        const files = fs.readdirSync(dir);
        const testFiles = files.filter(f => f.includes('.test.') || f.includes('.spec.'));
        totalTests += testFiles.length;
      }
    }

    if (totalTests > 10) {
      this.log('success', `Test coverage: ${totalTests} test files found`);
    } else {
      this.log('error', `Test coverage: Only ${totalTests} test files found`);
      this.issues.push({ type: 'testing', issue: 'low_coverage' });
    }

    // Check CI/CD
    if (fs.existsSync('.github/workflows')) {
      const workflows = fs.readdirSync('.github/workflows');
      if (workflows.length > 0) {
        this.log('success', `CI/CD: ${workflows.length} workflows configured`);
      } else {
        this.log('error', 'CI/CD: No workflows configured');
        this.issues.push({ type: 'testing', issue: 'no_cicd' });
      }
    } else {
      this.log('error', 'CI/CD: No GitHub Actions configured');
      this.issues.push({ type: 'testing', issue: 'no_cicd' });
    }
  }

  async testRateLimit() {
    // Send 10 rapid requests to test rate limiting
    const promises = [];
    for (let i = 0; i < 10; i++) {
      promises.push(
        axios.get('http://localhost:3001/health', { timeout: 1000 })
          .catch(e => e.response?.status)
      );
    }
    
    const results = await Promise.all(promises);
    return results.some(r => r === 429); // 429 = Too Many Requests
  }

  generateReport() {
    console.log(`\n${colors.cyan}📊 VALIDATION SUMMARY${colors.reset}`);
    console.log('=' .repeat(60));

    const categories = {
      service: 'Service Issues',
      database: 'Database Issues',
      config: 'Configuration Issues',
      api: 'API Issues',
      security: 'Security Issues',
      monitoring: 'Monitoring Issues',
      testing: 'Testing Issues'
    };

    for (const [type, title] of Object.entries(categories)) {
      const categoryIssues = this.issues.filter(i => i.type === type);
      if (categoryIssues.length > 0) {
        console.log(`\n${colors.yellow}${title}: ${categoryIssues.length}${colors.reset}`);
        categoryIssues.forEach(issue => {
          console.log(`  - ${JSON.stringify(issue)}`);
        });
      }
    }

    const totalIssues = this.issues.length;
    const criticalIssues = this.issues.filter(i => 
      i.type === 'security' || i.type === 'database' || i.issue === 'not_running'
    ).length;

    console.log(`\n${colors.red}Total Issues: ${totalIssues}${colors.reset}`);
    console.log(`${colors.red}Critical Issues: ${criticalIssues}${colors.reset}`);

    // Calculate readiness score
    const maxScore = 100;
    const deduction = totalIssues * 5 + criticalIssues * 10;
    const score = Math.max(0, maxScore - deduction);

    console.log(`\n${colors.cyan}🏭 INDUSTRIAL GRADE READINESS: ${score}%${colors.reset}`);
    
    if (score >= 90) {
      console.log(`${colors.green}✅ PRODUCTION READY${colors.reset}`);
    } else if (score >= 70) {
      console.log(`${colors.yellow}⚠️ NEAR PRODUCTION READY (Minor fixes needed)${colors.reset}`);
    } else {
      console.log(`${colors.red}❌ NOT PRODUCTION READY (Major work required)${colors.reset}`);
    }
  }

  async attemptFixes() {
    if (this.issues.length === 0) return;

    console.log(`\n${colors.cyan}🔧 ATTEMPTING AUTOMATIC FIXES${colors.reset}`);
    console.log('=' .repeat(60));

    // Fix database issues
    const dbIssue = this.issues.find(i => i.type === 'database' && i.issue === 'missing_user');
    if (dbIssue) {
      this.log('fixing', 'Creating database user and database...');
      try {
        await execPromise(`docker exec stylze-postgres psql -U postgres -c "CREATE USER stylze_user WITH PASSWORD 'stylze_secure_password_2025';"`);
        await execPromise(`docker exec stylze-postgres psql -U postgres -c "CREATE DATABASE stylze_db OWNER stylze_user;"`);
        this.log('success', 'Database user and database created');
        this.fixes.push('database_setup');
      } catch (error) {
        this.log('error', 'Failed to create database user');
      }
    }

    // Fix mock configuration
    const mockIssue = this.issues.find(i => i.type === 'config' && i.issue === 'mock_enabled');
    if (mockIssue) {
      this.log('fixing', 'Creating production configuration...');
      const prodConfig = `
# Production Configuration
USE_MOCK_VISION_API=false
USE_LOCAL_STORAGE=false
DEBUG=false
NODE_ENV=production
JWT_SECRET=${this.generateSecret()}
DATABASE_URL=postgresql://stylze_user:stylze_secure_password_2025@localhost:5432/stylze_db
REDIS_URL=redis://localhost:6379
`;
      fs.writeFileSync('.env.production', prodConfig);
      this.log('success', 'Production configuration created (.env.production)');
      this.fixes.push('production_config');
    }

    // Start missing services
    const missingServices = this.issues.filter(i => i.type === 'service' && i.issue === 'not_running');
    for (const service of missingServices) {
      this.log('fixing', `Starting ${service.name} service...`);
      // Command to start service would go here
      this.log('info', `Run: cd ai-styling-backend/services/${service.name}-service && npm start`);
    }

    console.log(`\n${colors.green}Fixes Applied: ${this.fixes.length}${colors.reset}`);
    
    if (this.fixes.length > 0) {
      console.log('\n📝 Next Steps:');
      console.log('1. Restart all services with production config');
      console.log('2. Run database migrations');
      console.log('3. Configure real API keys');
      console.log('4. Enable HTTPS');
      console.log('5. Set up monitoring');
    }
  }

  generateSecret() {
    return require('crypto').randomBytes(32).toString('base64');
  }
}

// Run validation
const validator = new SystemValidator();
validator.validateAll().catch(console.error);