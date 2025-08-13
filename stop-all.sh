#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Stopping all Stylze services...${NC}"

# Kill Node.js processes
echo "Stopping Node.js services..."
pkill -f "node.*user-service" 2>/dev/null
pkill -f "node.*avatar-service" 2>/dev/null
pkill -f "node.*notification-service" 2>/dev/null
pkill -f "node.*api-gateway" 2>/dev/null
pkill -f "node.*recommendation-service" 2>/dev/null
pkill -f "next dev" 2>/dev/null

# Kill Python processes
echo "Stopping Python services..."
pkill -f "python.*main.py" 2>/dev/null
pkill -f "uvicorn" 2>/dev/null

# Stop Docker services
echo "Stopping Docker services..."
cd ai-styling-backend
docker-compose down
cd ..

echo -e "${GREEN}✅ All services stopped${NC}"