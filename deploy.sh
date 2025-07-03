#!/bin/bash
set -e

echo "🚀 XplainCrypto MindsDB Complete Deployment"
echo "==========================================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    case $1 in
        "PASS") echo -e "${GREEN}✅ $2${NC}" ;;
        "FAIL") echo -e "${RED}❌ $2${NC}"; exit 1 ;;
        "WARN") echo -e "${YELLOW}⚠️  $2${NC}" ;;
        *) echo -e "ℹ️  $2" ;;
    esac
}

# 1. Validate secrets
if [ ! -d "secrets" ] || [ ! -f "secrets/openai_api_key.txt" ]; then
    print_status "FAIL" "Secrets directory missing. Run: mkdir -p secrets && setup API keys"
fi
print_status "PASS" "Secrets validation"

# 2. Setup volumes
print_status "INFO" "Setting up persistent volumes..."
sudo mkdir -p /var/lib/xplaincrypto/mindsdb/{var,logs,data}
sudo chown -R 1000:1000 /var/lib/xplaincrypto/mindsdb
mkdir -p logs
print_status "PASS" "Volume setup"

# 3. Network setup
docker network create xplaincrypto_network 2>/dev/null || true
print_status "PASS" "Network setup"

# 4. Deploy containers
print_status "INFO" "Deploying containers..."
docker-compose down 2>/dev/null || true
docker-compose up -d --build
print_status "PASS" "Container deployment"

# 5. Wait for MindsDB API
print_status "INFO" "Waiting for MindsDB API..."
timeout=120
while [ $timeout -gt 0 ]; do
    if curl -f -s http://localhost:47334/api/status >/dev/null 2>&1; then
        print_status "PASS" "MindsDB API ready"
        break
    fi
    echo "⏳ Waiting... ($timeout seconds remaining)"
    sleep 5
    timeout=$((timeout-5))
done
[ $timeout -le 0 ] && print_status "FAIL" "MindsDB API timeout"

# 6. Initialize databases
print_status "INFO" "Initializing databases and handlers..."
sleep 10

# Create PostgreSQL connection
POSTGRES_PASS=$(cat secrets/postgres_password.txt)
curl -s -X POST "http://localhost:47334/api/sql/query" \
    -H "Content-Type: application/json" \
    -d "{\"query\":\"CREATE DATABASE IF NOT EXISTS postgres_crypto WITH ENGINE = 'postgres', PARAMETERS = {'host': '142.93.49.20', 'port': 5432, 'database': 'crypto_data', 'user': 'mindsdb', 'password': '$POSTGRES_PASS'};\"}" >/dev/null

# Create CoinMarketCap connection
CMC_KEY=$(cat secrets/coinmarketcap_api_key.txt)
curl -s -X POST "http://localhost:47334/api/sql/query" \
    -H "Content-Type: application/json" \
    -d "{\"query\":\"CREATE DATABASE IF NOT EXISTS coinmarketcap_data WITH ENGINE = 'coinmarketcap', PARAMETERS = {'api_key': '$CMC_KEY'};\"}" >/dev/null

print_status "PASS" "Database initialization"

# 7. Final health check
if curl -f -s "http://localhost:47334/api/sql/query" \
    -H "Content-Type: application/json" \
    -d '{"query": "SHOW DATABASES;"}' | grep -q "postgres_crypto"; then
    print_status "PASS" "Health check - databases accessible"
else
    print_status "WARN" "Health check - some databases may not be ready"
fi

echo -e "\n${GREEN}🎉 MindsDB Deployment Complete!${NC}"
echo "================================="
echo "📊 MindsDB API: http://localhost:47334"
echo "🔍 Test: curl http://localhost:47334/api/status"
echo "📋 Monitor: docker logs -f xplaincrypto-mindsdb" 