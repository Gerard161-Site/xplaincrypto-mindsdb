
-- XplainCrypto Database Connections Setup
-- Purpose: Create all external database connections for crypto data
-- Execute AFTER health check passes
-- Expected execution time: 2-3 minutes

-- ============================================================================
-- DATABASE CONNECTIONS SCRIPT
-- IMPORTANT: Replace ALL ${VARIABLE} placeholders with your actual API keys
-- ============================================================================

-- PostgreSQL Connection for Historical Data
-- Replace ${POSTGRES_PASSWORD} with your actual PostgreSQL password
CREATE DATABASE IF NOT EXISTS crypto_data_datasource
WITH ENGINE = 'postgres',
PARAMETERS = {
    "host": "localhost",
    "port": 5432,
    "database": "crypto_data",
    "user": "mindsdb",
    "password": "${POSTGRES_PASSWORD}"
};

-- CoinMarketCap API Connection
-- Replace ${COINMARKETCAP_API_KEY} with your actual CoinMarketCap API key
-- Get your key from: https://coinmarketcap.com/api/
CREATE DATABASE IF NOT EXISTS coinmarketcap_datasource
WITH ENGINE = 'coinmarketcap',
PARAMETERS = {
    "api_key": "${COINMARKETCAP_API_KEY}"
};

-- DeFiLlama Public API Connection (no API key required)
CREATE DATABASE IF NOT EXISTS defillama_datasource
WITH ENGINE = 'defillama',
PARAMETERS = {
    "base_url": "https://api.llama.fi"
};

-- Blockchain.info Public API Connection (no API key required)
CREATE DATABASE IF NOT EXISTS blockchain_datasource
WITH ENGINE = 'blockchain',
PARAMETERS = {
    "base_url": "https://blockchain.info"
};

-- Dune Analytics API Connection
-- Replace ${DUNE_API_KEY} with your actual Dune Analytics API key
-- Get your key from: https://dune.com/settings/api
CREATE DATABASE IF NOT EXISTS dune_datasource
WITH ENGINE = 'dune',
PARAMETERS = {
    "api_key": "${DUNE_API_KEY}"
};

-- Whale Alert API Connection (if you have a key)
-- Replace ${WHALE_ALERT_API_KEY} with your actual Whale Alert API key
-- Comment out this section if you don't have a Whale Alert API key
/*
CREATE DATABASE IF NOT EXISTS whale_alerts_datasource
WITH ENGINE = 'whale_alert',
PARAMETERS = {
    "api_key": "${WHALE_ALERT_API_KEY}"
};
*/

-- ============================================================================
-- VERIFICATION QUERIES - Execute these to verify connections
-- ============================================================================

-- List all created databases
SELECT 'Database Creation Verification' as check_name;
SELECT name, engine, creation_date 
FROM information_schema.databases 
WHERE name LIKE '%_db'
ORDER BY name;

-- Verify specific connections
SELECT 'Connection Status Check' as check_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'crypto_data_db')
        THEN 'CREATED: crypto_data_db (PostgreSQL)'
        ELSE 'MISSING: crypto_data_db'
    END as postgres_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'coinmarketcap_db')
        THEN 'CREATED: coinmarketcap_db (CoinMarketCap API)'
        ELSE 'MISSING: coinmarketcap_db'
    END as coinmarketcap_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'defillama_db')
        THEN 'CREATED: defillama_db (DeFiLlama API)'
        ELSE 'MISSING: defillama_db'
    END as defillama_status;

-- ============================================================================
-- TROUBLESHOOTING:
-- ============================================================================
-- If connections fail:
-- 1. Verify API keys are correct and active
-- 2. Check network connectivity to external APIs
-- 3. Ensure PostgreSQL is running and accessible
-- 4. Review MindsDB logs for detailed error messages
-- 5. Test individual connections using the test scripts
--
-- All connections use IF NOT EXISTS - safe to re-run this script
-- ============================================================================
