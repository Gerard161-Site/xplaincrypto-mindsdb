-- Data Synchronization Jobs for XplainCrypto
-- Continuous sync from APIs to PostgreSQL for historical data

-- PostgreSQL connection setup
CREATE DATABASE IF NOT EXISTS postgres_db
WITH ENGINE = 'postgres',
PARAMETERS = {
    "host": "postgres",
    "port": 5432,
    "database": "crypto_data",
    "user": "postgres",
    "password": "${POSTGRES_PASSWORD}"
};

-- Job: Sync market data from multiple sources
CREATE JOB IF NOT EXISTS sync_market_data (
    -- Sync CoinMarketCap data
    INSERT INTO postgres_db.crypto_data.prices (
        timestamp,
        symbol,
        open,
        high,
        low,
        close,
        volume,
        market_cap,
        price_change_24h
    )
    SELECT 
        NOW() as timestamp,
        symbol,
        price as open,  -- Will be updated by OHLCV job
        price as high,
        price as low,
        price as close,
        volume_24h as volume,
        market_cap,
        percent_change_24h as price_change_24h
    FROM coinmarketcap_db.quotes
    WHERE symbol IN ('BTC', 'ETH', 'BNB', 'SOL', 'ADA', 'AVAX', 'DOT', 'MATIC', 'LINK', 'UNI')
    ON CONFLICT (timestamp, symbol) DO UPDATE
    SET 
        close = EXCLUDED.close,
        volume = EXCLUDED.volume,
        market_cap = EXCLUDED.market_cap,
        price_change_24h = EXCLUDED.price_change_24h;
        
    -- Update sync status
    INSERT INTO postgres_db.crypto_data.sync_status (handler_name, last_sync, records_synced, status)
    VALUES ('coinmarketcap', NOW(), 10, 'success')
    ON CONFLICT (handler_name) DO UPDATE
    SET 
        last_sync = NOW(),
        records_synced = sync_status.records_synced + 10,
        status = 'success',
        updated_at = NOW();
) EVERY 1 minute;

-- Job: Track whale movements
CREATE JOB IF NOT EXISTS track_whale_movements (
    INSERT INTO postgres_db.crypto_data.whale_transactions (
        timestamp,
        blockchain,
        tx_hash,
        from_address,
        to_address,
        wallet_address,
        symbol,
        amount,
        amount_usd,
        from_type,
        to_type,
        transaction_type
    )
    SELECT 
        timestamp,
        blockchain,
        hash as tx_hash,
        from_address,
        to_address,
        COALESCE(from_address, to_address) as wallet_address,
        symbol,
        amount,
        amount_usd,
        from_owner_type as from_type,
        to_owner_type as to_type,
        CASE 
            WHEN from_owner_type = 'exchange' AND to_owner_type != 'exchange' THEN 'withdrawal'
            WHEN from_owner_type != 'exchange' AND to_owner_type = 'exchange' THEN 'deposit'
            WHEN amount_usd > 10000000 THEN 'mega_transaction'
            ELSE 'transfer'
        END as transaction_type
    FROM whale_alerts_db.transactions
    WHERE amount_usd > 100000
    AND timestamp > (
        SELECT COALESCE(MAX(timestamp), NOW() - INTERVAL '1 hour')
        FROM postgres_db.crypto_data.whale_transactions
    )
    ON CONFLICT (tx_hash) DO NOTHING;
    
    -- Update sync status
    INSERT INTO postgres_db.crypto_data.sync_status (handler_name, last_sync, status)
    VALUES ('whale_alerts', NOW(), 'success')
    ON CONFLICT (handler_name) DO UPDATE
    SET last_sync = NOW(), status = 'success', updated_at = NOW();
) EVERY 5 minutes;

-- Job: Sync DeFi yields
CREATE JOB IF NOT EXISTS sync_defi_yields (
    INSERT INTO postgres_db.crypto_data.defi_yields (
        timestamp,
        protocol,
        chain,
        pool_name,
        token_a,
        token_b,
        apy,
        tvl,
        risk_score
    )
    SELECT 
        NOW() as timestamp,
        protocol,
        chain,
        name as pool_name,
        symbol as token_a,  -- Simplified, needs parsing
        'USDC' as token_b,  -- Simplified
        apy,
        tvl,
        CASE 
            WHEN apy > 100 THEN 0.9  -- Very high risk
            WHEN apy > 50 THEN 0.7   -- High risk
            WHEN apy > 20 THEN 0.5   -- Medium risk
            ELSE 0.3                  -- Low risk
        END as risk_score
    FROM defillama_db.pools
    WHERE tvl > 1000000  -- Only pools with > $1M TVL
    ORDER BY tvl DESC
    LIMIT 100;
    
    -- Update sync status
    INSERT INTO postgres_db.crypto_data.sync_status (handler_name, last_sync, records_synced, status)
    VALUES ('defillama', NOW(), 100, 'success')
    ON CONFLICT (handler_name) DO UPDATE
    SET last_sync = NOW(), records_synced = 100, status = 'success', updated_at = NOW();
) EVERY 30 minutes;

-- Job: Process agent messages
CREATE JOB IF NOT EXISTS process_agent_messages (
    -- Process high-priority inter-agent messages
    UPDATE postgres_db.crypto_data.agent_communications
    SET processed = TRUE
    WHERE processed = FALSE
    AND priority >= 8
    AND timestamp > NOW() - INTERVAL '1 minute';
) EVERY 10 seconds;

-- Job: Clean old data
CREATE JOB IF NOT EXISTS cleanup_old_data (
    -- Delete price data older than 1 year
    DELETE FROM postgres_db.crypto_data.prices 
    WHERE timestamp < NOW() - INTERVAL '1 year';
    
    -- Delete processed agent messages older than 7 days
    DELETE FROM postgres_db.crypto_data.agent_communications
    WHERE processed = TRUE
    AND timestamp < NOW() - INTERVAL '7 days';
) EVERY 1 day START '2024-01-01 02:00:00'; 