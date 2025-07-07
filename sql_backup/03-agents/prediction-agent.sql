-- TimeGPT Forecasting Agent for XplainCrypto
-- Advanced time-series forecasting using Nixtla's TimeGPT

-- Single asset forecasting model
CREATE MODEL IF NOT EXISTS crypto_prediction_agent
PREDICT price_forecast
USING
    engine = 'timegpt_engine',
    horizon = 24,        -- 24 hours forecast
    frequency = 'H',     -- Hourly frequency
    confidence_level = 0.95,
    model = 'timegpt-1-long-horizon',
    finetune_steps = 10,
    clean_ex_first = true;

-- Multi-asset forecasting model with historical data
CREATE MODEL IF NOT EXISTS multi_asset_forecast
FROM postgres_db.crypto_prices_historical (
    SELECT 
        timestamp, 
        symbol, 
        close as price, 
        volume, 
        market_cap
    FROM crypto_prices_historical
    WHERE timestamp > NOW() - INTERVAL '6 months'
)
PREDICT price
ORDER BY timestamp
GROUP BY symbol
WINDOW 168      -- 1 week lookback
HORIZON 168     -- 1 week forecast
USING
    engine = 'timegpt_engine',
    confidence_level = 0.95,
    finetune_steps = 10; 