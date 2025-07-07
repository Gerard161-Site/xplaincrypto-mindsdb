
-- XplainCrypto AI Engines Setup
-- Purpose: Create all ML engines for AI-powered crypto analysis
-- Execute AFTER database connections are created
-- Expected execution time: 1-2 minutes

-- ============================================================================
-- AI ENGINES SCRIPT
-- IMPORTANT: Replace ALL ${VARIABLE} placeholders with your actual API keys
-- ============================================================================

-- OpenAI Engine for GPT-4 Analysis
-- Replace ${OPENAI_API_KEY} with your actual OpenAI API key
-- Get your key from: https://platform.openai.com/api-keys
CREATE ML_ENGINE IF NOT EXISTS openai_engine
FROM openai
USING
    api_key = '${OPENAI_API_KEY}';

-- Anthropic Engine for Claude Analysis
-- Replace ${ANTHROPIC_API_KEY} with your actual Anthropic API key
-- Get your key from: https://console.anthropic.com/
CREATE ML_ENGINE IF NOT EXISTS anthropic_engine
FROM anthropic
USING
    api_key = '${ANTHROPIC_API_KEY}';

-- TimeGPT Engine for Time Series Forecasting
-- Replace ${TIMEGPT_API_KEY} with your actual TimeGPT API key
-- Get your key from: https://nixtla.io/
CREATE ML_ENGINE IF NOT EXISTS timegpt_engine
FROM timegpt
USING
    api_key = '${TIMEGPT_API_KEY}';

-- ============================================================================
-- VERIFICATION QUERIES - Execute these to verify engines
-- ============================================================================

-- List all created ML engines
SELECT 'ML Engines Verification' as check_name;
SELECT name, handler, creation_date
FROM information_schema.ml_engines
ORDER BY name;

-- Verify specific engines
SELECT 'Engine Status Check' as check_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.ml_engines WHERE name = 'openai_engine')
        THEN 'CREATED: openai_engine (GPT-4 Analysis)'
        ELSE 'MISSING: openai_engine'
    END as openai_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.ml_engines WHERE name = 'anthropic_engine')
        THEN 'CREATED: anthropic_engine (Claude Analysis)'
        ELSE 'MISSING: anthropic_engine'
    END as anthropic_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.ml_engines WHERE name = 'timegpt_engine')
        THEN 'CREATED: timegpt_engine (Time Series Forecasting)'
        ELSE 'MISSING: timegpt_engine'
    END as timegpt_status;

-- Test engine connectivity (optional - may take 30 seconds each)
-- Uncomment these lines to test engine connectivity:
/*
SELECT 'OpenAI Engine Test' as test_name;
SELECT openai_engine('What is Bitcoin?') as openai_test;

SELECT 'Anthropic Engine Test' as test_name;
SELECT anthropic_engine('Explain Ethereum in one sentence') as anthropic_test;
*/

-- ============================================================================
-- TROUBLESHOOTING:
-- ============================================================================
-- If engine creation fails:
-- 1. Verify API keys are correct and have sufficient credits
-- 2. Check API key permissions and rate limits
-- 3. Ensure network connectivity to AI service providers
-- 4. Review MindsDB logs for detailed error messages
-- 5. Test individual engines using the test scripts
--
-- Common Issues:
-- - OpenAI: Ensure you have credits in your account
-- - Anthropic: Verify API key has Claude access
-- - TimeGPT: Check if you have an active subscription
--
-- All engines use IF NOT EXISTS - safe to re-run this script
-- ============================================================================
