#!/bin/bash

# XplainCrypto MindsDB Database & Handler Initialization
# Sets up all external data sources and custom handlers

set -e

echo "🗄️  MindsDB Database & Handler Initialization"
echo "============================================="

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
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
    else
        echo -e "${BLUE}ℹ️  $message${NC}"
    fi
}

# Function to execute SQL via MindsDB API
execute_sql() {
    local query="$1"
    local description="$2"
    
    print_status "INFO" "Executing: $description"
    
    response=$(curl -s -X POST "http://localhost:47334/api/sql/query" \
        -H "Content-Type: application/json" \
        -d "{\"query\":\"$query\"}")
    
    if echo "$response" | grep -q '"type":"error"'; then
        print_status "FAIL" "SQL Error: $response"
        return 1
    else
        print_status "PASS" "$description completed"
        return 0
    fi
}

# Wait for MindsDB to be ready
echo -e "\n${BLUE}Waiting for MindsDB API...${NC}"
timeout=60
while [ $timeout -gt 0 ]; do
    if curl -f -s http://localhost:47334/api/status >/dev/null 2>&1; then
        print_status "PASS" "MindsDB API is ready"
        break
    fi
    sleep 2
    timeout=$((timeout-2))
done

if [ $timeout -le 0 ]; then
    print_status "FAIL" "MindsDB API timeout"
    exit 1
fi

# Read API keys from secrets
COINMARKETCAP_KEY=$(docker exec xplaincrypto-mindsdb cat /run/secrets/coinmarketcap_api_key 2>/dev/null || echo "")
DUNE_KEY=$(docker exec xplaincrypto-mindsdb cat /run/secrets/dune_api_key 2>/dev/null || echo "")
COINGECKO_KEY=$(docker exec xplaincrypto-mindsdb cat /run/secrets/coingecko_api_key 2>/dev/null || echo "")

# Phase 1: Create PostgreSQL connection
echo -e "\n${BLUE}Phase 1: PostgreSQL Connection${NC}"
echo "-------------------------------"

POSTGRES_PASS=$(docker exec xplaincrypto-mindsdb cat /run/secrets/postgres_password 2>/dev/null || echo "")

execute_sql "CREATE DATABASE IF NOT EXISTS postgres_crypto
WITH ENGINE = 'postgres',
PARAMETERS = {
    'host': '142.93.49.20',
    'port': 5432,
    'database': 'crypto_data',
    'user': 'mindsdb',
    'password': '$POSTGRES_PASS'
};" "PostgreSQL crypto_data connection"

# Phase 2: Create external data source connections
echo -e "\n${BLUE}Phase 2: External Data Sources${NC}"
echo "-------------------------------"

# CoinMarketCap
if [ -n "$COINMARKETCAP_KEY" ]; then
    execute_sql "CREATE DATABASE IF NOT EXISTS coinmarketcap_data
    WITH ENGINE = 'coinmarketcap',
    PARAMETERS = {
        'api_key': '$COINMARKETCAP_KEY'
    };" "CoinMarketCap data source"
else
    print_status "WARN" "CoinMarketCap API key not found"
fi

# Dune Analytics
if [ -n "$DUNE_KEY" ]; then
    execute_sql "CREATE DATABASE IF NOT EXISTS dune_data
    WITH ENGINE = 'dune',
    PARAMETERS = {
        'api_key': '$DUNE_KEY'
    };" "Dune Analytics data source"
else
    print_status "WARN" "Dune API key not found"
fi

# CoinGecko
if [ -n "$COINGECKO_KEY" ]; then
    execute_sql "CREATE DATABASE IF NOT EXISTS coingecko_data
    WITH ENGINE = 'coingecko',
    PARAMETERS = {
        'api_key': '$COINGECKO_KEY'
    };" "CoinGecko data source"
else
    print_status "WARN" "CoinGecko API key not found"
fi

# DeFiLlama (no API key required)
execute_sql "CREATE DATABASE IF NOT EXISTS defillama_data
WITH ENGINE = 'defillama',
PARAMETERS = {};" "DeFiLlama data source"

# Whale Alerts (placeholder for future)
execute_sql "CREATE DATABASE IF NOT EXISTS whale_alerts_data
WITH ENGINE = 'whale_alerts',
PARAMETERS = {
    'api_key': 'placeholder'
};" "Whale Alerts data source (placeholder)"

# Phase 3: Test data source connections
echo -e "\n${BLUE}Phase 3: Connection Testing${NC}"
echo "----------------------------"

# Test each data source
DATABASES=("postgres_crypto" "coinmarketcap_data" "dune_data" "coingecko_data" "defillama_data")

for db in "${DATABASES[@]}"; do
    execute_sql "SHOW TABLES FROM $db LIMIT 1;" "Testing $db connection"
done

# Phase 4: Create initial data tables in PostgreSQL
echo -e "\n${BLUE}Phase 4: Initial Data Tables${NC}"
echo "-----------------------------"

# Create tables for storing historical data
execute_sql "CREATE TABLE IF NOT EXISTS postgres_crypto.crypto_prices (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    price DECIMAL(20,8) NOT NULL,
    volume_24h DECIMAL(20,2),
    market_cap DECIMAL(20,2),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    source VARCHAR(50) NOT NULL DEFAULT 'coinmarketcap',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(symbol, timestamp, source)
);" "Create crypto_prices table"

execute_sql "CREATE TABLE IF NOT EXISTS postgres_crypto.defi_protocols (
    id SERIAL PRIMARY KEY,
    protocol VARCHAR(100) NOT NULL,
    tvl DECIMAL(20,2),
    category VARCHAR(50),
    chain VARCHAR(50),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(protocol, timestamp)
);" "Create defi_protocols table"

execute_sql "CREATE TABLE IF NOT EXISTS postgres_crypto.social_sentiment (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    platform VARCHAR(50) NOT NULL,
    sentiment_score DECIMAL(5,2),
    post_count INTEGER,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);" "Create social_sentiment table"

# Phase 5: Setup data sync jobs
echo -e "\n${BLUE}Phase 5: Data Sync Jobs${NC}"
echo "-----------------------"

# Create job to sync crypto prices every hour
execute_sql "CREATE JOB sync_crypto_prices (
    INSERT INTO postgres_crypto.crypto_prices (symbol, price, volume_24h, market_cap, timestamp, source)
    SELECT 
        symbol, 
        price, 
        volume_24h, 
        market_cap, 
        NOW() as timestamp,
        'coinmarketcap' as source
    FROM coinmarketcap_data.listings
    WHERE symbol IN ('BTC', 'ETH', 'ADA', 'DOT', 'SOL', 'MATIC', 'LINK', 'UNI', 'AAVE', 'CRV')
    ON CONFLICT (symbol, timestamp, source) DO NOTHING
)
START NOW
EVERY hour;" "Create hourly price sync job"

print_status "PASS" "Data sync jobs configured"

echo -e "\n${GREEN}🎉 Database & Handler Initialization Complete!${NC}"
echo "=============================================="
echo ""
echo "📊 Initialized Connections:"
echo "   ✅ PostgreSQL crypto_data"
echo "   ✅ CoinMarketCap API"
echo "   ✅ Dune Analytics API"
echo "   ✅ CoinGecko API"
echo "   ✅ DeFiLlama API"
echo "   ⏳ Whale Alerts (placeholder)"
echo ""
echo "📋 Created Tables:"
echo "   ✅ crypto_prices (price history)"
echo "   ✅ defi_protocols (DeFi data)"
echo "   ✅ social_sentiment (sentiment data)"
echo ""
echo "⏰ Sync Jobs:"
echo "   ✅ Hourly price sync for top 10 cryptos"
echo ""
echo "🔍 Monitor: SELECT * FROM postgres_crypto.crypto_prices LIMIT 10;" 