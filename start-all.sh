#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Stylze AI Fashion App - Complete Stack${NC}"
echo "=================================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command_exists docker; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command_exists node; then
    echo -e "${RED}❌ Node.js is not installed. Please install Node.js 18+ first.${NC}"
    exit 1
fi

if ! command_exists python3; then
    echo -e "${RED}❌ Python 3 is not installed. Please install Python 3.9+ first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"

# Step 1: Start Infrastructure
echo -e "\n${BLUE}Step 1: Starting Infrastructure Services${NC}"
echo "----------------------------------------"
cd ai-styling-backend

# Copy .env.example to .env if not exists
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${YELLOW}Created .env file from .env.example${NC}"
fi

# Start Docker services
docker-compose down 2>/dev/null
docker-compose up -d postgres redis rabbitmq minio
echo -e "${GREEN}✅ Infrastructure services started${NC}"

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 10

# Step 2: Run Database Migrations
echo -e "\n${BLUE}Step 2: Running Database Migrations${NC}"
echo "----------------------------------------"
cd services/user-service
if [ ! -d "node_modules" ]; then
    npm install
fi
npx prisma generate
npx prisma migrate deploy 2>/dev/null || npx prisma migrate dev --name init
echo -e "${GREEN}✅ Database migrations completed${NC}"
cd ../../..

# Step 3: Install Dependencies for All Services
echo -e "\n${BLUE}Step 3: Installing Dependencies${NC}"
echo "----------------------------------------"

# Backend services
services=("user-service" "avatar-service" "wardrobe-service" "notification-service" "api-gateway" "recommendation-service")
for service in "${services[@]}"; do
    if [ -d "ai-styling-backend/services/$service" ]; then
        echo -e "${YELLOW}Installing dependencies for $service...${NC}"
        cd "ai-styling-backend/services/$service"
        if [ -f "package.json" ]; then
            npm install --silent
        elif [ -f "requirements.txt" ]; then
            python3 -m pip install -r requirements.txt --quiet
        fi
        cd ../../..
    fi
done

# AI Service
if [ -d "ai-styling-ai" ]; then
    echo -e "${YELLOW}Installing Python dependencies for AI service...${NC}"
    cd ai-styling-ai
    python3 -m venv venv 2>/dev/null
    source venv/bin/activate 2>/dev/null || . venv/Scripts/activate 2>/dev/null
    pip install -r requirements.txt --quiet
    cd ..
fi

# Mobile app
if [ -d "ai-styling-mobile" ]; then
    echo -e "${YELLOW}Installing dependencies for mobile app...${NC}"
    cd ai-styling-mobile
    npm install --silent
    cd ..
fi

# Web app
if [ -d "ai-styling-web" ]; then
    echo -e "${YELLOW}Installing dependencies for web app...${NC}"
    cd ai-styling-web
    npm install --silent
    cd ..
fi

echo -e "${GREEN}✅ All dependencies installed${NC}"

# Step 4: Start Backend Services
echo -e "\n${BLUE}Step 4: Starting Backend Services${NC}"
echo "----------------------------------------"

# Function to start a service in background
start_service() {
    local service_name=$1
    local service_path=$2
    local port=$3
    
    echo -e "${YELLOW}Starting $service_name on port $port...${NC}"
    cd "$service_path"
    
    if [ -f "package.json" ]; then
        npm run dev > /dev/null 2>&1 &
    elif [ -f "requirements.txt" ]; then
        if [ "$service_name" = "AI Service" ]; then
            cd ..
            source venv/bin/activate 2>/dev/null || . venv/Scripts/activate 2>/dev/null
            cd src
            python main.py > /dev/null 2>&1 &
        else
            python src/main.py > /dev/null 2>&1 &
        fi
    fi
    
    cd - > /dev/null
    echo -e "${GREEN}✅ $service_name started${NC}"
}

# Start all backend services
start_service "User Service" "ai-styling-backend/services/user-service" 3001
start_service "Avatar Service" "ai-styling-backend/services/avatar-service" 3003
start_service "Notification Service" "ai-styling-backend/services/notification-service" 3005
start_service "API Gateway" "ai-styling-backend/services/api-gateway" 3000
start_service "Recommendation Service" "ai-styling-backend/services/recommendation-service" 3004

# Start Python services
echo -e "${YELLOW}Starting Wardrobe Service (Python)...${NC}"
cd ai-styling-backend/services/wardrobe-service
python3 -m venv venv 2>/dev/null
source venv/bin/activate 2>/dev/null || . venv/Scripts/activate 2>/dev/null
pip install -r requirements.txt --quiet 2>/dev/null
python src/main.py > /dev/null 2>&1 &
cd ../../..
echo -e "${GREEN}✅ Wardrobe Service started${NC}"

echo -e "${YELLOW}Starting AI Service (Python)...${NC}"
cd ai-styling-ai
source venv/bin/activate 2>/dev/null || . venv/Scripts/activate 2>/dev/null
cd src
python main.py > /dev/null 2>&1 &
cd ../..
echo -e "${GREEN}✅ AI Service started${NC}"

# Step 5: Start Frontend Applications
echo -e "\n${BLUE}Step 5: Starting Frontend Applications${NC}"
echo "----------------------------------------"

# Start Web App
echo -e "${YELLOW}Starting Next.js Web App...${NC}"
cd ai-styling-web
npm run dev > /dev/null 2>&1 &
cd ..
echo -e "${GREEN}✅ Web app started on http://localhost:3006${NC}"

# Step 6: Display Status
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 All Services Started Successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Services Running:"
echo "----------------"
echo "📦 Infrastructure:"
echo "   • PostgreSQL:    http://localhost:5432"
echo "   • Redis:         http://localhost:6379"
echo "   • RabbitMQ:      http://localhost:15672 (admin/admin123)"
echo "   • MinIO:         http://localhost:9001 (minioadmin/minioadmin123)"
echo ""
echo "🔧 Backend Services:"
echo "   • API Gateway:    http://localhost:3000"
echo "   • User Service:   http://localhost:3001"
echo "   • Avatar Service: http://localhost:3003"
echo "   • Recommendation: http://localhost:3004/graphql"
echo "   • Notifications:  http://localhost:3005"
echo "   • AI Service:     http://localhost:8000"
echo ""
echo "🎨 Frontend:"
echo "   • Web App:        http://localhost:3006"
echo "   • Mobile:         Run 'cd ai-styling-mobile && npm run ios' or 'npm run android'"
echo ""
echo "📊 Monitoring:"
echo "   • Health Check:   http://localhost:3000/health"
echo ""
echo -e "${YELLOW}To stop all services, run: ./stop-all.sh${NC}"
echo -e "${YELLOW}To view logs, run: docker-compose logs -f [service-name]${NC}"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"

# Keep script running
echo -e "\n${YELLOW}Press Ctrl+C to stop all services${NC}"
trap 'echo -e "\n${RED}Stopping all services...${NC}"; ./stop-all.sh; exit' INT
while true; do sleep 1; done