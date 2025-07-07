#!/bin/bash

# XplainCrypto MindsDB Complete Deployment Script
# Deploys MindsDB with all configurations and validations

set -e

echo "🚀 XplainCrypto MindsDB Deployment"
echo "=================================="

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
        exit 1
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
    else
        echo -e "${BLUE}ℹ️  $message${NC}"
    fi
}

# Phase 1: Pre-deployment validation
echo -e "\n${BLUE}Phase 1: Pre-deployment Validation${NC}"
echo "-----------------------------------"

if [ -f "scripts/validate-mindsdb-environment.sh" ]; then
    print_status "INFO" "Running environment validation..."
    ./scripts/validate-mindsdb-environment.sh
    if [ $? -eq 0 ]; then
        print_status "PASS" "Environment validation successful"
    else
        print_status "FAIL" "Environment validation failed"
    fi
else
    print_status "WARN" "Environment validation script not found"
fi

# Phase 2: Setup secrets
echo -e "\n${BLUE}Phase 2: Secrets Setup${NC}"
echo "----------------------"

if [ -f "secrets/create-secrets.sh" ]; then
    print_status "INFO" "Setting up secrets..."
    ./secrets/create-secrets.sh
    print_status "PASS" "Secrets configured"
else
    print_status "FAIL" "Secrets setup script not found"
fi

# Phase 3: Setup volumes
echo -e "\n${BLUE}Phase 3: Volume Setup${NC}"
echo "---------------------"

if [ -f "scripts/setup-volumes.sh" ]; then
    print_status "INFO" "Setting up persistent volumes..."
    ./scripts/setup-volumes.sh
    print_status "PASS" "Volumes configured"
else
    print_status "FAIL" "Volume setup script not found"
fi

# Phase 4: Network validation
echo -e "\n${BLUE}Phase 4: Network Integration${NC}"
echo "-----------------------------"

if docker network ls | grep -q "xplaincrypto_network"; then
    print_status "PASS" "xplaincrypto_network exists"
else
    print_status "WARN" "Creating xplaincrypto_network..."
    docker network create xplaincrypto_network
    print_status "PASS" "Network created"
fi

# Phase 5: Database connectivity check
echo -e "\n${BLUE}Phase 5: Database Connectivity${NC}"
echo "-------------------------------"

if [ -f "scripts/test-database-connectivity.sh" ]; then
    print_status "INFO" "Testing database connections..."
    ./scripts/test-database-connectivity.sh
    print_status "PASS" "Database connectivity verified"
else
    print_status "WARN" "Database connectivity test not found"
fi

# Phase 6: Docker build and deployment
echo -e "\n${BLUE}Phase 6: Docker Deployment${NC}"
echo "--------------------------"

print_status "INFO" "Stopping any existing MindsDB containers..."
docker-compose down 2>/dev/null || true

print_status "INFO" "Building MindsDB Docker image..."
docker-compose build --no-cache

print_status "INFO" "Starting MindsDB services..."
docker-compose up -d

# Wait for MindsDB to be ready
print_status "INFO" "Waiting for MindsDB to be ready..."
timeout=120
while [ $timeout -gt 0 ]; do
    if curl -f -s http://localhost:47334/api/status >/dev/null 2>&1; then
        print_status "PASS" "MindsDB API is responding"
        break
    fi
    echo "⏳ Waiting for MindsDB API... ($timeout seconds remaining)"
    sleep 5
    timeout=$((timeout-5))
done

if [ $timeout -le 0 ]; then
    print_status "FAIL" "MindsDB API timeout - checking logs..."
    docker logs xplaincrypto-mindsdb --tail 20
    exit 1
fi

# Phase 7: Health check
echo -e "\n${BLUE}Phase 7: Health Verification${NC}"
echo "-----------------------------"

if [ -f "scripts/health-check.sh" ]; then
    print_status "INFO" "Running comprehensive health check..."
    ./scripts/health-check.sh
    print_status "PASS" "Health check completed"
else
    print_status "WARN" "Health check script not found"
fi

# Phase 8: Initialize databases and handlers
echo -e "\n${BLUE}Phase 8: Database & Handler Initialization${NC}"
echo "-------------------------------------------"

if [ -f "scripts/initialize-databases.sh" ]; then
    print_status "INFO" "Initializing databases and handlers..."
    ./scripts/initialize-databases.sh
    print_status "PASS" "Databases and handlers initialized"
else
    print_status "WARN" "Database initialization script will be created next"
fi

# Final status
echo -e "\n${GREEN}🎉 MindsDB Deployment Complete!${NC}"
echo "================================="
echo ""
echo "📊 Access URLs:"
echo "   MindsDB API: http://localhost:47334"
echo "   MindsDB Web: http://localhost:47335"
echo "   Domain: http://mindsdb.xplaincrypto.ai (when DNS configured)"
echo ""
echo "📋 Next Steps:"
echo "   1. Initialize databases: ./scripts/initialize-databases.sh"
echo "   2. Deploy AI agents: ./scripts/deploy-ai-agents.sh"
echo "   3. Run tests: ./scripts/test-ai-agents.sh"
echo ""
echo "🔍 Monitor with: docker logs -f xplaincrypto-mindsdb" 