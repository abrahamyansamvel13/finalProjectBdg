#!/bin/bash
# Gaming Stats API - Quick Setup Script
# Run this script to get started quickly

set -e

echo "🚀 Gaming Stats API - Quick Setup"
echo "=================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "   Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    echo "   Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"

# Check if .env exists, create from example if not
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "✅ Created .env file from .env.example"
    else
        echo "⚠️  .env.example not found, creating basic .env"
        cat > .env << EOF
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=gaming_stats
MYSQL_USER=user
MYSQL_PASSWORD=password
DATABASE_URL=mysql+pymysql://user:password@mysql:3306/gaming_stats
API_HOST=0.0.0.0
API_PORT=8000
EOF
    fi
fi

echo "🔨 Building and starting services..."
sudo docker-compose up -d --build

echo "⏳ Waiting for services to be ready..."
sleep 15

# Check if services are running
if sudo docker-compose ps | grep -q "Up"; then
    echo "✅ Services are running!"
    echo ""
    echo "🌐 Access your application:"
    echo "   API: http://localhost:8000"
    echo "   API Docs: http://localhost:8000/docs"
    echo "   Health Check: http://localhost:8000/health"
    echo ""
    echo "📊 Database:"
    echo "   Host: localhost:3306"
    echo "   Database: gaming_stats"
    echo "   User: user"
    echo "   Password: password"
    echo ""
    echo "📝 Useful commands:"
    echo "   View logs: sudo docker-compose logs -f app"
    echo "   Stop services: docker-compose down"
    echo "   Restart: docker-compose restart"
    echo ""
    echo "🎉 Setup complete! Your Gaming Stats API is ready to use."
else
    echo "❌ Services failed to start. Check logs:"
    echo "   sudo docker-compose logs"
    exit 1
fi