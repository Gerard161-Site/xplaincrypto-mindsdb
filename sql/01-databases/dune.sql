-- Dune Analytics Database Connection for XplainCrypto
-- Purpose: Connect to Dune Analytics API for blockchain analytics and custom queries
-- Documentation: https://docs.mindsdb.com/mindsdb_sql/sql/create/database
-- API Info: Requires Dune Analytics API key from dune.com

-- Create Dune Analytics database connection
-- Security: Uses environment variable substitution for API key
CREATE DATABASE IF NOT EXISTS dune_db
WITH ENGINE = 'dune',
PARAMETERS = {
    "api_key": "${DUNE_API_KEY}",
    "base_url": "https://api.dune.com/api/v1"
};

-- Verify the connection was created successfully
SELECT * FROM information_schema.databases WHERE name = 'dune_db';

-- Test the connection (uncomment to test after deployment)
-- This query should return query results if the connection works
-- Note: Requires specific Dune query IDs to test
-- SELECT * FROM dune_db.query_results WHERE query_id = 'your_query_id' LIMIT 5; 