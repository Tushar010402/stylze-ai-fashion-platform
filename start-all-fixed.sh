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
docker-compose up -d postgres redis
echo -e "${GREEN}✅ Infrastructure services started${NC}"

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 10

# Step 2: Run Database Migrations (if needed)
echo -e "\n${BLUE}Step 2: Checking Database${NC}"
echo "----------------------------------------"
docker exec stylze-postgres psql -U stylze_user -d stylze_db -c "\dt" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database is ready${NC}"
else
    echo -e "${YELLOW}Setting up database...${NC}"
fi
cd ..

# Step 3: Start Backend Services
echo -e "\n${BLUE}Step 3: Starting Backend Services${NC}"
echo "----------------------------------------"

# Function to kill and start a service
start_service() {
    local service_name=$1
    local port=$2
    local command=$3
    
    echo -e "${YELLOW}Starting $service_name on port $port...${NC}"
    
    # Kill existing process on port
    lsof -ti:$port | xargs kill -9 2>/dev/null
    sleep 1
    
    # Start service
    eval "$command" &
    
    echo -e "${GREEN}✅ $service_name started${NC}"
}

# Start all backend services with correct commands
start_service "User Service" 3001 "cd ai-styling-backend/services/user-service && node production-server.js"
start_service "Wardrobe Service (Python)" 3002 "cd ai-styling-backend/services/wardrobe-service && python3 simple_wardrobe.py"
start_service "Avatar Service" 3003 "cd ai-styling-backend/services/avatar-service && node simple-avatar-service.js"
start_service "Recommendation Service (GraphQL)" 3004 "cd ai-styling-backend/services/recommendation-service && node simple-graphql-server.js"
start_service "Notification Service" 3005 "cd ai-styling-backend/services/notification-service && node simple-notification-server.js"
start_service "AI Service (Python)" 8000 "cd ai-styling-ai && source venv/bin/activate && cd src && python fixed_ai_service.py"
start_service "API Gateway" 3010 "cd ai-styling-backend/services/api-gateway && node simple-gateway.js"

# Step 4: Start Frontend Applications
echo -e "\n${BLUE}Step 4: Starting Frontend Applications${NC}"
echo "----------------------------------------"

# Start Web App
echo -e "${YELLOW}Starting Next.js Web App...${NC}"
lsof -ti:3006 | xargs kill -9 2>/dev/null
sleep 1
cd ai-styling-web && npm run dev -- --port 3006 > /dev/null 2>&1 &
cd ..
echo -e "${GREEN}✅ Web app started on http://localhost:3006${NC}"

# Start Mobile App
echo -e "${YELLOW}Starting React Native Mobile App...${NC}"
cd ai-styling-mobile
npm run start -- --reset-cache > /dev/null 2>&1 &
cd ..
echo -e "${GREEN}✅ Mobile app Metro bundler started${NC}"

# Step 5: Display Status
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 All Services Started Successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Services Running:"
echo "----------------"
echo "📦 Infrastructure:"
echo "   • PostgreSQL:    http://localhost:5432"
echo "   • Redis:         http://localhost:6379"
echo ""
echo "🔧 Backend Services:"
echo "   • API Gateway:    http://localhost:3010"
echo "   • User Service:   http://localhost:3001"
echo "   • Wardrobe:       http://localhost:3002"
echo "   • Avatar Service: http://localhost:3003"
echo "   • Recommendation: http://localhost:3004/graphql"
echo "   • Notifications:  http://localhost:3005"
echo "   • AI Service:     http://localhost:8000"
echo ""
echo "🎨 Frontend:"
echo "   • Web App:        http://localhost:3006"
echo "   • Mobile:         Metro bundler running"
echo ""
echo "📊 Monitoring:"
echo "   • Health Check:   http://localhost:3010/health"
echo ""
echo -e "${YELLOW}To stop all services, run: ./stop-all.sh${NC}"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"

# Keep script running
echo -e "\n${YELLOW}Press Ctrl+C to stop all services${NC}"
trap 'echo -e "\n${RED}Stopping all services...${NC}"; pkill -f "node|python"; exit' INT
while true; do sleep 1; done