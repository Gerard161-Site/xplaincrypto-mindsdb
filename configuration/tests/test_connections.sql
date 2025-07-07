
-- XplainCrypto Database Connections Test Suite
-- Purpose: Comprehensive testing of all database connections
-- Execute AFTER deploying database connections
-- Expected execution time: 1-2 minutes

-- ============================================================================
-- DATABASE CONNECTIONS TEST SUITE
-- ============================================================================

-- Test 1: List all connected databases
SELECT '=== DATABASE CONNECTIONS TEST SUITE ===' as test_suite;
SELECT 'Test 1: Database Inventory' as test_name;
SELECT name, engine, creation_date, connection_data
FROM information_schema.databases 
WHERE name NOT IN ('information_schema', 'mindsdb', 'files')
ORDER BY name;

-- Test 2: PostgreSQL Connection Test
SELECT 'Test 2: PostgreSQL Connection' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'crypto_data_db')
        THEN 'PASS: crypto_data_db connection exists'
        ELSE 'FAIL: crypto_data_db connection missing'
    END as postgres_connection_status;

-- Test PostgreSQL connectivity (if connection exists)
-- Uncomment to test actual connectivity:
/*
SELECT 'PostgreSQL Connectivity Test' as test_name;
SELECT COUNT(*) as table_count 
FROM crypto_data_db.information_schema.tables;
*/

-- Test 3: CoinMarketCap API Connection Test
SELECT 'Test 3: CoinMarketCap API Connection' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'coinmarketcap_db')
        THEN 'PASS: coinmarketcap_db connection exists'
        ELSE 'FAIL: coinmarketcap_db connection missing'
    END as coinmarketcap_connection_status;

-- Test CoinMarketCap API connectivity (if connection exists)
-- Uncomment to test actual API connectivity:
/*
SELECT 'CoinMarketCap API Test' as test_name;
SELECT name, symbol, price 
FROM coinmarketcap_db.listings 
LIMIT 3;
*/

-- Test 4: DeFiLlama Public API Connection Test
SELECT 'Test 4: DeFiLlama API Connection' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'defillama_db')
        THEN 'PASS: defillama_db connection exists'
        ELSE 'FAIL: defillama_db connection missing'
    END as defillama_connection_status;

-- Test DeFiLlama API connectivity (if connection exists)
-- Uncomment to test actual API connectivity:
/*
SELECT 'DeFiLlama API Test' as test_name;
SELECT protocol, tvl, category 
FROM defillama_db.protocols 
LIMIT 3;
*/

-- Test 5: Blockchain.info Public API Connection Test
SELECT 'Test 5: Blockchain.info API Connection' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'blockchain_db')
        THEN 'PASS: blockchain_db connection exists'
        ELSE 'FAIL: blockchain_db connection missing'
    END as blockchain_connection_status;

-- Test 6: Dune Analytics API Connection Test
SELECT 'Test 6: Dune Analytics API Connection' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'dune_db')
        THEN 'PASS: dune_db connection exists'
        ELSE 'FAIL: dune_db connection missing'
    END as dune_connection_status;

-- Test 7: Whale Alert API Connection Test (Optional)
SELECT 'Test 7: Whale Alert API Connection' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'whale_alerts_db')
        THEN 'PASS: whale_alerts_db connection exists'
        ELSE 'INFO: whale_alerts_db not configured (optional)'
    END as whale_alerts_connection_status;

-- Test 8: Connection Summary and Health Check
SELECT 'Test 8: Connection Summary' as test_name;
SELECT 
    COUNT(*) as total_external_databases,
    COUNT(CASE WHEN name LIKE '%_db' THEN 1 END) as xplaincrypto_databases,
    COUNT(CASE WHEN engine = 'postgres' THEN 1 END) as postgres_connections,
    COUNT(CASE WHEN engine IN ('coinmarketcap', 'defillama', 'blockchain', 'dune', 'whale_alert') THEN 1 END) as api_connections
FROM information_schema.databases
WHERE name NOT IN ('information_schema', 'mindsdb', 'files');

-- Test 9: Connection Error Check
SELECT 'Test 9: Connection Error Check' as test_name;
SELECT name, engine, 
    CASE 
        WHEN connection_data LIKE '%error%' THEN 'ERROR DETECTED'
        ELSE 'OK'
    END as connection_health
FROM information_schema.databases 
WHERE name LIKE '%_db'
ORDER BY name;

-- ============================================================================
-- TEST RESULTS INTERPRETATION
-- ============================================================================

SELECT '=== TEST RESULTS SUMMARY ===' as summary;
SELECT 
    'Connection Tests Complete' as status,
    NOW() as test_timestamp,
    'Review results above for any FAIL status' as next_action;

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- PASS Results Expected:
-- - crypto_data_db (PostgreSQL): Should exist if PostgreSQL is configured
-- - coinmarketcap_db: Should exist if CoinMarketCap API key is valid
-- - defillama_db: Should exist (public API, no key required)
-- - blockchain_db: Should exist (public API, no key required)
-- - dune_db: Should exist if Dune Analytics API key is valid
--
-- INFO Results (Optional):
-- - whale_alerts_db: Optional connection, INFO status is acceptable
--
-- FAIL Results (Action Required):
-- - Any FAIL status indicates connection issues that need resolution
-- - Check API keys, network connectivity, and service availability
-- - Review troubleshooting guide for specific solutions
-- ============================================================================
