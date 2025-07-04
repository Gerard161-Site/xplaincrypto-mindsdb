-- CoinMarketCap Database Connection for XplainCrypto
-- Purpose: Connect to CoinMarketCap API for comprehensive cryptocurrency data
-- Documentation: https://docs.mindsdb.com/mindsdb_sql/sql/create/database
-- API Info: Requires CoinMarketCap API key from coinmarketcap.com

-- Create CoinMarketCap database connection
-- Security: Uses environment variable substitution for API key
CREATE DATABASE IF NOT EXISTS coinmarketcap_db
WITH ENGINE = 'coinmarketcap',
PARAMETERS = {
    "api_key": "${COINMARKETCAP_API_KEY}"
};

-- Verify the connection was created successfully
SELECT * FROM information_schema.databases WHERE name = 'coinmarketcap_db';

-- Test the connection (uncomment to test after deployment)
-- This query should return cryptocurrency listings if the connection works
-- SELECT name, symbol, price FROM coinmarketcap_db.listings LIMIT 5; 