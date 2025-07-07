#!/bin/bash

# XplainCrypto MindsDB Startup Script
# Handles initialization and startup with proper health checks

set -e

echo "🚀 Starting XplainCrypto MindsDB..."

# Function to read secrets
read_secret() {
    local secret_file="/run/secrets/$1"
    if [ -f "$secret_file" ]; then
        cat "$secret_file"
    else
        echo ""
    fi
}

# Set up environment variables from secrets
export OPENAI_API_KEY=$(read_secret "openai_api_key")
export ANTHROPIC_API_KEY=$(read_secret "anthropic_api_key") 
export TIMEGPT_API_KEY=$(read_secret "timegpt_api_key")
export COINMARKETCAP_API_KEY=$(read_secret "coinmarketcap_api_key")
export DUNE_API_KEY=$(read_secret "dune_api_key")
export COINGECKO_API_KEY=$(read_secret "coingecko_api_key")
export POSTGRES_PASSWORD=$(read_secret "postgres_password")
export REDIS_PASSWORD=$(read_secret "redis_password")

echo "✅ Environment variables configured from secrets"

# Wait for database connectivity
echo "⏳ Waiting for database connectivity..."
timeout=60
while [ $timeout -gt 0 ]; do
    if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ PostgreSQL connection successful"
        break
    fi
    echo "⏳ Waiting for PostgreSQL... ($timeout seconds remaining)"
    sleep 2
    timeout=$((timeout-2))
done

if [ $timeout -le 0 ]; then
    echo "❌ PostgreSQL connection timeout"
    exit 1
fi

# Wait for Redis connectivity  
echo "⏳ Waiting for Redis connectivity..."
timeout=30
while [ $timeout -gt 0 ]; do
    if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" ping >/dev/null 2>&1; then
        echo "✅ Redis connection successful"
        break
    fi
    echo "⏳ Waiting for Redis... ($timeout seconds remaining)"
    sleep 2
    timeout=$((timeout-2))
done

if [ $timeout -le 0 ]; then
    echo "❌ Redis connection timeout"
    exit 1
fi

# Initialize MindsDB configuration
echo "🔧 Initializing MindsDB configuration..."

# Create config directory
mkdir -p /opt/mindsdb/var

# Start MindsDB
echo "🚀 Starting MindsDB server..."
exec python -m mindsdb \
    --config=/opt/mindsdb/var \
    --verbose 