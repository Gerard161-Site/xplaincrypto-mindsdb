-- XplainCrypto Database Connections Test Suite
-- Purpose: Validate all database connections are working correctly
-- Usage: Run after deploying database connection scripts

-- Test 1: List all connected databases
SELECT 'Database Connections Test' as test_name;
SELECT name, engine, creation_date 
FROM information_schema.databases 
WHERE name NOT IN ('information_schema', 'mindsdb', 'files')
ORDER BY name;

-- Test 2: PostgreSQL Connection Test
SELECT 'PostgreSQL Connection Test' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'crypto_data_db')
        THEN 'PASS: crypto_data_db connected'
        ELSE 'FAIL: crypto_data_db not found'
    END as postgres_status;

-- Test 3: Public API Connections Test (no auth required)
SELECT 'Public API Connections Test' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'defillama_db')
        THEN 'PASS: defillama_db connected'
        ELSE 'FAIL: defillama_db not found'
    END as defillama_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'blockchain_db')
        THEN 'PASS: blockchain_db connected'
        ELSE 'FAIL: blockchain_db not found'
    END as blockchain_status;

-- Test 4: Authenticated API Connections Test
SELECT 'Authenticated API Connections Test' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'coinmarketcap_db')
        THEN 'PASS: coinmarketcap_db connected'
        ELSE 'FAIL: coinmarketcap_db not found'
    END as coinmarketcap_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'dune_db')
        THEN 'PASS: dune_db connected'
        ELSE 'FAIL: dune_db not found'
    END as dune_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'whale_alerts_db')
        THEN 'PASS: whale_alerts_db connected'
        ELSE 'FAIL: whale_alerts_db not found'
    END as whale_alerts_status;

-- Test 5: Connection Summary
SELECT 'Connection Summary' as test_name;
SELECT 
    COUNT(*) as total_databases,
    COUNT(CASE WHEN name LIKE '%_db' THEN 1 END) as xplaincrypto_databases
FROM information_schema.databases; 