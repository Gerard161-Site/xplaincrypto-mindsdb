-- PostgreSQL Schema for XplainCrypto Historical Data
-- This script creates all necessary tables for data persistence

-- Create schema
CREATE SCHEMA IF NOT EXISTS crypto_data;

-- Historical prices table with partitioning
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
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (timestamp, symbol)
) PARTITION BY RANGE (timestamp);

-- Create monthly partitions (example for current month)
CREATE TABLE IF NOT EXISTS crypto_data.prices_2024_01 
PARTITION OF crypto_data.prices 
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- Whale transactions table
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

-- Social sentiment table
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

-- DeFi yields table
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

-- Cross-chain prices for arbitrage
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
    bridge_fee DECIMAL(10,4),
    gas_cost_a DECIMAL(10,4),
    gas_cost_b DECIMAL(10,4),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sync status tracking
CREATE TABLE IF NOT EXISTS crypto_data.sync_status (
    handler_name VARCHAR(50) PRIMARY KEY,
    last_sync TIMESTAMPTZ,
    records_synced INTEGER,
    status VARCHAR(20),
    error_message TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Agent communications
CREATE TABLE IF NOT EXISTS crypto_data.agent_communications (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    from_agent VARCHAR(100),
    to_agent VARCHAR(100),
    message_type VARCHAR(50),
    payload JSONB,
    priority INTEGER DEFAULT 5,
    processed BOOLEAN DEFAULT FALSE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_prices_symbol_timestamp 
ON crypto_data.prices(symbol, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_whale_tx_timestamp 
ON crypto_data.whale_transactions(timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_whale_tx_amount 
ON crypto_data.whale_transactions(amount_usd DESC);

CREATE INDEX IF NOT EXISTS idx_whale_tx_wallet 
ON crypto_data.whale_transactions(wallet_address);

CREATE INDEX IF NOT EXISTS idx_sentiment_symbol_timestamp 
ON crypto_data.social_sentiment(symbol, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_cross_chain_token 
ON crypto_data.cross_chain_prices(token, timestamp DESC);

-- Create hypertables for time-series optimization (if TimescaleDB is available)
-- SELECT create_hypertable('crypto_data.prices', 'timestamp', if_not_exists => TRUE);
-- SELECT create_hypertable('crypto_data.whale_transactions', 'timestamp', if_not_exists => TRUE); 