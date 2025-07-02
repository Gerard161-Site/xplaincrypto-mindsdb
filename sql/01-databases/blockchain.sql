-- Blockchain.com Database Connection Setup
-- This script creates a database connection to Blockchain.com API
-- Note: Most Blockchain.com endpoints are public, no API key required

CREATE DATABASE blockchain_db
WITH ENGINE = 'blockchain',
PARAMETERS = {
    'base_url': 'https://api.blockchain.info'
}; 