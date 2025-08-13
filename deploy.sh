#!/bin/bash

# Stylze AI Fashion Platform - Deployment Script
# This script deploys all services using Docker Compose

set -e

echo "🚀 Stylze AI Fashion Platform Deployment"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command_exists docker; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi

if ! command_exists docker-compose; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"

# Parse command line arguments
ACTION=${1:-"start"}

case $ACTION in
    start)
        echo "🔧 Starting all services..."
        
        # Stop any existing services
        docker-compose -f docker-compose.yml down 2>/dev/null || true
        
        # Start infrastructure services first
        echo "📦 Starting infrastructure services..."
        docker-compose -f docker-compose.yml up -d postgres redis rabbitmq minio
        
        # Wait for databases to be ready
        echo "⏳ Waiting for databases to initialize..."
        sleep 10
        
        # Start microservices
        echo "🎯 Starting microservices..."
        docker-compose -f docker-compose.yml up -d user-service wardrobe-service avatar-service recommendation-service notification-service
        
        # Start API Gateway
        echo "🌐 Starting API Gateway..."
        docker-compose -f docker-compose.yml up -d api-gateway
        
        # Start monitoring
        echo "📊 Starting monitoring services..."
        docker-compose -f docker-compose.yml up -d prometheus grafana
        
        # Start web application
        echo "💻 Starting web application..."
        docker-compose -f docker-compose.yml up -d web-app
        
        echo -e "${GREEN}✅ All services started successfully!${NC}"
        ;;
        
    stop)
        echo "🛑 Stopping all services..."
        docker-compose -f docker-compose.yml down
        echo -e "${GREEN}✅ All services stopped${NC}"
        ;;
        
    restart)
        echo "🔄 Restarting all services..."
        $0 stop
        sleep 3
        $0 start
        ;;
        
    status)
        echo "📊 Service Status:"
        docker-compose -f docker-compose.yml ps
        ;;
        
    logs)
        SERVICE=${2:-""}
        if [ -z "$SERVICE" ]; then
            docker-compose -f docker-compose.yml logs -f
        else
            docker-compose -f docker-compose.yml logs -f $SERVICE
        fi
        ;;
        
    test)
        echo "🧪 Running integration tests..."
        node test-production-services.js
        ;;
        
    clean)
        echo "🧹 Cleaning up..."
        docker-compose -f docker-compose.yml down -v
        echo -e "${GREEN}✅ Cleanup complete${NC}"
        ;;
        
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|test|clean}"
        echo ""
        echo "Commands:"
        echo "  start    - Start all services"
        echo "  stop     - Stop all services"
        echo "  restart  - Restart all services"
        echo "  status   - Show service status"
        echo "  logs     - Show logs (optionally specify service)"
        echo "  test     - Run integration tests"
        echo "  clean    - Stop services and remove volumes"
        exit 1
        ;;
esac

# Display access URLs
if [ "$ACTION" == "start" ] || [ "$ACTION" == "restart" ]; then
    echo ""
    echo "🌐 Access URLs:"
    echo "================================"
    echo "📱 Web Application:        http://localhost:3006"
    echo "🔌 API Gateway:           http://localhost:3010"
    echo "👤 User Service:          http://localhost:3001"
    echo "👔 Wardrobe Service:      http://localhost:3002"
    echo "🎭 Avatar Service:        http://localhost:3003"
    echo "🎯 Recommendation Service: http://localhost:3004"
    echo "📧 Notification Service:   http://localhost:3005"
    echo ""
    echo "📊 Monitoring:"
    echo "================================"
    echo "📈 Prometheus:            http://localhost:9090"
    echo "📊 Grafana:              http://localhost:3007 (admin/stylze_grafana_2025)"
    echo "🗄️ pgAdmin:              http://localhost:5050 (admin@stylze.ai/admin123)"
    echo "🐰 RabbitMQ:             http://localhost:15672 (admin/stylze_rabbit_secure_2025)"
    echo "📦 MinIO:                http://localhost:9001 (minioadmin/stylze_minio_secure_2025)"
    echo ""
    echo -e "${GREEN}🎉 Stylze AI Fashion Platform is ready!${NC}"
fi