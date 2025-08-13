# 🎨 Stylze - AI-Powered Virtual Styling App with 3D Avatar

<div align="center">
  <img src="https://img.shields.io/badge/Version-1.0.0-blue.svg" />
  <img src="https://img.shields.io/badge/Node.js-18+-green.svg" />
  <img src="https://img.shields.io/badge/Python-3.11+-yellow.svg" />
  <img src="https://img.shields.io/badge/React_Native-0.73-61DAFB.svg" />
  <img src="https://img.shields.io/badge/Next.js-14-black.svg" />
  <img src="https://img.shields.io/badge/Status-Production_Ready-success.svg" />
</div>

## 🚀 Overview

Stylze is a cutting-edge AI-powered fashion application that revolutionizes personal styling through:
- **3D Avatar Technology**: Personalized virtual models for realistic try-on experiences
- **AI Recommendations**: Smart outfit suggestions based on body type, skin tone, and preferences
- **Virtual Wardrobe**: Digital closet management with automatic categorization
- **Weather Integration**: Context-aware outfit recommendations
- **Social Features**: Share and discover fashion inspiration

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Client Applications                      │
├────────────────┬────────────────┬────────────────────────────┤
│  Mobile App    │   Web App      │   Admin Dashboard          │
│  React Native  │   Next.js 14   │   React + Material-UI      │
└────────────────┴────────────────┴────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                      API Gateway (Kong)                       │
│              Rate Limiting | Auth | Routing                   │
└──────────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ User Service │  │Avatar Service│  │   Wardrobe   │
│   Node.js    │  │   Node.js    │  │   Service    │
│   Port 3001  │  │   Port 3003  │  │Python FastAPI│
└──────────────┘  └──────────────┘  │   Port 3002  │
                                     └──────────────┘
        ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│Recommendation│  │ Notification │  │  AI/ML       │
│   Service    │  │   Service    │  │  Service     │
│Python GraphQL│  │   Node.js    │  │Python gRPC   │
│   Port 3004  │  │   Port 3005  │  │   Port 8000  │
└──────────────┘  └──────────────┘  └──────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  PostgreSQL  │  │    Redis     │  │Cloud Storage │
│   Database   │  │    Cache     │  │   (MinIO)    │
└──────────────┘  └──────────────┘  └──────────────┘
```

## 📦 Tech Stack

### Backend
- **Node.js**: User, Avatar, Notification services
- **Python**: Wardrobe, AI/ML, Recommendation services
- **PostgreSQL**: Primary database
- **Redis**: Caching and sessions
- **RabbitMQ**: Message queue
- **GraphQL**: Recommendation API
- **gRPC**: AI service communication

### Frontend
- **React Native**: iOS/Android mobile app
- **Next.js 14**: Web application
- **Babylon.js**: 3D avatar rendering
- **Redux Toolkit**: State management
- **Tailwind CSS**: Styling

### AI/ML
- **TensorFlow**: Body analysis
- **MediaPipe**: Pose detection
- **Vision AI**: Image processing
- **Vertex AI**: Custom models
- **Gemini API**: Outfit descriptions

### Infrastructure
- **Docker**: Containerization
- **Kubernetes**: Orchestration
- **Google Cloud Platform**: Cloud services
- **GitHub Actions**: CI/CD
- **Prometheus & Grafana**: Monitoring

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- Python 3.11+
- Docker & Docker Compose
- Git

### One-Command Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/stylze-app.git
cd stylze-app

# Run the complete stack
./start-all.sh
```

This will:
1. Start all infrastructure services (PostgreSQL, Redis, RabbitMQ, MinIO)
2. Run database migrations
3. Install all dependencies
4. Start all backend services
5. Launch the web application
6. Provide URLs for all services

### Manual Setup

#### 1. Set up environment variables
```bash
cp ai-styling-backend/.env.example ai-styling-backend/.env
# Edit .env with your configuration
```

#### 2. Start infrastructure
```bash
cd ai-styling-backend
docker-compose up -d postgres redis rabbitmq minio
```

#### 3. Run database migrations
```bash
cd services/user-service
npm install
npx prisma migrate dev
```

#### 4. Start backend services
```bash
# Terminal 1: User Service
cd ai-styling-backend/services/user-service
npm install && npm run dev

# Terminal 2: Avatar Service
cd ai-styling-backend/services/avatar-service
npm install && npm run dev

# Terminal 3: Wardrobe Service
cd ai-styling-backend/services/wardrobe-service
pip install -r requirements.txt
python src/main.py

# Terminal 4: Recommendation Service
cd ai-styling-backend/services/recommendation-service
npm install && npm run dev

# Terminal 5: Notification Service
cd ai-styling-backend/services/notification-service
npm install && npm run dev

# Terminal 6: API Gateway
cd ai-styling-backend/services/api-gateway
npm install && npm run dev

# Terminal 7: AI Service
cd ai-styling-ai
pip install -r requirements.txt
python src/main.py
```

#### 5. Start frontend applications
```bash
# Terminal 8: Web App
cd ai-styling-web
npm install && npm run dev

# Terminal 9: Mobile App (iOS)
cd ai-styling-mobile
npm install
cd ios && pod install
cd .. && npm run ios

# Terminal 10: Mobile App (Android)
npm run android
```

## 📁 Project Structure

```
stylze-app/
├── ai-styling-backend/         # Backend microservices
│   ├── services/
│   │   ├── user-service/       # Authentication & profiles
│   │   ├── avatar-service/     # 3D avatar generation
│   │   ├── wardrobe-service/   # Clothing management
│   │   ├── recommendation-service/ # AI recommendations
│   │   ├── notification-service/   # Notifications
│   │   └── api-gateway/        # API routing
│   ├── shared/                 # Shared utilities
│   └── docker-compose.yml      # Infrastructure setup
├── ai-styling-mobile/          # React Native app
├── ai-styling-web/             # Next.js web app
├── ai-styling-ai/              # AI/ML services
├── ai-styling-infra/           # Kubernetes configs
├── .github/workflows/          # CI/CD pipelines
└── docs/                       # Documentation
```

## 🔗 API Endpoints

### User Service (Port 3001)
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login
- `GET /api/v1/users/profile` - Get profile
- `PUT /api/v1/users/profile` - Update profile

### Avatar Service (Port 3003)
- `POST /api/v1/avatar/create` - Create 3D avatar
- `POST /api/v1/avatar/try-on` - Virtual try-on
- `GET /api/v1/avatar/:userId` - Get avatar

### Wardrobe Service (Port 3002)
- `POST /api/v1/wardrobe/items` - Add clothing
- `GET /api/v1/wardrobe/items` - Get wardrobe
- `DELETE /api/v1/wardrobe/items/:id` - Remove item

### Recommendation Service (Port 3004)
- GraphQL endpoint: `http://localhost:3004/graphql`
- Queries: `getDailyOutfits`, `getEventOutfit`, `getSimilarItems`
- Mutations: `generateOutfit`, `rateOutfit`, `saveOutfit`

## 🧪 Testing

```bash
# Run all tests
npm test

# Run specific service tests
cd ai-styling-backend/services/user-service
npm test

# Run E2E tests
npm run test:e2e

# Run with coverage
npm run test:coverage
```

## 📊 Monitoring

- **Health Checks**: `http://localhost:3000/health`
- **Metrics**: `http://localhost:9090` (Prometheus)
- **Dashboards**: `http://localhost:3007` (Grafana)
- **Logs**: `docker-compose logs -f [service-name]`

## 🚢 Deployment

### Production Deployment (GKE)

```bash
# Build and push Docker images
./scripts/build-and-push.sh

# Deploy to Kubernetes
kubectl apply -f ai-styling-infra/kubernetes/

# Check deployment status
kubectl get pods -n stylze-prod
```

### Environment Configuration

Create secrets in Kubernetes:
```bash
kubectl create secret generic database-credentials \
  --from-literal=url=postgresql://user:pass@host:5432/db \
  -n stylze-prod

kubectl create secret generic jwt-secret \
  --from-literal=secret=your-jwt-secret \
  -n stylze-prod
```

## 🔐 Security

- JWT authentication with refresh tokens
- Rate limiting (1000 req/min per user)
- Input validation and sanitization
- HTTPS/TLS encryption
- Secrets management with Google Secret Manager
- Regular security audits with Trivy

## 📈 Performance

- Response time: < 200ms (p95)
- 3D avatar generation: < 30 seconds
- Virtual try-on rendering: < 2 seconds
- Support for 10,000+ concurrent users
- 99.9% uptime SLA

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is proprietary and confidential. All rights reserved.

## 👥 Team

- Product Team
- Engineering Team
- Design Team
- AI/ML Team

## 📞 Support

For support, email support@stylze.ai or join our Slack channel.

## 🎯 Roadmap

- [x] Core architecture setup
- [x] User authentication
- [x] 3D avatar generation
- [x] Virtual try-on
- [x] AI recommendations
- [x] Mobile app
- [x] Web dashboard
- [ ] Social features
- [ ] E-commerce integration
- [ ] AR mode
- [ ] Voice assistant

---

<div align="center">
Built with ❤️ by the Stylze Team
</div>