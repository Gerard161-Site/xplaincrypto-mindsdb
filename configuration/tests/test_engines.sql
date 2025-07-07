
-- XplainCrypto AI Engines Test Suite
-- Purpose: Comprehensive testing of all AI/ML engines
-- Execute AFTER deploying AI engines
-- Expected execution time: 2-3 minutes

-- ============================================================================
-- AI ENGINES TEST SUITE
-- ============================================================================

-- Test 1: List all ML engines
SELECT '=== AI ENGINES TEST SUITE ===' as test_suite;
SELECT 'Test 1: ML Engines Inventory' as test_name;
SELECT name, handler, creation_date
FROM information_schema.ml_engines
ORDER BY name;

-- Test 2: OpenAI Engine Status Check
SELECT 'Test 2: OpenAI Engine Status' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.ml_engines WHERE name = 'openai_engine')
        THEN 'PASS: openai_engine exists'
        ELSE 'FAIL: openai_engine missing'
    END as openai_engine_status;

-- Test 3: Anthropic Engine Status Check
SELECT 'Test 3: Anthropic Engine Status' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.ml_engines WHERE name = 'anthropic_engine')
        THEN 'PASS: anthropic_engine exists'
        ELSE 'FAIL: anthropic_engine missing'
    END as anthropic_engine_status;

-- Test 4: TimeGPT Engine Status Check
SELECT 'Test 4: TimeGPT Engine Status' as test_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.ml_engines WHERE name = 'timegpt_engine')
        THEN 'PASS: timegpt_engine exists'
        ELSE 'FAIL: timegpt_engine missing'
    END as timegpt_engine_status;

-- Test 5: Engine Configuration Check
SELECT 'Test 5: Engine Configuration' as test_name;
SELECT name, handler, 
    CASE 
        WHEN connection_data LIKE '%error%' THEN 'ERROR'
        WHEN connection_data IS NOT NULL THEN 'CONFIGURED'
        ELSE 'UNKNOWN'
    END as config_status
FROM information_schema.ml_engines
ORDER BY name;

-- ============================================================================
-- BASIC CONNECTIVITY TESTS (Optional - Uncomment to test)
-- Note: These tests make actual API calls and may take 30-60 seconds each
-- ============================================================================

-- OpenAI Engine Connectivity Test
-- Uncomment to test OpenAI engine connectivity:
/*
SELECT 'OpenAI Engine Connectivity Test' as test_name;
CREATE MODEL test_openai_model
PREDICT response
USING
    engine = 'openai_engine',
    model_name = 'gpt-3.5-turbo',
    prompt_template = 'Say "OpenAI engine is working" in exactly those words.';

SELECT response FROM test_openai_model WHERE text = 'test';
DROP MODEL test_openai_model;
*/

-- Anthropic Engine Connectivity Test
-- Uncomment to test Anthropic engine connectivity:
/*
SELECT 'Anthropic Engine Connectivity Test' as test_name;
CREATE MODEL test_anthropic_model
PREDICT response
USING
    engine = 'anthropic_engine',
    model_name = 'claude-3-haiku-20240307',
    prompt_template = 'Say "Anthropic engine is working" in exactly those words.';

SELECT response FROM test_anthropic_model WHERE text = 'test';
DROP MODEL test_anthropic_model;
*/

-- TimeGPT Engine Connectivity Test
-- Uncomment to test TimeGPT engine connectivity:
/*
SELECT 'TimeGPT Engine Connectivity Test' as test_name;
CREATE MODEL test_timegpt_model
PREDICT forecast
USING
    engine = 'timegpt_engine',
    horizon = 1,
    frequency = 'D';

-- Note: TimeGPT requires time series data to test properly
-- This is a basic configuration test only
*/

-- Test 6: Engine Handler Availability Check
SELECT 'Test 6: Engine Handler Availability' as test_name;
SELECT name, title, import_success,
    CASE 
        WHEN import_success = true THEN 'AVAILABLE'
        ELSE 'UNAVAILABLE'
    END as handler_status
FROM information_schema.handlers 
WHERE type = 'ml' 
AND name IN ('openai', 'anthropic', 'timegpt')
ORDER BY name;

-- Test 7: Engine Creation Errors Check
SELECT 'Test 7: Engine Creation Errors' as test_name;
SELECT name,
    CASE 
        WHEN connection_data LIKE '%error%' OR connection_data LIKE '%fail%' 
        THEN 'ERROR DETECTED - Check API keys and connectivity'
        ELSE 'NO ERRORS DETECTED'
    END as error_status
FROM information_schema.ml_engines
ORDER BY name;

-- Test 8: Engines Summary
SELECT 'Test 8: Engines Summary' as test_name;
SELECT 
    COUNT(*) as total_engines,
    COUNT(CASE WHEN name = 'openai_engine' THEN 1 END) as openai_count,
    COUNT(CASE WHEN name = 'anthropic_engine' THEN 1 END) as anthropic_count,
    COUNT(CASE WHEN name = 'timegpt_engine' THEN 1 END) as timegpt_count
FROM information_schema.ml_engines;

-- ============================================================================
-- TEST RESULTS INTERPRETATION
-- ============================================================================

SELECT '=== TEST RESULTS SUMMARY ===' as summary;
SELECT 
    'Engine Tests Complete' as status,
    NOW() as test_timestamp,
    'Review results above for any FAIL or ERROR status' as next_action;

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- PASS Results Expected:
-- - openai_engine: Should exist if OpenAI API key is valid
-- - anthropic_engine: Should exist if Anthropic API key is valid  
-- - timegpt_engine: Should exist if TimeGPT API key is valid
--
-- Handler Availability:
-- - All handlers (openai, anthropic, timegpt) should show import_success = true
-- - If import_success = false, the handler is not available in this MindsDB instance
--
-- FAIL/ERROR Results (Action Required):
-- - Missing engines: Check API keys and re-run engine creation script
-- - Handler unavailable: Update MindsDB or check handler installation
-- - Connection errors: Verify API keys have sufficient credits and permissions
--
-- Troubleshooting:
-- - OpenAI: Ensure API key has credits and proper permissions
-- - Anthropic: Verify API key has Claude model access
-- - TimeGPT: Check active subscription and API key validity
-- ============================================================================
