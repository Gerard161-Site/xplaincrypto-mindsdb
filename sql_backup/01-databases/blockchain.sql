-- Blockchain.info Database Connection for XplainCrypto
-- Purpose: Connect to Blockchain.info API for Bitcoin blockchain data
-- Documentation: https://docs.mindsdb.com/mindsdb_sql/sql/create/database
-- API Info: Blockchain.info provides public APIs (no authentication required)

-- Create Blockchain.info database connection
-- Note: Most Blockchain.info endpoints are public and don't require API keys
CREATE DATABASE IF NOT EXISTS blockchain_db
WITH ENGINE = 'blockchain',
PARAMETERS = {
    "base_url": "https://api.blockchain.info"
};

-- Verify the connection was created successfully
SELECT * FROM information_schema.databases WHERE name = 'blockchain_db';

-- Test the connection (uncomment to test after deployment)
-- This query should return Bitcoin statistics if the connection works
-- SELECT difficulty, hash_rate FROM blockchain_db.stats LIMIT 1; 