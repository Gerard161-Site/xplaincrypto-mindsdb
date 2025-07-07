-- Automated Alert System for XplainCrypto
-- Real-time monitoring and alert generation

-- Create alerts table
CREATE TABLE IF NOT EXISTS alerts (
    id SERIAL PRIMARY KEY,
    alert_type VARCHAR(50),
    symbol VARCHAR(20),
    severity VARCHAR(20),
    message TEXT,
    data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    sent BOOLEAN DEFAULT FALSE
);

-- Job: Market Alert System
CREATE JOB IF NOT EXISTS market_alert_system (
    -- Check for anomalies
    INSERT INTO alerts (alert_type, symbol, severity, message, data)
    SELECT 
        'anomaly' as alert_type,
        symbol,
        CASE 
            WHEN anomaly_score > 0.9 THEN 'critical'
            WHEN anomaly_score > 0.8 THEN 'high'
            WHEN anomaly_score > 0.7 THEN 'medium'
            ELSE 'low'
        END as severity,
        CONCAT('Anomaly detected for ', symbol, ': ', anomaly_type) as message,
        JSON_BUILD_OBJECT(
            'anomaly_score', anomaly_score,
            'anomaly_type', anomaly_type,
            'detected_at', NOW()
        ) as data
    FROM anomaly_detection_agent
    WHERE anomaly_score > 0.7
    AND NOT EXISTS (
        SELECT 1 FROM alerts 
        WHERE alert_type = 'anomaly' 
        AND symbol = anomaly_detection_agent.symbol
        AND created_at > NOW() - INTERVAL '1 hour'
    );
    
    -- Check whale movements
    INSERT INTO alerts (alert_type, symbol, severity, message, data)
    SELECT 
        'whale_movement' as alert_type,
        token as symbol,
        CASE 
            WHEN probability > 0.9 THEN 'critical'
            WHEN probability > 0.8 THEN 'high'
            ELSE 'medium'
        END as severity,
        CONCAT('Whale alert: Predicted ', next_action, ' for ', token, ' in ', timeframe) as message,
        JSON_BUILD_OBJECT(
            'wallet', wallet_address,
            'action', next_action,
            'probability', probability,
            'timeframe', timeframe
        ) as data
    FROM whale_behavior_predictor
    WHERE probability > 0.7
    AND next_action IN ('massive_sell', 'massive_buy', 'exit');
    
    -- Check arbitrage opportunities
    INSERT INTO alerts (alert_type, symbol, severity, message, data)
    SELECT 
        'arbitrage' as alert_type,
        token as symbol,
        CASE 
            WHEN arbitrage_profit > 1000 THEN 'high'
            WHEN arbitrage_profit > 500 THEN 'medium'
            ELSE 'low'
        END as severity,
        CONCAT('Arbitrage opportunity: $', ROUND(arbitrage_profit, 2), ' profit between ', chain_a, ' and ', chain_b) as message,
        JSON_BUILD_OBJECT(
            'profit_usd', arbitrage_profit,
            'chain_a', chain_a,
            'chain_b', chain_b,
            'success_probability', success_probability
        ) as data
    FROM cross_chain_arbitrage
    WHERE arbitrage_profit > 100
    AND success_probability > 0.8;
    
    -- Price alerts based on significant movements
    INSERT INTO alerts (alert_type, symbol, severity, message, data)
    SELECT 
        'price_movement' as alert_type,
        symbol,
        CASE 
            WHEN ABS(price_change_24h) > 20 THEN 'critical'
            WHEN ABS(price_change_24h) > 10 THEN 'high'
            WHEN ABS(price_change_24h) > 5 THEN 'medium'
            ELSE 'low'
        END as severity,
        CONCAT(symbol, ' ', 
            CASE WHEN price_change_24h > 0 THEN 'surged' ELSE 'dropped' END,
            ' ', ABS(ROUND(price_change_24h, 2)), '% in 24h'
        ) as message,
        JSON_BUILD_OBJECT(
            'current_price', close,
            'change_24h', price_change_24h,
            'volume', volume,
            'market_cap', market_cap
        ) as data
    FROM postgres_db.crypto_data.prices
    WHERE timestamp > NOW() - INTERVAL '5 minutes'
    AND ABS(price_change_24h) > 5
    AND NOT EXISTS (
        SELECT 1 FROM alerts 
        WHERE alert_type = 'price_movement' 
        AND symbol = prices.symbol
        AND created_at > NOW() - INTERVAL '1 hour'
    );
) EVERY 30 seconds;

-- Materialized view for real-time dashboard
CREATE MATERIALIZED VIEW IF NOT EXISTS market_dashboard AS
SELECT 
    p.symbol,
    p.close as current_price,
    p.price_change_24h,
    p.volume,
    p.market_cap,
    COUNT(DISTINCT w.tx_hash) as whale_tx_24h,
    SUM(w.amount_usd) as whale_volume_24h,
    AVG(s.sentiment_score) as avg_sentiment,
    MAX(a.created_at) as last_alert
FROM crypto_data.prices p
LEFT JOIN crypto_data.whale_transactions w 
    ON p.symbol = w.symbol 
    AND w.timestamp > NOW() - INTERVAL '24 hours'
LEFT JOIN crypto_data.social_sentiment s 
    ON p.symbol = s.symbol 
    AND s.timestamp > NOW() - INTERVAL '24 hours'
LEFT JOIN alerts a 
    ON p.symbol = a.symbol 
    AND a.created_at > NOW() - INTERVAL '24 hours'
WHERE p.timestamp = (
    SELECT MAX(timestamp) 
    FROM crypto_data.prices 
    WHERE symbol = p.symbol
)
GROUP BY p.symbol, p.close, p.price_change_24h, p.volume, p.market_cap;

-- Refresh dashboard every minute
CREATE JOB IF NOT EXISTS refresh_dashboard (
    REFRESH MATERIALIZED VIEW CONCURRENTLY market_dashboard;
) EVERY 1 minute; 