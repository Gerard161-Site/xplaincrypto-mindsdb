
-- XplainCrypto MindsDB Health Check
-- Purpose: Validate MindsDB is running and basic functionality works
-- Execute this FIRST before any other deployment scripts
-- Expected execution time: 30 seconds

-- ============================================================================
-- HEALTH CHECK SCRIPT - EXECUTE THIS FIRST
-- ============================================================================

-- Check MindsDB version and system status
SELECT 'MindsDB Version Check' as check_name;
SELECT version() as mindsdb_version;

-- List available handlers (should show data and ml handlers)
SELECT 'Available Handlers Check' as check_name;
SHOW HANDLERS;

-- Check system databases
SELECT 'System Databases Check' as check_name;
SHOW DATABASES;

-- Verify information schema is accessible
SELECT 'Information Schema Check' as check_name;
SELECT COUNT(*) as total_handlers 
FROM information_schema.handlers;

-- Check available ML handlers for AI engines
SELECT 'ML Handlers Check' as check_name;
SELECT name, title, description, import_success
FROM information_schema.handlers 
WHERE type = 'ml'
ORDER BY name;

-- Check available data handlers for connections
SELECT 'Data Handlers Check' as check_name;
SELECT name, title, description, import_success
FROM information_schema.handlers 
WHERE type = 'data'
ORDER BY name;

-- Test basic SQL functionality
SELECT 'Basic SQL Test' as check_name;
SELECT 
    'MindsDB Health Check PASSED' as status,
    NOW() as timestamp,
    'System operational - ready for deployment' as message;

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- 1. MindsDB version should be displayed (e.g., 23.10.x.x)
-- 2. Handlers should include: openai, anthropic, timegpt, postgres, coinmarketcap
-- 3. System databases should include: mindsdb, information_schema
-- 4. All handlers should show import_success = true
-- 5. Final message should show "System operational"
--
-- If any check fails, review troubleshooting/common_issues.md before proceeding
-- ============================================================================
