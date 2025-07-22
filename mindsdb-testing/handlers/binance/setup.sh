
#!/bin/bash

# Binance Handler Setup Script
# Sets up Binance exchange data integration

set -e

echo "🟡 Setting up Binance Handler..."

# Configuration
HANDLER_NAME="binance_handler"
API_BASE_URL="https://api.binance.com"

# Create handler SQL
cat > create_handler.sql << 'EOF'
-- Create Binance Handler
CREATE OR REPLACE DATABASE binance_db
WITH ENGINE = 'binance',
PARAMETERS = {
    "api_key": "{{BINANCE_API_KEY}}",
    "api_secret": "{{BINANCE_API_SECRET}}",
    "base_url": "https://api.binance.com",
    "testnet": false,
    "timeout": 30
};
EOF

# Create tables SQL
cat > create_tables.sql << 'EOF'
-- Binance Tables

-- Trading pairs and tickers
CREATE OR REPLACE VIEW binance_db.tickers AS (
    SELECT * FROM binance_db.ticker_24hr
);

-- Order book data
CREATE OR REPLACE VIEW binance_db.orderbook AS (
    SELECT * FROM binance_db.depth
);

-- Recent trades
CREATE OR REPLACE VIEW binance_db.trades AS (
    SELECT * FROM binance_db.recent_trades
);

-- Kline/Candlestick data
CREATE OR REPLACE VIEW binance_db.klines AS (
    SELECT * FROM binance_db.klines
);

-- Account information (requires API key)
CREATE OR REPLACE VIEW binance_db.account AS (
    SELECT * FROM binance_db.account_info
);
EOF

# Execute setup
execute_setup() {
    echo "Creating Binance handler..."
    
    # Check if API credentials are set
    if [ -z "$BINANCE_API_KEY" ]; then
        echo "⚠️  Warning: BINANCE_API_KEY environment variable not set"
        echo "Please set your Binance API credentials:"
        echo "export BINANCE_API_KEY='your_api_key_here'"
        echo "export BINANCE_API_SECRET='your_api_secret_here'"
    fi
    
    # Replace API key placeholders
    sed -e "s/{{BINANCE_API_KEY}}/$BINANCE_API_KEY/g" \
        -e "s/{{BINANCE_API_SECRET}}/$BINANCE_API_SECRET/g" \
        create_handler.sql > create_handler_final.sql
    
    # Execute SQL commands
    if command -v mindsdb &> /dev/null; then
        mindsdb -f create_handler_final.sql
        mindsdb -f create_tables.sql
        echo "✅ Binance handler created successfully"
    else
        echo "⚠️  MindsDB CLI not found. SQL files created for manual execution."
    fi
}

# Validation
validate_setup() {
    echo "Validating Binance handler setup..."
    
    cat > validate.sql << 'EOF'
-- Validation queries
SHOW DATABASES;
DESCRIBE binance_db;
SELECT symbol, price, volume FROM binance_db.tickers WHERE symbol LIKE '%USDT' LIMIT 10;
EOF
    
    if command -v mindsdb &> /dev/null; then
        mindsdb -f validate.sql
        echo "✅ Validation completed"
    else
        echo "⚠️  Manual validation required"
    fi
}

# Main execution
main() {
    execute_setup
    validate_setup
    echo "🎉 Binance handler setup completed!"
}

main "$@"
