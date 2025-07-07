-- XplainCrypto MindsDB Health Check
-- Purpose: Validate MindsDB is running and basic functionality works
-- Documentation: https://docs.mindsdb.com/setup/custom-config

-- Check MindsDB version and system status
SELECT version();

-- List available handlers (should show data and ml handlers)
SHOW HANDLERS;

-- Check system databases
SHOW DATABASES;

-- Verify information schema is accessible
SELECT COUNT(*) as total_handlers 
FROM information_schema.handlers;

-- Check available ML handlers for AI engines
SELECT name, title, description, import_success
FROM information_schema.handlers 
WHERE type = 'ml'
ORDER BY name;

-- Check available data handlers for connections
SELECT name, title, description, import_success
FROM information_schema.handlers 
WHERE type = 'data'
ORDER BY name;

-- Test basic SQL functionality
SELECT 
    'MindsDB Health Check' as status,
    NOW() as timestamp,
    'System operational' as message; 