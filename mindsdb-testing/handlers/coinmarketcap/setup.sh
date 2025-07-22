
#!/bin/bash

# CoinMarketCap Handler Setup Script
# Sets up CoinMarketCap data source integration

set -e

echo "🪙 Setting up CoinMarketCap Handler..."

# Configuration
HANDLER_NAME="coinmarketcap_handler"
API_BASE_URL="https://pro-api.coinmarketcap.com"

# Create handler SQL
cat > create_handler.sql << 'EOF'
-- Create CoinMarketCap Handler
CREATE OR REPLACE DATABASE coinmarketcap_db
WITH ENGINE = 'coinmarketcap',
PARAMETERS = {
    "api_key": "{{CMC_API_KEY}}",
    "base_url": "https://pro-api.coinmarketcap.com",
    "version": "v1",
    "rate_limit": 333,
    "timeout": 30
};
EOF

# Create tables SQL
cat > create_tables.sql << 'EOF'
-- CoinMarketCap Tables

-- Cryptocurrency listings
CREATE OR REPLACE VIEW coinmarketcap_db.listings AS (
    SELECT * FROM coinmarketcap_db.cryptocurrency_listings_latest
);

-- Price quotes
CREATE OR REPLACE VIEW coinmarketcap_db.quotes AS (
    SELECT * FROM coinmarketcap_db.cryptocurrency_quotes_latest
);

-- Market data
CREATE OR REPLACE VIEW coinmarketcap_db.market_data AS (
    SELECT * FROM coinmarketcap_db.global_metrics_quotes_latest
);

-- Historical data
CREATE OR REPLACE VIEW coinmarketcap_db.historical AS (
    SELECT * FROM coinmarketcap_db.cryptocurrency_quotes_historical
);
EOF

# Execute setup
execute_setup() {
    echo "Creating CoinMarketCap handler..."
    
    # Check if API key is set
    if [ -z "$CMC_API_KEY" ]; then
        echo "⚠️  Warning: CMC_API_KEY environment variable not set"
        echo "Please set your CoinMarketCap API key:"
        echo "export CMC_API_KEY='your_api_key_here'"
    fi
    
    # Replace API key placeholder
    sed "s/{{CMC_API_KEY}}/$CMC_API_KEY/g" create_handler.sql > create_handler_final.sql
    
    # Execute SQL commands
    if command -v mindsdb &> /dev/null; then
        mindsdb -f create_handler_final.sql
        mindsdb -f create_tables.sql
        echo "✅ CoinMarketCap handler created successfully"
    else
        echo "⚠️  MindsDB CLI not found. SQL files created for manual execution."
    fi
}

# Validation
validate_setup() {
    echo "Validating CoinMarketCap handler setup..."
    
    cat > validate.sql << 'EOF'
-- Validation queries
SHOW DATABASES;
DESCRIBE coinmarketcap_db;
SELECT * FROM coinmarketcap_db.listings LIMIT 5;
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
    echo "🎉 CoinMarketCap handler setup completed!"
}

main "$@"
