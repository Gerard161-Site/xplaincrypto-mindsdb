
-- XplainCrypto PostgreSQL Schema Setup
-- Purpose: Create historical data tables and schema in PostgreSQL
-- Execute AFTER database connections are established
-- Expected execution time: 1-2 minutes

-- ============================================================================
-- POSTGRESQL SCHEMA SCRIPT
-- This creates the data persistence layer for historical crypto data
-- ============================================================================

-- Note: This script should be executed in your PostgreSQL database
-- You can execute it through MindsDB using the crypto_data_db connection
-- Or execute directly in PostgreSQL if you have direct access

-- Create main schema for crypto data
-- CREATE SCHEMA IF NOT EXISTS crypto_data;

-- Historical prices table with time-series optimization
CREATE TABLE IF NOT EXISTS crypto_data.prices (
    id SERIAL,
    timestamp TIMESTAMPTZ NOT NULL,
    symbol VARCHAR(20) NOT NULL,
    open DECIMAL(20,8),
    high DECIMAL(20,8),
    low DECIMAL(20,8),
    close DECIMAL(20,8) NOT NULL,
    volume DECIMAL(20,8),
    market_cap DECIMAL(20,2),
    price_change_24h DECIMAL(10,4),
    price_change_7d DECIMAL(10,4),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (timestamp, symbol)
);

-- Whale transactions tracking table
CREATE TABLE IF NOT EXISTS crypto_data.whale_transactions (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL,
    blockchain VARCHAR(50),
    tx_hash VARCHAR(100) UNIQUE,
    from_address VARCHAR(100),
    to_address VARCHAR(100),
    wallet_address VARCHAR(100),
    symbol VARCHAR(20),
    amount DECIMAL(30,8),
    amount_usd DECIMAL(20,2),
    from_type VARCHAR(50),
    to_type VARCHAR(50),
    transaction_type VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Social sentiment aggregation table
CREATE TABLE IF NOT EXISTS crypto_data.social_sentiment (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL,
    platform VARCHAR(50),
    symbol VARCHAR(20),
    sentiment_score DECIMAL(5,4),
    volume_mentions INTEGER,
    influencer_mentions INTEGER,
    sentiment_breakdown JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- DeFi protocol yields and TVL tracking
CREATE TABLE IF NOT EXISTS crypto_data.defi_yields (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL,
    protocol VARCHAR(100),
    chain VARCHAR(50),
    pool_name VARCHAR(200),
    token_a VARCHAR(20),
    token_b VARCHAR(20),
    apy DECIMAL(10,4),
    tvl DECIMAL(20,2),
    risk_score DECIMAL(5,4),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cross-chain arbitrage opportunities
CREATE TABLE IF NOT EXISTS crypto_data.cross_chain_prices (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL,
    token VARCHAR(20),
    chain_a VARCHAR(50),
    price_a DECIMAL(20,8),
    liquidity_a DECIMAL(20,2),
    chain_b VARCHAR(50),
    price_b DECIMAL(20,8),
    liquidity_b DECIMAL(20,2),
    price_difference_pct DECIMAL(10,4),
    bridge_fee DECIMAL(10,4),
    gas_cost_a DECIMAL(10,4),
    gas_cost_b DECIMAL(10,4),
    profit_potential DECIMAL(10,4),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI agent predictions and analysis storage
CREATE TABLE IF NOT EXISTS crypto_data.agent_predictions (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    agent_name VARCHAR(100),
    symbol VARCHAR(20),
    prediction_type VARCHAR(50),
    prediction_data JSONB,
    confidence_score DECIMAL(5,4),
    time_horizon VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- System synchronization status tracking
CREATE TABLE IF NOT EXISTS crypto_data.sync_status (
    handler_name VARCHAR(50) PRIMARY KEY,
    last_sync TIMESTAMPTZ,
    records_synced INTEGER,
    status VARCHAR(20),
    error_message TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Agent communication and coordination
CREATE TABLE IF NOT EXISTS crypto_data.agent_communications (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    from_agent VARCHAR(100),
    to_agent VARCHAR(100),
    message_type VARCHAR(50),
    payload JSONB,
    priority INTEGER DEFAULT 5,
    processed BOOLEAN DEFAULT FALSE,
    processed_at TIMESTAMPTZ
);

-- Market alerts and notifications
CREATE TABLE IF NOT EXISTS crypto_data.market_alerts (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    alert_type VARCHAR(50),
    symbol VARCHAR(20),
    trigger_condition VARCHAR(200),
    current_value DECIMAL(20,8),
    threshold_value DECIMAL(20,8),
    severity VARCHAR(20),
    message TEXT,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_at TIMESTAMPTZ
);

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

-- Indexes for price data queries
CREATE INDEX IF NOT EXISTS idx_prices_symbol_timestamp 
ON crypto_data.prices(symbol, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_prices_timestamp 
ON crypto_data.prices(timestamp DESC);

-- Indexes for whale transaction queries
CREATE INDEX IF NOT EXISTS idx_whale_tx_timestamp 
ON crypto_data.whale_transactions(timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_whale_tx_amount 
ON crypto_data.whale_transactions(amount_usd DESC);

CREATE INDEX IF NOT EXISTS idx_whale_tx_wallet 
ON crypto_data.whale_transactions(wallet_address);

CREATE INDEX IF NOT EXISTS idx_whale_tx_symbol 
ON crypto_data.whale_transactions(symbol, timestamp DESC);

-- Indexes for sentiment analysis
CREATE INDEX IF NOT EXISTS idx_sentiment_symbol_timestamp 
ON crypto_data.social_sentiment(symbol, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_sentiment_platform 
ON crypto_data.social_sentiment(platform, timestamp DESC);

-- Indexes for DeFi data
CREATE INDEX IF NOT EXISTS idx_defi_protocol_timestamp 
ON crypto_data.defi_yields(protocol, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_defi_apy 
ON crypto_data.defi_yields(apy DESC);

-- Indexes for cross-chain arbitrage
CREATE INDEX IF NOT EXISTS idx_cross_chain_token 
ON crypto_data.cross_chain_prices(token, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_cross_chain_profit 
ON crypto_data.cross_chain_prices(profit_potential DESC);

-- Indexes for agent predictions
CREATE INDEX IF NOT EXISTS idx_agent_predictions_symbol 
ON crypto_data.agent_predictions(symbol, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_agent_predictions_agent 
ON crypto_data.agent_predictions(agent_name, timestamp DESC);

-- Indexes for alerts
CREATE INDEX IF NOT EXISTS idx_alerts_timestamp 
ON crypto_data.market_alerts(timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_alerts_symbol 
ON crypto_data.market_alerts(symbol, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_alerts_unacknowledged 
ON crypto_data.market_alerts(acknowledged, timestamp DESC) 
WHERE acknowledged = FALSE;

-- ============================================================================
-- VERIFICATION QUERIES - Execute these to verify schema creation
-- ============================================================================

-- List all created tables
SELECT 'Schema Verification' as check_name;
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'crypto_data'
ORDER BY table_name;

-- Check table row counts (should be 0 for new installation)
SELECT 'Table Status Check' as check_name;
SELECT 
    'crypto_data.prices' as table_name,
    COUNT(*) as row_count
FROM crypto_data.prices
UNION ALL
SELECT 
    'crypto_data.whale_transactions' as table_name,
    COUNT(*) as row_count
FROM crypto_data.whale_transactions
UNION ALL
SELECT 
    'crypto_data.social_sentiment' as table_name,
    COUNT(*) as row_count
FROM crypto_data.social_sentiment;

-- Verify indexes were created
SELECT 'Index Verification' as check_name;
SELECT indexname, tablename
FROM pg_indexes
WHERE schemaname = 'crypto_data'
ORDER BY tablename, indexname;

-- ============================================================================
-- TROUBLESHOOTING:
-- ============================================================================
-- If table creation fails:
-- 1. Ensure PostgreSQL connection (crypto_data_db) was created successfully
-- 2. Verify PostgreSQL user has CREATE TABLE permissions
-- 3. Check if crypto_data schema exists and is accessible
-- 4. Ensure sufficient disk space for database
-- 5. Review PostgreSQL logs for detailed error messages
--
-- Common Issues:
-- - Permission denied: Grant CREATE privileges to mindsdb user
-- - Schema not found: Create crypto_data schema manually
-- - Disk space: Ensure adequate storage for time-series data
--
-- All tables use IF NOT EXISTS - safe to re-run this script
-- ============================================================================
