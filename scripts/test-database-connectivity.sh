#!/bin/bash

# XplainCrypto MindsDB Database Connectivity Test
# Tests connection to existing infrastructure databases

set -e

echo "🔗 XplainCrypto MindsDB Database Connectivity Test"
echo "================================================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Status function
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ $message${NC}"
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}❌ $message${NC}"
        return 1
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
    else
        echo -e "${BLUE}ℹ️  $message${NC}"
    fi
}

# Read database password
DB_PASSWORD=$(cat secrets/postgres_password.txt 2>/dev/null || echo "")
REDIS_PASSWORD=$(cat secrets/redis_password.txt 2>/dev/null || echo "")

# Test PostgreSQL crypto_data connection
echo -e "\n${BLUE}1. PostgreSQL crypto_data Database${NC}"
echo "-----------------------------------"

# Check if container is running
if docker ps | grep -q "postgres.*5432"; then
    print_status "PASS" "PostgreSQL container running on port 5432"
    
    # Test connection from outside
    if PGPASSWORD="$DB_PASSWORD" psql -h 142.93.49.20 -p 5432 -U mindsdb -d crypto_data -c "SELECT version();" 2>/dev/null; then
        print_status "PASS" "External connection to crypto_data successful"
    else
        print_status "FAIL" "External connection to crypto_data failed"
    fi
    
    # Test from docker network (how MindsDB will connect)
    if docker run --rm --network xplaincrypto_network postgres:15 psql -h postgres-crypto -p 5432 -U mindsdb -d crypto_data -c "SELECT 1;" 2>/dev/null; then
        print_status "PASS" "Docker network connection to crypto_data successful"
    else
        print_status "WARN" "Docker network connection test failed (network may not exist yet)"
    fi
    
    # Check database schema
    TABLES=$(PGPASSWORD="$DB_PASSWORD" psql -h 142.93.49.20 -p 5432 -U mindsdb -d crypto_data -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null | xargs)
    if [ "$TABLES" -gt 0 ]; then
        print_status "PASS" "Database has $TABLES tables in public schema"
    else
        print_status "WARN" "Database appears empty - will need initial setup"
    fi
    
else
    print_status "FAIL" "PostgreSQL container not running"
fi

# Test Redis connection
echo -e "\n${BLUE}2. Redis Cache${NC}"
echo "---------------"

if docker ps | grep -q "redis.*6379"; then
    print_status "PASS" "Redis container running on port 6379"
    
    # Test Redis connection
    if docker exec xplaincrypto-redis redis-cli --no-auth-warning -a "$REDIS_PASSWORD" ping 2>/dev/null | grep -q "PONG"; then
        print_status "PASS" "Redis connection successful"
        
        # Test Redis info
        REDIS_VERSION=$(docker exec xplaincrypto-redis redis-cli --no-auth-warning -a "$REDIS_PASSWORD" INFO SERVER | grep "redis_version" | cut -d: -f2 | tr -d '\r')
        print_status "INFO" "Redis version: $REDIS_VERSION"
        
        # Test Redis memory
        REDIS_MEMORY=$(docker exec xplaincrypto-redis redis-cli --no-auth-warning -a "$REDIS_PASSWORD" INFO MEMORY | grep "used_memory_human" | cut -d: -f2 | tr -d '\r')
        print_status "INFO" "Redis memory usage: $REDIS_MEMORY"
        
    else
        print_status "FAIL" "Redis connection failed"
    fi
else
    print_status "FAIL" "Redis container not running"
fi

# Test PostgreSQL user_data connection (for FastAPI integration)
echo -e "\n${BLUE}3. PostgreSQL user_data Database${NC}"
echo "-----------------------------------"

if docker ps | grep -q "postgres.*5433"; then
    print_status "PASS" "PostgreSQL user_data container running on port 5433"
    
    # Test connection
    if PGPASSWORD="$DB_PASSWORD" psql -h 142.93.49.20 -p 5433 -U xplaincrypto -d user_data -c "SELECT 1;" 2>/dev/null; then
        print_status "PASS" "Connection to user_data successful"
    else
        print_status "WARN" "Connection to user_data failed (may use different credentials)"
    fi
else
    print_status "WARN" "PostgreSQL user_data container not running (may not be needed for MindsDB)"
fi

# Test network connectivity
echo -e "\n${BLUE}4. Network Connectivity${NC}"
echo "------------------------"

# Check if xplaincrypto_network exists
if docker network ls | grep -q "xplaincrypto_network"; then
    print_status "PASS" "Docker network 'xplaincrypto_network' exists"
else
    print_status "WARN" "Docker network 'xplaincrypto_network' not found"
fi

# Test DNS resolution for database services
HOSTS=("postgres-crypto" "redis" "prometheus" "grafana")
for host in "${HOSTS[@]}"; do
    if docker run --rm --network xplaincrypto_network alpine nslookup "$host" 2>/dev/null | grep -q "Address"; then
        print_status "PASS" "DNS resolution for $host successful"
    else
        print_status "WARN" "DNS resolution for $host failed"
    fi
done

echo -e "\n${BLUE}Database Connectivity Summary${NC}"
echo "=============================="
echo "✅ Ready for MindsDB database integration"
echo "📋 Connection details for MindsDB config:"
echo "   - PostgreSQL crypto_data: postgres-crypto:5432/crypto_data"
echo "   - Redis cache: redis:6379"
echo "   - Network: xplaincrypto_network" 