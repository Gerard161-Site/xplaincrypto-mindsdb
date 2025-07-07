-- DeFiLlama Database Connection for XplainCrypto
-- Purpose: Connect to DeFiLlama API for DeFi protocol data
-- Documentation: https://docs.mindsdb.com/mindsdb_sql/sql/create/database
-- API Info: DeFiLlama provides public APIs for DeFi data (no authentication required)

-- Create DeFiLlama database connection
-- Note: DeFiLlama APIs are public and don't require API keys
CREATE DATABASE IF NOT EXISTS defillama_db
WITH ENGINE = 'defillama',
PARAMETERS = {
    "base_url": "https://api.llama.fi"
};

-- Verify the connection was created successfully
SELECT * FROM information_schema.databases WHERE name = 'defillama_db';

-- Test the connection (uncomment to test after deployment)
-- This query should return protocol information if the connection works
-- SELECT protocol, tvl, category FROM defillama_db.protocols LIMIT 5; 