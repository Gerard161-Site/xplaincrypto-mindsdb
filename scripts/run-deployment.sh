#!/bin/bash

# XplainCrypto MindsDB Complete Deployment
echo "🚀 Running complete MindsDB deployment..."

cd "$(dirname "$0")/.."

# Check secrets exist
if [ ! -d "secrets" ]; then
    echo "❌ Secrets directory not found!"
    exit 1
fi

# Setup volumes
sudo mkdir -p /var/lib/xplaincrypto/mindsdb
sudo chown -R 1000:1000 /var/lib/xplaincrypto/mindsdb
mkdir -p logs

# Create network if needed
docker network create xplaincrypto_network 2>/dev/null || true

# Deploy (use legacy docker-compose)
echo "🐳 Stopping existing containers..."
docker-compose down 2>/dev/null || true

echo "🔨 Building MindsDB..."
docker-compose build --no-cache

echo "🚀 Starting MindsDB..."
docker-compose up -d

echo "⏳ Waiting for MindsDB API..."
sleep 30

echo "🔍 Testing MindsDB connection..."
curl -f http://localhost:47334/api/status || echo "❌ MindsDB not responding"

echo "✅ MindsDB deployment complete!" 