-- PostgreSQL Database Connection for XplainCrypto
-- Purpose: Connect MindsDB to the crypto_data PostgreSQL database
-- Documentation: https://docs.mindsdb.com/mindsdb_sql/sql/create/database

-- Connect to the crypto_data database (existing on production server)
-- This database stores historical crypto data for AI model training
CREATE DATABASE IF NOT EXISTS crypto_data_db
WITH ENGINE = 'postgres',
PARAMETERS = {
    "host": "localhost",
    "port": 5432,
    "database": "crypto_data",
    "user": "mindsdb",
    "password": "${POSTGRES_PASSWORD}"
};

-- Verify the connection was created successfully
SELECT * FROM information_schema.databases WHERE name = 'crypto_data_db';

-- Test the connection by querying a sample table
-- Note: This will only work if tables exist in the crypto_data database
-- SELECT COUNT(*) as table_count FROM crypto_data_db.information_schema.tables; 