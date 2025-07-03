#!/bin/bash
set -e

echo "🚀 XplainCrypto MindsDB Complete Deployment"
echo "==========================================="

# Check secrets exist
if [ ! -d "secrets" ]; then
    echo "❌ Secrets directory not found!"
    exit 1
fi
echo "✅ Secrets validation"

# Setup volumes
echo "ℹ️  Setting up persistent volumes..."
sudo mkdir -p /var/lib/xplaincrypto/mindsdb
sudo chown -R 1000:1000 /var/lib/xplaincrypto/mindsdb
mkdir -p logs
echo "✅ Volume setup"

# Create network
docker network create xplaincrypto_network 2>/dev/null || true
echo "✅ Network setup"

# Deploy with docker-compose
echo "ℹ️  Deploying containers..."
docker-compose down 2>/dev/null || true
docker-compose build --no-cache
docker-compose up -d

# Wait for startup
echo "⏳ Waiting 120 seconds for MindsDB to initialize..."
sleep 120

# Test connection
echo "🔍 Testing MindsDB connection..."
response=$(curl -s http://localhost:47334/api/status || echo "failed")
if [[ $response == *"mindsdb_version"* ]]; then
    echo "✅ MindsDB API responding correctly"
    echo $response
else
    echo "❌ MindsDB not responding properly"
    echo $response
    exit 1
fi

echo "✅ MindsDB deployment complete!" 