#!/bin/bash

# XplainCrypto MindsDB Health Check Script
# Comprehensive health validation for monitoring

echo "🏥 MindsDB Health Check"
echo "======================"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if MindsDB container is running
echo -e "\n${BLUE}1. Container Status${NC}"
echo "-------------------"

if docker ps | grep -q "xplaincrypto-mindsdb"; then
    print_status "PASS" "MindsDB container is running"
else
    print_status "FAIL" "MindsDB container is not running"
    exit 1
fi

# Check MindsDB API endpoint
echo -e "\n${BLUE}2. API Health${NC}"
echo "-------------"

if curl -f -s http://localhost:47334/api/status >/dev/null; then
    print_status "PASS" "MindsDB API is responding"
    
    # Get API status details
    API_RESPONSE=$(curl -s http://localhost:47334/api/status)
    print_status "INFO" "API Response: $API_RESPONSE"
else
    print_status "FAIL" "MindsDB API is not responding"
fi

# Check database connections
echo -e "\n${BLUE}3. Database Connections${NC}"
echo "------------------------"

# Test via MindsDB API
if curl -f -s "http://localhost:47334/api/sql/query" \
    -H "Content-Type: application/json" \
    -d '{"query": "SHOW DATABASES;"}' >/dev/null; then
    print_status "PASS" "MindsDB can execute SQL queries"
else
    print_status "WARN" "MindsDB SQL query test failed"
fi

# Check logs for errors
echo -e "\n${BLUE}4. Error Check${NC}"
echo "---------------"

if docker logs xplaincrypto-mindsdb --tail 50 2>&1 | grep -i "error\|exception\|failed" | grep -v "INFO\|DEBUG"; then
    print_status "WARN" "Recent errors found in logs"
else
    print_status "PASS" "No recent errors in logs"
fi

# Check resource usage
echo -e "\n${BLUE}5. Resource Usage${NC}"
echo "------------------"

STATS=$(docker stats xplaincrypto-mindsdb --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}")
print_status "INFO" "Resource usage: $STATS"

echo -e "\n${BLUE}Health Check Complete${NC}"
echo "====================" 