-- CoinMarketCap Database Connection Setup
-- This script creates a database connection to CoinMarketCap API

CREATE DATABASE coinmarketcap_db
WITH ENGINE = 'coinmarketcap',
PARAMETERS = {
    'api_key': '${COINMARKETCAP_API_KEY}'
}; 