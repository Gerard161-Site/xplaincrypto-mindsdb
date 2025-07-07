#!/bin/bash

# XplainCrypto MindsDB Environment Validation Script
# Validates all requirements before MindsDB deployment

set -e

echo "🔍 XplainCrypto MindsDB Environment Validation"
echo "=============================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validation results
VALIDATION_PASSED=true

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ $message${NC}"
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}❌ $message${NC}"
        VALIDATION_PASSED=false
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
    else
        echo -e "${BLUE}ℹ️  $message${NC}"
    fi
}

# 1. System Requirements Check
echo -e "\n${BLUE}1. System Requirements${NC}"
echo "----------------------"

# Check Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    print_status "PASS" "Docker installed: $DOCKER_VERSION"
else
    print_status "FAIL" "Docker not installed"
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    print_status "PASS" "Docker Compose installed: $COMPOSE_VERSION"
else
    print_status "FAIL" "Docker Compose not installed"
fi

# Check available memory
MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
if [ "$MEMORY_GB" -ge 8 ]; then
    print_status "PASS" "System memory: ${MEMORY_GB}GB (minimum 8GB required)"
else
    print_status "WARN" "System memory: ${MEMORY_GB}GB (recommended: 8GB+)"
fi

# Check available disk space
DISK_SPACE=$(df -h . | awk 'NR==2{print $4}')
print_status "INFO" "Available disk space: $DISK_SPACE"

# 2. Database Connectivity Check
echo -e "\n${BLUE}2. Database Connectivity${NC}"
echo "-------------------------"

# Check PostgreSQL crypto_data connection
if docker ps | grep -q "postgres.*5432"; then
    print_status "PASS" "PostgreSQL crypto_data container running (port 5432)"
    
    # Test actual connection
    if docker exec postgres-crypto psql -U mindsdb -d crypto_data -c "SELECT 1;" &> /dev/null; then
        print_status "PASS" "PostgreSQL crypto_data connection successful"
    else
        print_status "FAIL" "PostgreSQL crypto_data connection failed"
    fi
else
    print_status "FAIL" "PostgreSQL crypto_data container not found"
fi

# Check Redis connection
if docker ps | grep -q "redis.*6379"; then
    print_status "PASS" "Redis container running (port 6379)"
else
    print_status "FAIL" "Redis container not found"
fi

# 3. API Keys and Secrets Validation
echo -e "\n${BLUE}3. API Keys and Secrets${NC}"
echo "------------------------"

# Check secrets directory
if [ -d "../secrets" ]; then
    print_status "PASS" "Secrets directory found"
    
    # Check for required API keys
    REQUIRED_KEYS=(
        "anthropic_api_key.txt"
        "openai_api_key.txt"
        "timegpt_api_key.txt"
        "coinmarketcap_api_key.txt"
        "dune_api_key.txt"
    )
    
    for key_file in "${REQUIRED_KEYS[@]}"; do
        if [ -f "../secrets/$key_file" ] && [ -s "../secrets/$key_file" ]; then
            print_status "PASS" "API key found: $key_file"
        else
            print_status "FAIL" "Missing or empty API key: $key_file"
        fi
    done
else
    print_status "FAIL" "Secrets directory not found (../secrets)"
fi

# 4. Network Connectivity Check
echo -e "\n${BLUE}4. Network Connectivity${NC}"
echo "------------------------"

# Test external API endpoints
ENDPOINTS=(
    "api.anthropic.com:443"
    "api.openai.com:443"
    "dashboard.nixtla.io:443"
    "pro-api.coinmarketcap.com:443"
    "api.dune.com:443"
    "api.defillama.com:443"
)

for endpoint in "${ENDPOINTS[@]}"; do
    if timeout 5 nc -z ${endpoint/:/ } &> /dev/null; then
        print_status "PASS" "Network connectivity: $endpoint"
    else
        print_status "WARN" "Network connectivity issue: $endpoint"
    fi
done

# 5. Python Dependencies Check
echo -e "\n${BLUE}5. Python Dependencies${NC}"
echo "-----------------------"

# Check if requirements.txt exists
if [ -f "requirements.txt" ]; then
    print_status "PASS" "requirements.txt found"
    
    # Check Python version in Docker
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version)
        print_status "INFO" "Python version: $PYTHON_VERSION"
    fi
else
    print_status "WARN" "requirements.txt not found"
fi

# 6. Port Availability Check
echo -e "\n${BLUE}6. Port Availability${NC}"
echo "--------------------"

# Check if MindsDB port is available
if ! netstat -tuln | grep -q ":47334 "; then
    print_status "PASS" "MindsDB port 47334 available"
else
    print_status "WARN" "MindsDB port 47334 already in use"
fi

# 7. Directory Structure Check
echo -e "\n${BLUE}7. Directory Structure${NC}"
echo "----------------------"

# Check required directories
REQUIRED_DIRS=(
    "agents"
    "sql"
    "scripts"
    "handlers"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        print_status "PASS" "Directory exists: $dir"
    else
        print_status "FAIL" "Missing directory: $dir"
    fi
done

# Final validation result
echo -e "\n${BLUE}Validation Summary${NC}"
echo "=================="

if [ "$VALIDATION_PASSED" = true ]; then
    print_status "PASS" "Environment validation completed successfully!"
    echo -e "\n${GREEN}✅ Ready to deploy MindsDB${NC}"
    exit 0
else
    print_status "FAIL" "Environment validation failed!"
    echo -e "\n${RED}❌ Please fix the issues above before deploying MindsDB${NC}"
    exit 1
fi 