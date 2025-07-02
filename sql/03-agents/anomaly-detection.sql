-- Anomaly Detection Agents for XplainCrypto
-- Detect market manipulation, unusual whale activity, and price anomalies

-- Real-time Anomaly Detection Agent
CREATE MODEL IF NOT EXISTS anomaly_detection_agent
FROM postgres_db (
    SELECT 
        timestamp,
        symbol,
        close as price,
        volume,
        (close - LAG(close, 1) OVER (PARTITION BY symbol ORDER BY timestamp)) / LAG(close, 1) OVER (PARTITION BY symbol ORDER BY timestamp) * 100 as price_change_1h,
        (volume - LAG(volume, 1) OVER (PARTITION BY symbol ORDER BY timestamp)) / LAG(volume, 1) OVER (PARTITION BY symbol ORDER BY timestamp) * 100 as volume_change_1h,
        whale_transactions,
        social_mentions
    FROM crypto_prices_historical
    WHERE timestamp > NOW() - INTERVAL '30 days'
)
PREDICT anomaly_score, anomaly_type
USING
    engine = 'anomaly_detection',
    ensemble = true,
    contamination = 0.1;

-- Whale Behavior Prediction Agent
CREATE MODEL IF NOT EXISTS whale_behavior_predictor
FROM postgres_db.whale_transactions (
    SELECT 
        wallet_address,
        timestamp as transaction_time,
        amount,
        symbol as token,
        from_address,
        to_address,
        CASE 
            WHEN from_address LIKE '%exchange%' THEN 'exchange'
            ELSE 'wallet'
        END as from_type,
        CASE 
            WHEN to_address LIKE '%exchange%' THEN 'exchange'
            ELSE 'wallet'
        END as to_type,
        amount_usd / 1000000 as amount_millions,
        COUNT(*) OVER (PARTITION BY wallet_address ORDER BY timestamp RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW) as transaction_count_24h
    FROM whale_transactions
    WHERE amount_usd > 100000
    AND timestamp > NOW() - INTERVAL '90 days'
)
PREDICT next_action, probability, timeframe
USING
    engine = 'lightwood',
    encoder_type = 'transformer';

-- Cross-Chain Arbitrage Detection Agent
CREATE MODEL IF NOT EXISTS cross_chain_arbitrage
FROM postgres_db (
    SELECT 
        timestamp,
        token,
        chain_a,
        price_a,
        liquidity_a,
        chain_b,
        price_b,
        liquidity_b,
        bridge_fee,
        gas_cost_a,
        gas_cost_b,
        ABS(price_a - price_b) / price_a * 100 as price_diff_pct
    FROM cross_chain_prices
    WHERE timestamp > NOW() - INTERVAL '1 hour'
    AND liquidity_a > 100000
    AND liquidity_b > 100000
)
PREDICT arbitrage_profit, success_probability
USING
    engine = 'lightwood',
    stop_after = 60; 