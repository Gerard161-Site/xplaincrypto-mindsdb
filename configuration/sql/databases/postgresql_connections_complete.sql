-- XplainCrypto PostgreSQL Databases Complete Connection Script
-- Purpose: Connect to all 3 PostgreSQL databases in the XplainCrypto infrastructure
-- Execute AFTER confirming all database containers are running

-- ============================================================================
-- XPLAINCRYPTO 3 POSTGRESQL DATABASES
-- ============================================================================

-- Database 1: Crypto Data (Port 5432) - ✅ WORKING
-- Contains: Historical crypto data, AI training data, market analysis data
CREATE DATABASE IF NOT EXISTS crypto_data_db
WITH ENGINE = 'postgres',
PARAMETERS = {
    "host": "142.93.49.20",
    "port": 5432,
    "database": "crypto_data",
    "user": "mindsdb",
    "password": "rfmveurVyThziPsujMdMsnya6JNirlz8nFrcH34o9Xs="
};

-- Database 2: User Data (Port 5433) - ⚠️ REQUIRES CONTAINER TO BE RUNNING
-- Contains: User accounts, portfolios, social features, educational content
CREATE DATABASE IF NOT EXISTS user_data_db
WITH ENGINE = 'postgres',
PARAMETERS = {
    "host": "142.93.49.20",
    "port": 5433,
    "database": "user_data",
    "user": "xplaincrypto",
    "password": "SimplePass123"
};

-- Database 3: Operational Data (Port 5434) - ⚠️ REQUIRES CONTAINER TO BE RUNNING
-- Contains: FastAPI logs, sessions, caching, operational metrics
CREATE DATABASE IF NOT EXISTS operational_data_db
WITH ENGINE = 'postgres',
PARAMETERS = {
    "host": "142.93.49.20",
    "port": 5434,
    "database": "operational_data",
    "user": "fastapi",
    "password": "rfmveurVyThziPsujMdMsnya6JNirlz8nFrcH34o9Xs="
};

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check all PostgreSQL database connections
SELECT 'PostgreSQL Databases Status' as check_name;
SELECT name, engine, creation_date 
FROM information_schema.databases 
WHERE name LIKE '%data_db'
ORDER BY name;

-- Detailed status check
SELECT 'Connection Status Summary' as check_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'crypto_data_db')
        THEN '✅ crypto_data_db (Port 5432) - CONNECTED'
        ELSE '❌ crypto_data_db (Port 5432) - FAILED'
    END as crypto_data_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'user_data_db')
        THEN '✅ user_data_db (Port 5433) - CONNECTED'
        ELSE '❌ user_data_db (Port 5433) - FAILED'
    END as user_data_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.databases WHERE name = 'operational_data_db')
        THEN '✅ operational_data_db (Port 5434) - CONNECTED'
        ELSE '❌ operational_data_db (Port 5434) - FAILED'
    END as operational_data_status;

-- ============================================================================
-- TROUBLESHOOTING NOTES
-- ============================================================================

-- Current Status:
-- ✅ crypto_data_db (Port 5432): WORKING - Part of MindsDB infrastructure
-- ❌ user_data_db (Port 5433): Connection timeout - Container not running
-- ❌ operational_data_db (Port 5434): Connection timeout - Container not running

-- To fix Database 2 & 3:
-- 1. Start the xplaincrypto-user-database container (Port 5433)
-- 2. Start the xplaincrypto-fastapi postgres container (Port 5434)
-- 3. Verify containers are running: docker ps | grep postgres
-- 4. Re-run this script

-- Manual Connection Test Data:
-- Database 1: ✅ WORKING
--   Host: 142.93.49.20, Port: 5432, DB: crypto_data, User: mindsdb
-- Database 2: ⚠️ NEEDS CONTAINER
--   Host: 142.93.49.20, Port: 5433, DB: user_data, User: xplaincrypto  
-- Database 3: ⚠️ NEEDS CONTAINER
--   Host: 142.93.49.20, Port: 5434, DB: operational_data, User: fastapi

-- ============================================================================ 