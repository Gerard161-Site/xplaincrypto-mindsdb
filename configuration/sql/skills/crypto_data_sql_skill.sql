
-- XplainCrypto Crypto Data SQL Skill
-- Reusable AI skill for querying crypto market data using natural language

-- Create the crypto data SQL skill
CREATE SKILL crypto_data_sql_skill
USING
    type = 'text2sql',
    database = 'crypto_data_db',
    tables = [
        'historical_prices',
        'daily_ohlcv', 
        'daily_technical_indicators',
        'real_time_prices',
        'defi_protocols',
        'defi_real_time',
        'market_data_hourly',
        'blockchain_metrics'
    ],
    description = 'Comprehensive crypto market data including historical prices, technical indicators, DeFi metrics, and blockchain statistics. Covers major cryptocurrencies like BTC, ETH, BNB, XRP, ADA, SOL, and DeFi protocols with TVL, volume, and user metrics.';

-- Test the skill with sample queries
-- Test Query 1: Basic price information
SELECT 
    'Test Query 1: Bitcoin current price' as test_description,
    symbol,
    price,
    percent_change_24h,
    volume_24h,
    market_cap
FROM crypto_data_db.real_time_prices 
WHERE symbol = 'BTC' 
ORDER BY last_updated DESC 
LIMIT 1;

-- Test Query 2: Technical analysis data
SELECT 
    'Test Query 2: Ethereum technical indicators' as test_description,
    symbol,
    date,
    close_price,
    rsi,
    macd,
    sma_20,
    bollinger_upper,
    bollinger_lower
FROM crypto_data_db.daily_technical_indicators 
WHERE symbol = 'ETH' 
ORDER BY date DESC 
LIMIT 5;

-- Test Query 3: DeFi protocol information
SELECT 
    'Test Query 3: Top DeFi protocols by TVL' as test_description,
    protocol_name,
    tvl,
    volume_24h,
    tvl_change_24h,
    chain
FROM crypto_data_db.defi_real_time 
WHERE tvl > 100000000 
ORDER BY tvl DESC 
LIMIT 10;

-- Create sample query templates for common use cases
CREATE TABLE crypto_data_db.sql_skill_templates (
    template_id VARCHAR(50) PRIMARY KEY,
    template_name VARCHAR(200),
    description TEXT,
    sql_template TEXT,
    parameters JSON,
    example_usage TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO crypto_data_db.sql_skill_templates VALUES
('price_comparison', 
 'Compare cryptocurrency prices',
 'Compare current prices and performance of multiple cryptocurrencies',
 'SELECT symbol, price, percent_change_24h, volume_24h, market_cap FROM crypto_data_db.real_time_prices WHERE symbol IN ({symbols}) ORDER BY market_cap DESC',
 '{"symbols": ["BTC", "ETH", "BNB"]}',
 'Compare Bitcoin, Ethereum, and Binance Coin prices',
 NOW()),

('technical_analysis',
 'Technical analysis indicators',
 'Get technical indicators for cryptocurrency analysis',
 'SELECT symbol, date, close_price, rsi, macd, sma_20, bollinger_upper, bollinger_lower FROM crypto_data_db.daily_technical_indicators WHERE symbol = "{symbol}" AND date >= DATE_SUB(CURDATE(), INTERVAL {days} DAY) ORDER BY date DESC',
 '{"symbol": "BTC", "days": 30}',
 'Get Bitcoin technical indicators for the last 30 days',
 NOW()),

('price_history',
 'Historical price data',
 'Retrieve historical price data for trend analysis',
 'SELECT symbol, date, open_price, high_price, low_price, close_price, volume FROM crypto_data_db.daily_ohlcv WHERE symbol = "{symbol}" AND date >= DATE_SUB(CURDATE(), INTERVAL {days} DAY) ORDER BY date DESC',
 '{"symbol": "ETH", "days": 90}',
 'Get Ethereum price history for the last 90 days',
 NOW()),

('defi_overview',
 'DeFi protocol overview',
 'Overview of DeFi protocols and their metrics',
 'SELECT protocol_name, tvl, volume_24h, fees_24h, active_users, chain FROM crypto_data_db.defi_real_time WHERE tvl > {min_tvl} ORDER BY tvl DESC LIMIT {limit}',
 '{"min_tvl": 50000000, "limit": 20}',
 'Get top 20 DeFi protocols with TVL over $50M',
 NOW()),

('market_movers',
 'Top market movers',
 'Find cryptocurrencies with significant price movements',
 'SELECT symbol, price, percent_change_24h, volume_24h FROM crypto_data_db.real_time_prices WHERE ABS(percent_change_24h) > {threshold} ORDER BY ABS(percent_change_24h) DESC LIMIT {limit}',
 '{"threshold": 5, "limit": 10}',
 'Find top 10 cryptocurrencies with price changes over 5%',
 NOW()),

('volume_analysis',
 'Volume analysis',
 'Analyze trading volume patterns',
 'SELECT symbol, date, volume, volume_change_24h, (volume / volume_sma_20) as volume_ratio FROM crypto_data_db.daily_technical_indicators WHERE symbol = "{symbol}" AND date >= DATE_SUB(CURDATE(), INTERVAL {days} DAY) ORDER BY date DESC',
 '{"symbol": "BTC", "days": 30}',
 'Analyze Bitcoin volume patterns for the last 30 days',
 NOW()),

('support_resistance',
 'Support and resistance levels',
 'Identify key support and resistance levels',
 'SELECT symbol, date, close_price, support_level, resistance_level, (close_price - support_level)/(resistance_level - support_level) as price_position FROM crypto_data_db.daily_technical_indicators WHERE symbol = "{symbol}" ORDER BY date DESC LIMIT {limit}',
 '{"symbol": "ETH", "limit": 10}',
 'Get Ethereum support and resistance levels',
 NOW()),

('blockchain_stats',
 'Blockchain network statistics',
 'Get blockchain network health and activity metrics',
 'SELECT blockchain, block_height, hash_rate, transaction_count_24h, active_addresses, network_utilization FROM crypto_data_db.blockchain_metrics WHERE blockchain = "{blockchain}" ORDER BY last_updated DESC LIMIT 1',
 '{"blockchain": "bitcoin"}',
 'Get Bitcoin network statistics',
 NOW());

-- Create helper functions for common calculations
DELIMITER //

CREATE FUNCTION calculate_rsi(symbol_param VARCHAR(10), period_param INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE rsi_value DECIMAL(5,2);
    
    SELECT 
        100 - (100 / (1 + (
            AVG(CASE WHEN price_change_24h > 0 THEN price_change_24h ELSE 0 END) /
            AVG(CASE WHEN price_change_24h < 0 THEN ABS(price_change_24h) ELSE 0 END)
        )))
    INTO rsi_value
    FROM (
        SELECT 
            (close_price - LAG(close_price) OVER (ORDER BY date)) / LAG(close_price) OVER (ORDER BY date) * 100 as price_change_24h
        FROM crypto_data_db.daily_ohlcv 
        WHERE symbol = symbol_param 
        ORDER BY date DESC 
        LIMIT period_param
    ) price_changes
    WHERE price_change_24h IS NOT NULL;
    
    RETURN COALESCE(rsi_value, 50);
END //

CREATE FUNCTION get_price_trend(symbol_param VARCHAR(10), days_param INT)
RETURNS VARCHAR(20)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE trend_direction VARCHAR(20);
    DECLARE price_change DECIMAL(10,2);
    
    SELECT 
        (MAX(close_price) - MIN(close_price)) / MIN(close_price) * 100
    INTO price_change
    FROM crypto_data_db.daily_ohlcv 
    WHERE symbol = symbol_param 
    AND date >= DATE_SUB(CURDATE(), INTERVAL days_param DAY);
    
    SET trend_direction = CASE 
        WHEN price_change > 10 THEN 'Strong Uptrend'
        WHEN price_change > 3 THEN 'Uptrend'
        WHEN price_change > -3 THEN 'Sideways'
        WHEN price_change > -10 THEN 'Downtrend'
        ELSE 'Strong Downtrend'
    END;
    
    RETURN trend_direction;
END //

CREATE FUNCTION calculate_volatility(symbol_param VARCHAR(10), days_param INT)
RETURNS DECIMAL(8,4)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE volatility_value DECIMAL(8,4);
    
    SELECT 
        STDDEV((close_price - LAG(close_price) OVER (ORDER BY date)) / LAG(close_price) OVER (ORDER BY date) * 100)
    INTO volatility_value
    FROM crypto_data_db.daily_ohlcv 
    WHERE symbol = symbol_param 
    AND date >= DATE_SUB(CURDATE(), INTERVAL days_param DAY)
    ORDER BY date;
    
    RETURN COALESCE(volatility_value, 0);
END //

DELIMITER ;

-- Create views for commonly requested data combinations
CREATE VIEW crypto_market_overview AS
SELECT 
    p.symbol,
    p.price,
    p.percent_change_24h,
    p.volume_24h,
    p.market_cap,
    t.rsi,
    t.macd,
    t.sma_20,
    get_price_trend(p.symbol, 7) as trend_7d,
    calculate_volatility(p.symbol, 30) as volatility_30d,
    p.last_updated
FROM crypto_data_db.real_time_prices p
LEFT JOIN crypto_data_db.daily_technical_indicators t ON p.symbol = t.symbol AND t.date = CURDATE()
WHERE p.data_quality_score > 0.7
ORDER BY p.market_cap DESC;

CREATE VIEW defi_protocol_summary AS
SELECT 
    protocol_name,
    tvl,
    volume_24h,
    fees_24h,
    active_users,
    tvl_change_24h,
    chain,
    category,
    RANK() OVER (ORDER BY tvl DESC) as tvl_rank,
    RANK() OVER (ORDER BY volume_24h DESC) as volume_rank,
    last_updated
FROM crypto_data_db.defi_real_time
WHERE tvl > 1000000
ORDER BY tvl DESC;

CREATE VIEW technical_signals AS
SELECT 
    symbol,
    date,
    close_price,
    rsi,
    CASE 
        WHEN rsi > 70 THEN 'Overbought'
        WHEN rsi < 30 THEN 'Oversold'
        ELSE 'Neutral'
    END as rsi_signal,
    macd,
    macd_signal,
    CASE 
        WHEN macd > macd_signal THEN 'Bullish'
        ELSE 'Bearish'
    END as macd_signal_direction,
    close_price as current_price,
    sma_20,
    CASE 
        WHEN close_price > sma_20 THEN 'Above SMA20'
        ELSE 'Below SMA20'
    END as sma_position,
    bollinger_upper,
    bollinger_lower,
    CASE 
        WHEN close_price > bollinger_upper THEN 'Above Upper Band'
        WHEN close_price < bollinger_lower THEN 'Below Lower Band'
        ELSE 'Within Bands'
    END as bollinger_position
FROM crypto_data_db.daily_technical_indicators
WHERE date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
ORDER BY symbol, date DESC;

-- Create performance monitoring for the skill
CREATE TABLE crypto_data_db.sql_skill_usage_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    query_type VARCHAR(100),
    execution_time_ms INT,
    rows_returned INT,
    success BOOLEAN,
    error_message TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Success validation queries
SELECT 'Crypto Data SQL Skill created successfully' as status;

-- Test the skill functionality
SELECT 
    'Skill Validation' as test_type,
    COUNT(DISTINCT symbol) as symbols_available,
    MAX(last_updated) as latest_data,
    COUNT(*) as total_price_records
FROM crypto_data_db.real_time_prices;

SELECT 
    'Technical Indicators Available' as test_type,
    COUNT(DISTINCT symbol) as symbols_with_indicators,
    MAX(date) as latest_indicator_date,
    COUNT(*) as total_indicator_records
FROM crypto_data_db.daily_technical_indicators;

SELECT 
    'DeFi Data Available' as test_type,
    COUNT(DISTINCT protocol_name) as protocols_available,
    SUM(tvl) as total_tvl,
    MAX(last_updated) as latest_defi_data
FROM crypto_data_db.defi_real_time;
