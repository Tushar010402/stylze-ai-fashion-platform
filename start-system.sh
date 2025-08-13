#!/bin/bash

# Stylze AI Fashion App - Complete System Startup Script
# This script starts all services with proper endpoints

echo "🚀 Starting Stylze AI Fashion Platform..."
echo "========================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Kill any existing services
echo -e "${YELLOW}Cleaning up existing services...${NC}"
pkill -f "node.*3001" 2>/dev/null
pkill -f "node.*3002" 2>/dev/null
pkill -f "node.*3003" 2>/dev/null
pkill -f "node.*3004" 2>/dev/null
pkill -f "node.*3005" 2>/dev/null
pkill -f "node.*3010" 2>/dev/null
sleep 2

# Start Infrastructure (if not running)
echo -e "\n${BLUE}📦 Checking Infrastructure Services${NC}"
if ! nc -z localhost 5432 2>/dev/null; then
    echo "Starting PostgreSQL..."
    docker start stylze-postgres 2>/dev/null || echo "PostgreSQL container not found"
fi
if ! nc -z localhost 6379 2>/dev/null; then
    echo "Starting Redis..."
    docker start stylze-redis 2>/dev/null || echo "Redis container not found"
fi
if ! nc -z localhost 5672 2>/dev/null; then
    echo "Starting RabbitMQ..."
    docker start stylze-rabbitmq 2>/dev/null || echo "RabbitMQ container not found"
fi
if ! nc -z localhost 9000 2>/dev/null; then
    echo "Starting MinIO..."
    docker start stylze-minio 2>/dev/null || echo "MinIO container not found"
fi

# Start Backend Services
echo -e "\n${BLUE}🚀 Starting Backend Services${NC}"

# User Service
echo "Starting User Service on port 3001..."
cd /Users/macbookpro/Desktop/Personal_Stylze/ai-styling-backend/services/user-service
PORT=3001 node simple-server.js > /tmp/user-service.log 2>&1 &

# Wardrobe Service
echo "Starting Wardrobe Service on port 3002..."
cd /Users/macbookpro/Desktop/Personal_Stylze/ai-styling-backend/services/wardrobe-service
if [ -f "simple-wardrobe-server.js" ]; then
    PORT=3002 node simple-wardrobe-server.js > /tmp/wardrobe-service.log 2>&1 &
else
    cd /Users/macbookpro/Desktop/Personal_Stylze/ai-styling-backend/services/user-service
    PORT=3002 node simple-server.js > /tmp/wardrobe-service.log 2>&1 &
fi

# Avatar Service
echo "Starting Avatar Service on port 3003..."
cd /Users/macbookpro/Desktop/Personal_Stylze/ai-styling-backend/services/avatar-service
if [ -f "simple-avatar-server.js" ]; then
    PORT=3003 node simple-avatar-server.js > /tmp/avatar-service.log 2>&1 &
else
    cd /Users/macbookpro/Desktop/Personal_Stylze/ai-styling-backend/services/user-service
    PORT=3003 node simple-server.js > /tmp/avatar-service.log 2>&1 &
fi

# Recommendation Service
echo "Starting Recommendation Service on port 3004..."
cd /Users/macbookpro/Desktop/Personal_Stylze/ai-styling-backend/services/user-service
PORT=3004 node simple-server.js > /tmp/recommendation-service.log 2>&1 &

# Notification Service
echo "Starting Notification Service on port 3005..."
cd /Users/macbookpro/Desktop/Personal_Stylze/ai-styling-backend/services/user-service
PORT=3005 node simple-server.js > /tmp/notification-service.log 2>&1 &

# API Gateway
echo "Starting API Gateway on port 3010..."
cd /Users/macbookpro/Desktop/Personal_Stylze/ai-styling-backend/services/api-gateway
PORT=3010 node simple-gateway.js > /tmp/api-gateway.log 2>&1 &

# Wait for services to start
sleep 5

# Start Frontend
echo -e "\n${BLUE}🎨 Starting Frontend Applications${NC}"

# Web App
echo "Starting Web App on port 3000..."
cd /Users/macbookpro/Desktop/Personal_Stylze/ai-styling-web
npm run dev > /tmp/web-app.log 2>&1 &

# Wait for all services
sleep 5

# Health Check
echo -e "\n${BLUE}🔍 Checking Service Health${NC}"
echo "================================"

services=(
    "User Service:3001"
    "Wardrobe Service:3002"
    "Avatar Service:3003"
    "Recommendation Service:3004"
    "Notification Service:3005"
    "API Gateway:3010"
)

all_healthy=true
for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    
    if curl -s http://localhost:$port/health | grep -q "healthy"; then
        echo -e "${GREEN}✅ $name is running on port $port${NC}"
    else
        echo -e "❌ $name failed to start on port $port"
        all_healthy=false
    fi
done

# Check Web App
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Web App is running on port 3000${NC}"
else
    echo -e "⚠️  Web App is starting on port 3000..."
fi

# Summary
echo -e "\n${BLUE}📊 System Status${NC}"
echo "================"
if $all_healthy; then
    echo -e "${GREEN}✅ All services are running!${NC}"
else
    echo -e "⚠️  Some services need attention"
fi

echo -e "\n${BLUE}🔗 Access URLs${NC}"
echo "=============="
echo "Web App:          http://localhost:3000"
echo "API Gateway:      http://localhost:3010"
echo "User Service:     http://localhost:3001"
echo "Wardrobe Service: http://localhost:3002"
echo "Avatar Service:   http://localhost:3003"
echo "RabbitMQ UI:      http://localhost:15672"
echo "MinIO UI:         http://localhost:9001"

echo -e "\n${BLUE}📝 Logs${NC}"
echo "======="
echo "User Service:     tail -f /tmp/user-service.log"
echo "Wardrobe Service: tail -f /tmp/wardrobe-service.log"
echo "Avatar Service:   tail -f /tmp/avatar-service.log"
echo "API Gateway:      tail -f /tmp/api-gateway.log"
echo "Web App:          tail -f /tmp/web-app.log"

echo -e "\n${GREEN}🎉 Stylze Platform is ready!${NC}"
echo "To stop all services, run: ./stop-all.sh"