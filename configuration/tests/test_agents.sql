
-- XplainCrypto AI Agents Test Suite
-- Purpose: Comprehensive testing of all AI agents and models
-- Execute AFTER deploying AI agents
-- Expected execution time: 3-5 minutes

-- ============================================================================
-- AI AGENTS TEST SUITE
-- ============================================================================

-- Test 1: List all AI agents/models
SELECT '=== AI AGENTS TEST SUITE ===' as test_suite;
SELECT 'Test 1: AI Agents Inventory' as test_name;
SELECT name, engine, status, creation_date, training_log
FROM information_schema.models
WHERE name LIKE '%_agent'
ORDER BY name;

-- Test 2: Crypto Prediction Agent Status
SELECT 'Test 2: Crypto Prediction Agent Status' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'crypto_prediction_agent')
        THEN 'PASS: crypto_prediction_agent exists'
        ELSE 'FAIL: crypto_prediction_agent missing'
    END as prediction_agent_status;

-- Test 3: Market Analysis Agent Status
SELECT 'Test 3: Market Analysis Agent Status' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'market_analysis_agent')
        THEN 'PASS: market_analysis_agent exists'
        ELSE 'FAIL: market_analysis_agent missing'
    END as analysis_agent_status;

-- Test 4: Risk Assessment Agent Status
SELECT 'Test 4: Risk Assessment Agent Status' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'risk_assessment_agent')
        THEN 'PASS: risk_assessment_agent exists'
        ELSE 'FAIL: risk_assessment_agent missing'
    END as risk_agent_status;

-- Test 5: Sentiment Analysis Agent Status
SELECT 'Test 5: Sentiment Analysis Agent Status' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'sentiment_analysis_agent')
        THEN 'PASS: sentiment_analysis_agent exists'
        ELSE 'FAIL: sentiment_analysis_agent missing'
    END as sentiment_agent_status;

-- Test 6: Anomaly Detection Agent Status
SELECT 'Test 6: Anomaly Detection Agent Status' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'anomaly_detection_agent')
        THEN 'PASS: anomaly_detection_agent exists'
        ELSE 'FAIL: anomaly_detection_agent missing'
    END as anomaly_agent_status;

-- Test 7: Master Intelligence Agent Status
SELECT 'Test 7: Master Intelligence Agent Status' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'master_intelligence_agent')
        THEN 'PASS: master_intelligence_agent exists'
        ELSE 'FAIL: master_intelligence_agent missing'
    END as master_agent_status;

-- Test 8: Agent Training Status Check
SELECT 'Test 8: Agent Training Status' as test_name;
SELECT name, status,
    CASE 
        WHEN status = 'complete' THEN 'READY'
        WHEN status = 'training' THEN 'TRAINING (Wait 1-2 minutes)'
        WHEN status = 'error' THEN 'ERROR - Check logs'
        ELSE 'UNKNOWN STATUS'
    END as training_status
FROM information_schema.models
WHERE name LIKE '%_agent'
ORDER BY name;

-- Test 9: Agent Engine Dependencies Check
SELECT 'Test 9: Agent Engine Dependencies' as test_name;
SELECT m.name as agent_name, m.engine as required_engine,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.ml_engines e WHERE e.name = m.engine)
        THEN 'ENGINE AVAILABLE'
        ELSE 'ENGINE MISSING'
    END as engine_status
FROM information_schema.models m
WHERE m.name LIKE '%_agent'
ORDER BY m.name;

-- ============================================================================
-- BASIC FUNCTIONALITY TESTS (Optional - Uncomment to test)
-- Note: These tests make actual API calls and may take 1-2 minutes each
-- ============================================================================

-- Market Analysis Agent Functionality Test
-- Uncomment to test market analysis agent:
/*
SELECT 'Market Analysis Agent Test' as test_name;
SELECT analysis 
FROM market_analysis_agent 
WHERE symbol = 'BTC' 
AND price = 45000 
AND change_24h = 2.5 
AND volume = 25000000000 
AND market_cap = 850000000000 
AND context = 'Test analysis request';
*/

-- Risk Assessment Agent Functionality Test
-- Uncomment to test risk assessment agent:
/*
SELECT 'Risk Assessment Agent Test' as test_name;
SELECT risk_analysis 
FROM risk_assessment_agent 
WHERE symbol = 'ETH' 
AND price = 2500 
AND position_size = 10000 
AND market_data = 'Volatile market conditions' 
AND portfolio_context = 'Diversified crypto portfolio';
*/

-- Sentiment Analysis Agent Functionality Test
-- Uncomment to test sentiment analysis agent:
/*
SELECT 'Sentiment Analysis Agent Test' as test_name;
SELECT sentiment_score 
FROM sentiment_analysis_agent 
WHERE symbol = 'BTC' 
AND news_data = 'Bitcoin adoption increasing' 
AND social_data = 'Positive social media sentiment' 
AND volume_data = 'High trading volume' 
AND price_action = 'Upward trend';
*/

-- Test 10: Agent Error Check
SELECT 'Test 10: Agent Error Check' as test_name;
SELECT name, status, training_log,
    CASE 
        WHEN status = 'error' THEN 'ERROR - Review training_log'
        WHEN training_log LIKE '%error%' THEN 'WARNING - Check training_log'
        ELSE 'NO ERRORS DETECTED'
    END as error_status
FROM information_schema.models
WHERE name LIKE '%_agent'
ORDER BY name;

-- Test 11: Agents Summary
SELECT 'Test 11: Agents Summary' as test_name;
SELECT 
    COUNT(*) as total_agents,
    COUNT(CASE WHEN status = 'complete' THEN 1 END) as ready_agents,
    COUNT(CASE WHEN status = 'training' THEN 1 END) as training_agents,
    COUNT(CASE WHEN status = 'error' THEN 1 END) as error_agents
FROM information_schema.models
WHERE name LIKE '%_agent';

-- Test 12: Agent Capabilities Summary
SELECT 'Test 12: Agent Capabilities Summary' as test_name;
SELECT 
    'crypto_prediction_agent' as agent,
    'TimeGPT time-series forecasting' as capability,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'crypto_prediction_agent' AND status = 'complete') 
         THEN 'READY' ELSE 'NOT READY' END as status
UNION ALL
SELECT 
    'market_analysis_agent' as agent,
    'Claude market analysis' as capability,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'market_analysis_agent' AND status = 'complete') 
         THEN 'READY' ELSE 'NOT READY' END as status
UNION ALL
SELECT 
    'risk_assessment_agent' as agent,
    'GPT-4 risk assessment' as capability,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'risk_assessment_agent' AND status = 'complete') 
         THEN 'READY' ELSE 'NOT READY' END as status
UNION ALL
SELECT 
    'sentiment_analysis_agent' as agent,
    'GPT-4 sentiment analysis' as capability,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'sentiment_analysis_agent' AND status = 'complete') 
         THEN 'READY' ELSE 'NOT READY' END as status
UNION ALL
SELECT 
    'anomaly_detection_agent' as agent,
    'Claude anomaly detection' as capability,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'anomaly_detection_agent' AND status = 'complete') 
         THEN 'READY' ELSE 'NOT READY' END as status
UNION ALL
SELECT 
    'master_intelligence_agent' as agent,
    'Claude Opus orchestration' as capability,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'master_intelligence_agent' AND status = 'complete') 
         THEN 'READY' ELSE 'NOT READY' END as status;

-- ============================================================================
-- TEST RESULTS INTERPRETATION
-- ============================================================================

SELECT '=== TEST RESULTS SUMMARY ===' as summary;
SELECT 
    'Agent Tests Complete' as status,
    NOW() as test_timestamp,
    'Review results above for any FAIL, ERROR, or NOT READY status' as next_action;

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- PASS Results Expected:
-- - All 6 agents should exist: crypto_prediction_agent, market_analysis_agent, 
--   risk_assessment_agent, sentiment_analysis_agent, anomaly_detection_agent, 
--   master_intelligence_agent
--
-- Training Status:
-- - 'complete': Agent is ready to use (expected final state)
-- - 'training': Agent is still being created (wait 1-2 minutes and re-test)
-- - 'error': Agent creation failed (check engine dependencies and API keys)
--
-- Engine Dependencies:
-- - All required engines should show 'ENGINE AVAILABLE'
-- - Missing engines will prevent agent functionality
--
-- FAIL/ERROR Results (Action Required):
-- - Missing agents: Re-run agent creation script
-- - Training errors: Check AI engine status and API key validity
-- - Engine missing: Ensure all AI engines were created successfully
--
-- Troubleshooting:
-- - If agents stuck in 'training': Wait 2-3 minutes, some models take time
-- - If 'error' status: Check training_log for specific error messages
-- - If engine missing: Re-run the AI engines deployment script
-- ============================================================================
