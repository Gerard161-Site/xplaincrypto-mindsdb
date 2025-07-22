
#!/bin/bash

# Crypto Data Database Setup Script
# Sets up the main cryptocurrency data database

set -e

echo "💰 Setting up Crypto Data Database..."

# Configuration
DATABASE_NAME="crypto_data"

# Create database SQL
cat > create_database.sql << 'EOF'
-- Create Crypto Data Database
CREATE DATABASE IF NOT EXISTS crypto_data;
USE crypto_data;

-- Price data table
CREATE TABLE IF NOT EXISTS price_data (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    price DECIMAL(20,8) NOT NULL,
    volume_24h DECIMAL(20,2),
    market_cap DECIMAL(20,2),
    price_change_24h DECIMAL(10,4),
    price_change_7d DECIMAL(10,4),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source VARCHAR(50) NOT NULL,
    INDEX idx_symbol_timestamp (symbol, timestamp),
    INDEX idx_timestamp (timestamp)
);

-- Market data aggregation table
CREATE TABLE IF NOT EXISTS market_data (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    date DATE NOT NULL,
    open_price DECIMAL(20,8),
    high_price DECIMAL(20,8),
    low_price DECIMAL(20,8),
    close_price DECIMAL(20,8),
    volume DECIMAL(20,2),
    market_cap DECIMAL(20,2),
    UNIQUE KEY unique_symbol_date (symbol, date),
    INDEX idx_symbol_date (symbol, date)
);

-- DeFi protocol data
CREATE TABLE IF NOT EXISTS defi_protocols (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    protocol_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    blockchain VARCHAR(50),
    tvl_usd DECIMAL(20,2),
    volume_24h DECIMAL(20,2),
    fees_24h DECIMAL(20,2),
    users_24h INT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_protocol_timestamp (protocol_name, timestamp),
    INDEX idx_protocol_name (protocol_name),
    INDEX idx_category (category),
    INDEX idx_blockchain (blockchain)
);

-- Exchange data
CREATE TABLE IF NOT EXISTS exchange_data (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    exchange_name VARCHAR(50) NOT NULL,
    symbol VARCHAR(20) NOT NULL,
    price DECIMAL(20,8),
    volume_24h DECIMAL(20,2),
    bid DECIMAL(20,8),
    ask DECIMAL(20,8),
    spread DECIMAL(10,6),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_exchange_symbol (exchange_name, symbol),
    INDEX idx_timestamp (timestamp)
);

-- Blockchain metrics
CREATE TABLE IF NOT EXISTS blockchain_metrics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    blockchain VARCHAR(50) NOT NULL,
    block_height BIGINT,
    hash_rate DECIMAL(20,2),
    difficulty DECIMAL(30,2),
    transaction_count BIGINT,
    active_addresses INT,
    network_value DECIMAL(20,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_blockchain_timestamp (blockchain, timestamp)
);

-- Whale transactions
CREATE TABLE IF NOT EXISTS whale_transactions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    blockchain VARCHAR(50) NOT NULL,
    transaction_hash VARCHAR(100) NOT NULL,
    symbol VARCHAR(20),
    amount DECIMAL(30,8),
    amount_usd DECIMAL(20,2),
    from_address VARCHAR(100),
    to_address VARCHAR(100),
    from_owner VARCHAR(100),
    to_owner VARCHAR(100),
    transaction_type VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_tx_hash (transaction_hash),
    INDEX idx_symbol_amount (symbol, amount_usd),
    INDEX idx_timestamp (timestamp)
);
EOF

# Create views SQL
cat > create_views.sql << 'EOF'
-- Crypto Data Views
USE crypto_data;

-- Latest prices view
CREATE OR REPLACE VIEW latest_prices AS
SELECT DISTINCT
    symbol,
    FIRST_VALUE(price) OVER (PARTITION BY symbol ORDER BY timestamp DESC) as current_price,
    FIRST_VALUE(volume_24h) OVER (PARTITION BY symbol ORDER BY timestamp DESC) as volume_24h,
    FIRST_VALUE(market_cap) OVER (PARTITION BY symbol ORDER BY timestamp DESC) as market_cap,
    FIRST_VALUE(price_change_24h) OVER (PARTITION BY symbol ORDER BY timestamp DESC) as price_change_24h,
    FIRST_VALUE(price_change_7d) OVER (PARTITION BY symbol ORDER BY timestamp DESC) as price_change_7d,
    FIRST_VALUE(timestamp) OVER (PARTITION BY symbol ORDER BY timestamp DESC) as last_updated
FROM price_data;

-- Top cryptocurrencies by market cap
CREATE OR REPLACE VIEW top_cryptos AS
SELECT symbol, current_price, market_cap, volume_24h, price_change_24h,
       RANK() OVER (ORDER BY market_cap DESC) as market_cap_rank
FROM latest_prices
WHERE market_cap > 0
ORDER BY market_cap DESC
LIMIT 100;

-- DeFi protocol rankings
CREATE OR REPLACE VIEW top_defi_protocols AS
SELECT DISTINCT
    protocol_name,
    category,
    blockchain,
    FIRST_VALUE(tvl_usd) OVER (PARTITION BY protocol_name ORDER BY timestamp DESC) as current_tvl,
    FIRST_VALUE(volume_24h) OVER (PARTITION BY protocol_name ORDER BY timestamp DESC) as volume_24h,
    FIRST_VALUE(fees_24h) OVER (PARTITION BY protocol_name ORDER BY timestamp DESC) as fees_24h,
    RANK() OVER (ORDER BY FIRST_VALUE(tvl_usd) OVER (PARTITION BY protocol_name ORDER BY timestamp DESC) DESC) as tvl_rank
FROM defi_protocols
WHERE tvl_usd > 0;

-- Recent whale transactions
CREATE OR REPLACE VIEW recent_whale_activity AS
SELECT blockchain, symbol, amount_usd, from_owner, to_owner, 
       transaction_type, timestamp,
       CASE 
         WHEN amount_usd > 50000000 THEN 'Mega Whale'
         WHEN amount_usd > 10000000 THEN 'Large Whale'
         WHEN amount_usd > 1000000 THEN 'Whale'
         ELSE 'Large Transaction'
       END as whale_category
FROM whale_transactions
WHERE timestamp > DATE_SUB(NOW(), INTERVAL 24 HOUR)
ORDER BY amount_usd DESC;

-- Market overview
CREATE OR REPLACE VIEW market_overview AS
SELECT 
    COUNT(DISTINCT symbol) as total_cryptocurrencies,
    SUM(market_cap) as total_market_cap,
    SUM(volume_24h) as total_volume_24h,
    AVG(price_change_24h) as avg_price_change_24h,
    COUNT(CASE WHEN price_change_24h > 0 THEN 1 END) as gainers_count,
    COUNT(CASE WHEN price_change_24h < 0 THEN 1 END) as losers_count
FROM latest_prices
WHERE market_cap > 1000000;
EOF

# Execute setup
execute_setup() {
    echo "Creating crypto data database and tables..."
    
    # Execute SQL commands
    if command -v mysql &> /dev/null; then
        mysql -u root -p < create_database.sql
        mysql -u root -p < create_views.sql
        echo "✅ Crypto data database created successfully"
    elif command -v mindsdb &> /dev/null; then
        mindsdb -f create_database.sql
        mindsdb -f create_views.sql
        echo "✅ Crypto data database created via MindsDB"
    else
        echo "⚠️  Neither MySQL nor MindsDB CLI found. SQL files created for manual execution."
    fi
}

# Validation
validate_setup() {
    echo "Validating crypto data database setup..."
    
    cat > validate.sql << 'EOF'
-- Validation queries
USE crypto_data;
SHOW TABLES;
DESCRIBE price_data;
DESCRIBE defi_protocols;
SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = 'crypto_data';
EOF
    
    if command -v mysql &> /dev/null; then
        mysql -u root -p < validate.sql
        echo "✅ Validation completed"
    elif command -v mindsdb &> /dev/null; then
        mindsdb -f validate.sql
        echo "✅ Validation completed via MindsDB"
    else
        echo "⚠️  Manual validation required"
    fi
}

# Main execution
main() {
    execute_setup
    validate_setup
    echo "🎉 Crypto data database setup completed!"
}

main "$@"
