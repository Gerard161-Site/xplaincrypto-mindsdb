
-- XplainCrypto Complete System Test Suite
-- Purpose: End-to-end testing of the entire XplainCrypto MindsDB deployment
-- Execute AFTER all deployment scripts and individual tests
-- Expected execution time: 2-3 minutes

-- ============================================================================
-- COMPLETE SYSTEM TEST SUITE
-- ============================================================================

-- Test 1: System Overview
SELECT '=== XPLAINCRYPTO COMPLETE SYSTEM TEST ===' as test_suite;
SELECT 'Test 1: System Overview' as test_name;
SELECT 
    'XplainCrypto MindsDB Deployment' as system_name,
    version() as mindsdb_version,
    NOW() as test_timestamp;

-- Test 2: Database Connections Summary
SELECT 'Test 2: Database Connections Summary' as test_name;
SELECT 
    COUNT(*) as total_databases,
    COUNT(CASE WHEN name LIKE '%_db' THEN 1 END) as crypto_databases,
    COUNT(CASE WHEN engine = 'postgres' THEN 1 END) as postgres_connections,
    COUNT(CASE WHEN engine IN ('coinmarketcap', 'defillama', 'blockchain', 'dune') THEN 1 END) as api_connections
FROM information_schema.databases
WHERE name NOT IN ('information_schema', 'mindsdb', 'files');

-- Test 3: AI Engines Summary
SELECT 'Test 3: AI Engines Summary' as test_name;
SELECT 
    COUNT(*) as total_engines,
    COUNT(CASE WHEN name = 'openai_engine' THEN 1 END) as openai_available,
    COUNT(CASE WHEN name = 'anthropic_engine' THEN 1 END) as anthropic_available,
    COUNT(CASE WHEN name = 'timegpt_engine' THEN 1 END) as timegpt_available
FROM information_schema.ml_engines;

-- Test 4: AI Agents Summary
SELECT 'Test 4: AI Agents Summary' as test_name;
SELECT 
    COUNT(*) as total_agents,
    COUNT(CASE WHEN status = 'complete' THEN 1 END) as ready_agents,
    COUNT(CASE WHEN status = 'training' THEN 1 END) as training_agents,
    COUNT(CASE WHEN status = 'error' THEN 1 END) as error_agents
FROM information_schema.models
WHERE name LIKE '%_agent';

-- Test 5: Critical Components Check
SELECT 'Test 5: Critical Components Check' as test_name;
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'crypto_data_db') 
         THEN 'PASS' ELSE 'FAIL' END as postgres_connection,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'coinmarketcap_db') 
         THEN 'PASS' ELSE 'FAIL' END as coinmarketcap_api,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.ml_engines WHERE name = 'openai_engine') 
         THEN 'PASS' ELSE 'FAIL' END as openai_engine,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.ml_engines WHERE name = 'anthropic_engine') 
         THEN 'PASS' ELSE 'FAIL' END as anthropic_engine,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'master_intelligence_agent' AND status = 'complete') 
         THEN 'PASS' ELSE 'FAIL' END as master_agent;

-- Test 6: Data Pipeline Readiness
SELECT 'Test 6: Data Pipeline Readiness' as test_name;
SELECT 
    'Data Sources' as component,
    CASE WHEN (SELECT COUNT(*) FROM information_schema.databases WHERE name LIKE '%_db') >= 3
         THEN 'READY' ELSE 'INCOMPLETE' END as status
UNION ALL
SELECT 
    'AI Engines' as component,
    CASE WHEN (SELECT COUNT(*) FROM information_schema.ml_engines) >= 2
         THEN 'READY' ELSE 'INCOMPLETE' END as status
UNION ALL
SELECT 
    'AI Agents' as component,
    CASE WHEN (SELECT COUNT(*) FROM information_schema.models WHERE name LIKE '%_agent' AND status = 'complete') >= 4
         THEN 'READY' ELSE 'INCOMPLETE' END as status;

-- Test 7: System Capabilities Inventory
SELECT 'Test 7: System Capabilities Inventory' as test_name;
SELECT 
    'Price Forecasting' as capability,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'crypto_prediction_agent' AND status = 'complete')
         THEN 'AVAILABLE' ELSE 'UNAVAILABLE' END as status
UNION ALL
SELECT 
    'Market Analysis' as capability,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'market_analysis_agent' AND status = 'complete')
         THEN 'AVAILABLE' ELSE 'UNAVAILABLE' END as status
UNION ALL
SELECT 
    'Risk Assessment' as capability,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'risk_assessment_agent' AND status = 'complete')
         THEN 'AVAILABLE' ELSE 'UNAVAILABLE' END as status
UNION ALL
SELECT 
    'Sentiment Analysis' as capability,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'sentiment_analysis_agent' AND status = 'complete')
         THEN 'AVAILABLE' ELSE 'UNAVAILABLE' END as status
UNION ALL
SELECT 
    'Anomaly Detection' as capability,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'anomaly_detection_agent' AND status = 'complete')
         THEN 'AVAILABLE' ELSE 'UNAVAILABLE' END as status
UNION ALL
SELECT 
    'Master Intelligence' as capability,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'master_intelligence_agent' AND status = 'complete')
         THEN 'AVAILABLE' ELSE 'UNAVAILABLE' END as status;

-- Test 8: Error Detection Scan
SELECT 'Test 8: Error Detection Scan' as test_name;
SELECT 
    'Database Connections' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE connection_data LIKE '%error%')
         THEN 'ERRORS DETECTED' ELSE 'NO ERRORS' END as error_status
UNION ALL
SELECT 
    'ML Engines' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.ml_engines WHERE connection_data LIKE '%error%')
         THEN 'ERRORS DETECTED' ELSE 'NO ERRORS' END as error_status
UNION ALL
SELECT 
    'AI Agents' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name LIKE '%_agent' AND status = 'error')
         THEN 'ERRORS DETECTED' ELSE 'NO ERRORS' END as error_status;

-- Test 9: Deployment Completeness Score
SELECT 'Test 9: Deployment Completeness Score' as test_name;
SELECT 
    ROUND(
        (
            (SELECT COUNT(*) FROM information_schema.databases WHERE name LIKE '%_db') * 15 +
            (SELECT COUNT(*) FROM information_schema.ml_engines) * 25 +
            (SELECT COUNT(*) FROM information_schema.models WHERE name LIKE '%_agent' AND status = 'complete') * 10
        ) / 1.0, 0
    ) as completeness_score,
    CASE 
        WHEN (
            (SELECT COUNT(*) FROM information_schema.databases WHERE name LIKE '%_db') >= 4 AND
            (SELECT COUNT(*) FROM information_schema.ml_engines) >= 3 AND
            (SELECT COUNT(*) FROM information_schema.models WHERE name LIKE '%_agent' AND status = 'complete') >= 5
        ) THEN 'EXCELLENT (90-100%)'
        WHEN (
            (SELECT COUNT(*) FROM information_schema.databases WHERE name LIKE '%_db') >= 3 AND
            (SELECT COUNT(*) FROM information_schema.ml_engines) >= 2 AND
            (SELECT COUNT(*) FROM information_schema.models WHERE name LIKE '%_agent' AND status = 'complete') >= 4
        ) THEN 'GOOD (70-89%)'
        WHEN (
            (SELECT COUNT(*) FROM information_schema.databases WHERE name LIKE '%_db') >= 2 AND
            (SELECT COUNT(*) FROM information_schema.ml_engines) >= 1 AND
            (SELECT COUNT(*) FROM information_schema.models WHERE name LIKE '%_agent' AND status = 'complete') >= 2
        ) THEN 'FAIR (50-69%)'
        ELSE 'NEEDS IMPROVEMENT (<50%)'
    END as deployment_grade;

-- Test 10: Production Readiness Assessment
SELECT 'Test 10: Production Readiness Assessment' as test_name;
SELECT 
    CASE 
        WHEN (
            EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'crypto_data_db') AND
            EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'coinmarketcap_db') AND
            EXISTS (SELECT 1 FROM information_schema.ml_engines WHERE name = 'openai_engine') AND
            EXISTS (SELECT 1 FROM information_schema.ml_engines WHERE name = 'anthropic_engine') AND
            (SELECT COUNT(*) FROM information_schema.models WHERE name LIKE '%_agent' AND status = 'complete') >= 4
        ) THEN 'PRODUCTION READY'
        WHEN (
            (SELECT COUNT(*) FROM information_schema.databases WHERE name LIKE '%_db') >= 2 AND
            (SELECT COUNT(*) FROM information_schema.ml_engines) >= 2 AND
            (SELECT COUNT(*) FROM information_schema.models WHERE name LIKE '%_agent' AND status = 'complete') >= 3
        ) THEN 'DEVELOPMENT READY'
        ELSE 'INCOMPLETE DEPLOYMENT'
    END as readiness_status,
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'crypto_data_db')
        THEN 'Missing PostgreSQL connection'
        WHEN NOT EXISTS (SELECT 1 FROM information_schema.ml_engines WHERE name = 'openai_engine')
        THEN 'Missing OpenAI engine'
        WHEN (SELECT COUNT(*) FROM information_schema.models WHERE name LIKE '%_agent' AND status = 'complete') < 3
        THEN 'Insufficient AI agents ready'
        ELSE 'All critical components available'
    END as primary_blocker;

-- ============================================================================
-- FINAL SYSTEM STATUS
-- ============================================================================

SELECT '=== FINAL SYSTEM STATUS ===' as final_status;
SELECT 
    'XplainCrypto MindsDB Deployment Test Complete' as message,
    NOW() as completion_time,
    CASE 
        WHEN (
            (SELECT COUNT(*) FROM information_schema.databases WHERE name LIKE '%_db') >= 3 AND
            (SELECT COUNT(*) FROM information_schema.ml_engines) >= 2 AND
            (SELECT COUNT(*) FROM information_schema.models WHERE name LIKE '%_agent' AND status = 'complete') >= 4
        ) THEN '✅ DEPLOYMENT SUCCESSFUL - Ready for use!'
        WHEN (
            (SELECT COUNT(*) FROM information_schema.databases WHERE name LIKE '%_db') >= 2 AND
            (SELECT COUNT(*) FROM information_schema.ml_engines) >= 1 AND
            (SELECT COUNT(*) FROM information_schema.models WHERE name LIKE '%_agent' AND status = 'complete') >= 2
        ) THEN '⚠️ PARTIAL DEPLOYMENT - Some components need attention'
        ELSE '❌ DEPLOYMENT INCOMPLETE - Review troubleshooting guide'
    END as overall_status;

-- ============================================================================
-- NEXT STEPS RECOMMENDATIONS
-- ============================================================================

SELECT '=== NEXT STEPS RECOMMENDATIONS ===' as recommendations;
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.models WHERE name LIKE '%_agent' AND status = 'training') > 0
        THEN '1. Wait for agent training to complete (check in 2-3 minutes)'
        WHEN (SELECT COUNT(*) FROM information_schema.models WHERE name LIKE '%_agent' AND status = 'error') > 0
        THEN '1. Fix agent errors - check troubleshooting guide'
        WHEN (SELECT COUNT(*) FROM information_schema.ml_engines) < 3
        THEN '1. Complete AI engine setup - check API keys'
        WHEN (SELECT COUNT(*) FROM information_schema.databases WHERE name LIKE '%_db') < 3
        THEN '1. Complete database connections - check API keys'
        ELSE '1. System ready - proceed with automation setup'
    END as step_1,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.models WHERE name LIKE '%_agent' AND status = 'complete') >= 4
        THEN '2. Test individual agent functionality'
        ELSE '2. Complete agent deployment first'
    END as step_2,
    CASE 
        WHEN (
            (SELECT COUNT(*) FROM information_schema.databases WHERE name LIKE '%_db') >= 3 AND
            (SELECT COUNT(*) FROM information_schema.ml_engines) >= 2 AND
            (SELECT COUNT(*) FROM information_schema.models WHERE name LIKE '%_agent' AND status = 'complete') >= 4
        ) THEN '3. Ready for automation phase!'
        ELSE '3. Complete manual deployment first'
    END as step_3;

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- EXCELLENT DEPLOYMENT (90-100%):
-- - 4+ database connections (postgres, coinmarketcap, defillama, blockchain)
-- - 3 AI engines (openai, anthropic, timegpt)
-- - 5+ AI agents in 'complete' status
-- - All capabilities show 'AVAILABLE'
-- - Production ready status
--
-- GOOD DEPLOYMENT (70-89%):
-- - 3+ database connections
-- - 2+ AI engines
-- - 4+ AI agents in 'complete' status
-- - Most capabilities available
-- - Development ready status
--
-- NEEDS IMPROVEMENT (<50%):
-- - Missing critical components
-- - Multiple errors detected
-- - Incomplete deployment status
-- - Review troubleshooting guide required
-- ============================================================================
