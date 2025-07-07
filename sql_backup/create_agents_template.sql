-- XplainCrypto Advanced AI Agents Deployment Script - SECURE TEMPLATE
-- This script creates all the AI agents using MindsDB with secure secret placeholders
-- 
-- SECURITY NOTE: This template uses ${VARIABLE_NAME} placeholders that will be
-- replaced with actual secrets at runtime by the secure secrets manager.
-- NEVER commit files with actual API keys!

-- ============================================
-- 1. Create Data Source Connections
-- ============================================

-- PostgreSQL connection for historical data
CREATE DATABASE IF NOT EXISTS postgres_db
WITH ENGINE = 'postgres',
PARAMETERS = {
    'host': 'postgres',
    'port': 5432,
    'database': 'crypto_intelligence',
    'user': 'postgres',
    'password': '{{POSTGRES_PASSWORD}}'
};

-- Binance connection (already created)
-- CREATE DATABASE binance_datasource
-- WITH ENGINE = 'binance'
-- PARAMETERS = {};

-- CoinMarketCap connection
CREATE DATABASE IF NOT EXISTS coinmarketcap_datasource
WITH ENGINE = 'coinmarketcap',
PARAMETERS = {
    'api_key': '{{COINMARKETCAP_API_KEY}}'
};

-- ============================================
-- 2. Create ML Engines
-- ============================================

-- TimeGPT Engine
CREATE ML_ENGINE IF NOT EXISTS timegpt
FROM timegpt
USING
    timegpt_api_key = '{{TIMEGPT_API_KEY}}';

-- ============================================
-- 3. Master Market Intelligence Agent
-- ============================================
CREATE MODEL IF NOT EXISTS market_intelligence_master
USING
  engine = 'anthropic',
  model_name = 'claude-3-opus-20240229',
  api_key = '{{ANTHROPIC_API_KEY}}',
  mode = 'conversational',
  prompt_template = 'You are the Master Market Intelligence Agent for XplainCrypto.
    
Current Market Data: {{market_data}}
Historical Context: {{historical_patterns}}
Social Sentiment: {{sentiment_data}}
Task: {{query}}
    
Provide comprehensive analysis including:
1. Market overview and key trends
2. Risk assessment (1-10 scale)
3. Opportunities identification
4. Actionable recommendations
5. Key support/resistance levels
6. Market sentiment summary

Format as structured JSON for easy parsing.';

-- ============================================
-- 4. TimeGPT Forecasting Models
-- ============================================

-- Short-term BTC forecast
CREATE MODEL IF NOT EXISTS btc_forecast_short
FROM binance_datasource (
  SELECT * FROM aggregated_trade_data
  WHERE symbol = 'BTCUSDT'
  AND close_time > '2024-01-01'
  AND interval = '1h'
  LIMIT 10000
)
PREDICT close_price
ORDER BY close_time
WINDOW 168  -- 1 week lookback
HORIZON 24  -- 24 hour forecast
USING
  engine = 'timegpt';

-- Long-term multi-asset forecast
CREATE MODEL IF NOT EXISTS multi_asset_forecast
FROM binance_datasource (
  SELECT 
    close_time as timestamp,
    symbol,
    close_price as price,
    volume,
    quote_asset_volume as market_cap
  FROM aggregated_trade_data
  WHERE symbol IN ('BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'SOLUSDT', 'ADAUSDT')
  AND close_time > '2024-01-01'
  AND interval = '1d'
)
PREDICT price
ORDER BY timestamp
GROUP BY symbol
WINDOW 90   -- 3 months lookback
HORIZON 30  -- 30 days forecast
USING
  engine = 'timegpt',
  fine_tune = true,
  finetune_steps = 10;

-- ============================================
-- 5. Anomaly Detection Agent
-- ============================================
CREATE MODEL IF NOT EXISTS anomaly_detection_agent
FROM binance_datasource (
  SELECT 
    close_time as timestamp,
    symbol,
    close_price as price,
    volume,
    (close_price - open_price) / open_price * 100 as price_change_pct,
    volume / LAG(volume, 1) OVER (PARTITION BY symbol ORDER BY close_time) as volume_ratio,
    high_price - low_price as price_range,
    count as trade_count
  FROM aggregated_trade_data
  WHERE close_time > NOW() - INTERVAL '30 days'
  AND interval = '15m'
)
PREDICT price, volume
USING
  engine = 'anomaly_detection',
  ensemble = true,
  contamination = 0.05;

-- ============================================
-- 6. DeFi Yield Optimization Agent
-- ============================================
CREATE MODEL IF NOT EXISTS defi_yield_optimizer
USING
  engine = 'openai',
  model_name = 'gpt-4-turbo-preview',
  api_key = '{{OPENAI_API_KEY}}',
  mode = 'conversational',
  prompt_template = 'Analyze DeFi opportunities across protocols.
    
Current Yields: {{yield_data}}
Risk Metrics: {{risk_scores}}
Gas Costs: {{gas_prices}}
User Profile:
- Risk tolerance: {{risk_tolerance}}
- Capital: {{capital}}
- Time horizon: {{time_horizon}}
    
Provide:
1. Top 5 yield opportunities ranked by risk-adjusted returns
2. Recommended allocation percentages
3. Entry/exit strategies
4. Risk mitigation techniques
5. Expected APY range
6. Protocol safety scores

Return as structured JSON.';

-- ============================================
-- 7. Sentiment Analysis Agent
-- ============================================
CREATE MODEL IF NOT EXISTS crypto_sentiment_analyzer
USING
  engine = 'anthropic',
  model_name = 'claude-3-sonnet-20240229',
  api_key = '{{ANTHROPIC_API_KEY}}',
  mode = 'conversational',
  prompt_template = 'Analyze crypto sentiment from social media.
    
Text: {{social_text}}
Source: {{platform}}
Author Followers: {{follower_count}}
Engagement: {{engagement_metrics}}
    
Return JSON with:
{
  "sentiment": "bullish/bearish/neutral",
  "confidence": 0-1,
  "sentiment_score": -1 to 1,
  "key_topics": [],
  "mentioned_tokens": [],
  "influencer_score": 0-10,
  "manipulation_risk": 0-1,
  "fomo_index": 0-10,
  "fear_index": 0-10,
  "summary": "brief analysis"
}';

-- ============================================
-- 8. Risk Management Agent
-- ============================================
CREATE MODEL IF NOT EXISTS risk_management_agent
USING
  engine = 'openai',
  model_name = 'gpt-4-turbo-preview',
  api_key = '{{OPENAI_API_KEY}}',
  mode = 'conversational',
  prompt_template = 'Analyze portfolio risk for crypto holdings.
    
Portfolio: {{portfolio_data}}
Market Conditions: {{market_state}}
Correlation Matrix: {{correlations}}
Historical Volatility: {{volatility_data}}
    
Provide comprehensive risk analysis:
1. Overall risk score (1-10)
2. Portfolio beta
3. Value at Risk (95% confidence)
4. Maximum drawdown potential
5. Specific vulnerabilities
6. Hedging recommendations
7. Rebalancing suggestions
8. Stress test results
9. Black swan event impact

Format as detailed JSON report.';

-- ============================================
-- 9. Technical Analysis Agent
-- ============================================
CREATE MODEL IF NOT EXISTS technical_analysis_agent
USING
  engine = 'openai',
  model_name = 'gpt-4-turbo-preview',
  api_key = '{{OPENAI_API_KEY}}',
  mode = 'conversational',
  prompt_template = 'Perform comprehensive technical analysis.
    
Symbol: {{symbol}}
Timeframe: {{timeframe}}
Price Data: {{ohlcv_data}}
Volume Profile: {{volume_profile}}
    
Analyze and provide:
1. Current trend (strong buy/buy/neutral/sell/strong sell)
2. Key support levels
3. Key resistance levels
4. RSI analysis
5. MACD signals
6. Moving average positions
7. Volume analysis
8. Chart patterns identified
9. Fibonacci levels
10. Entry/exit recommendations

Return as structured JSON with confidence levels.';

-- ============================================
-- 10. Agent Orchestrator
-- ============================================
CREATE MODEL IF NOT EXISTS agent_orchestrator
USING
  engine = 'anthropic',
  model_name = 'claude-3-opus-20240229',
  api_key = '{{ANTHROPIC_API_KEY}}',
  mode = 'conversational',
  prompt_template = 'You are the Master Agent Orchestrator for XplainCrypto.
    
User Query: {{query}}
User Context: {{user_context}}
Available Agents: [
  "market_intelligence_master",
  "btc_forecast_short",
  "multi_asset_forecast",
  "anomaly_detection_agent",
  "defi_yield_optimizer",
  "crypto_sentiment_analyzer",
  "risk_management_agent",
  "technical_analysis_agent"
]
    
Analyze the query and return a JSON execution plan:
{
  "agents_to_activate": [],
  "execution_order": [],
  "parameters_per_agent": {},
  "expected_outputs": [],
  "synthesis_strategy": "",
  "priority": "high/medium/low",
  "estimated_time": "seconds"
}';

-- ============================================
-- 11. Create Supporting Tables
-- ============================================

-- Agent execution history
CREATE TABLE IF NOT EXISTS agent_execution_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    agent_name VARCHAR(100),
    query_hash VARCHAR(64),
    execution_time_ms INT,
    success BOOLEAN,
    error_message TEXT,
    result_summary JSON
);

-- Alert configurations
CREATE TABLE IF NOT EXISTS alert_configurations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(100),
    alert_type VARCHAR(50),
    conditions JSON,
    notification_channels JSON,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Prediction accuracy tracking
CREATE TABLE IF NOT EXISTS prediction_accuracy (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    agent_name VARCHAR(100),
    prediction_type VARCHAR(50),
    predicted_value DECIMAL(20,8),
    actual_value DECIMAL(20,8),
    accuracy_score DECIMAL(5,4),
    metadata JSON
);

-- ============================================
-- 12. Create Scheduled Jobs
-- ============================================

-- Market data sync job
CREATE JOB IF NOT EXISTS sync_market_data (
  -- Update latest prices
  INSERT INTO postgres_db.crypto_data.prices
  SELECT 
    NOW() as timestamp,
    symbol,
    close_price as price,
    volume,
    quote_asset_volume as market_cap,
    open_price as open_24h,
    high_price as high_24h,
    low_price as low_24h,
    (close_price - open_price) / open_price * 100 as price_change_24h
  FROM binance_datasource.aggregated_trade_data
  WHERE interval = '1m'
  AND close_time > (
    SELECT COALESCE(MAX(timestamp), NOW() - INTERVAL '1 day')
    FROM postgres_db.crypto_data.prices
  );
) EVERY 1 minute;

-- Anomaly detection job
CREATE JOB IF NOT EXISTS detect_anomalies (
  INSERT INTO alerts
  SELECT 
    'anomaly' as alert_type,
    symbol,
    anomaly_score,
    NOW() as detected_at,
    JSON_OBJECT(
      'price_deviation': price_anomaly,
      'volume_deviation': volume_anomaly,
      'severity': CASE 
        WHEN anomaly_score > 0.95 THEN 'critical'
        WHEN anomaly_score > 0.85 THEN 'high'
        WHEN anomaly_score > 0.75 THEN 'medium'
        ELSE 'low'
      END
    ) as details
  FROM anomaly_detection_agent
  WHERE anomaly_score > 0.75;
) EVERY 5 minutes;

-- Forecast update job
CREATE JOB IF NOT EXISTS update_forecasts (
  -- Update BTC short-term forecast
  INSERT INTO forecast_results
  SELECT 
    'btc_forecast_short' as model_name,
    symbol,
    predicted_price,
    confidence,
    forecast_timestamp,
    NOW() as created_at
  FROM btc_forecast_short
  WHERE symbol = 'BTCUSDT';
  
  -- Update multi-asset forecasts
  INSERT INTO forecast_results
  SELECT 
    'multi_asset_forecast' as model_name,
    symbol,
    predicted_price,
    confidence,
    forecast_timestamp,
    NOW() as created_at
  FROM multi_asset_forecast;
) EVERY 1 hour;

-- Performance monitoring job
CREATE JOB IF NOT EXISTS monitor_agent_performance (
  -- Track prediction accuracy
  INSERT INTO prediction_accuracy
  SELECT 
    NOW(),
    'btc_forecast_short',
    'price',
    f.predicted_price,
    p.price as actual_price,
    1 - ABS(f.predicted_price - p.price) / p.price as accuracy_score,
    JSON_OBJECT(
      'symbol': 'BTCUSDT',
      'forecast_horizon': '24h',
      'confidence': f.confidence
    )
  FROM forecast_results f
  JOIN postgres_db.crypto_data.prices p ON p.symbol = f.symbol
  WHERE f.model_name = 'btc_forecast_short'
  AND f.forecast_timestamp = p.timestamp
  AND f.created_at > NOW() - INTERVAL '25 hours';
) EVERY 1 day;

-- ============================================
-- 13. Create Views for Easy Access
-- ============================================

-- Current market overview
CREATE VIEW IF NOT EXISTS market_overview AS
SELECT 
    symbol,
    price as current_price,
    price_change_24h,
    volume as volume_24h,
    market_cap,
    high_24h,
    low_24h,
    (high_24h - low_24h) / low_24h * 100 as volatility_24h
FROM postgres_db.crypto_data.prices
WHERE timestamp = (SELECT MAX(timestamp) FROM postgres_db.crypto_data.prices);

-- Agent performance dashboard
CREATE VIEW IF NOT EXISTS agent_performance AS
SELECT 
    agent_name,
    COUNT(*) as total_predictions,
    AVG(accuracy_score) as avg_accuracy,
    MIN(accuracy_score) as min_accuracy,
    MAX(accuracy_score) as max_accuracy,
    STD(accuracy_score) as accuracy_std_dev
FROM prediction_accuracy
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY agent_name;

-- Active alerts view
CREATE VIEW IF NOT EXISTS active_alerts AS
SELECT 
    alert_type,
    symbol,
    details->>'severity' as severity,
    detected_at,
    details
FROM alerts
WHERE detected_at > NOW() - INTERVAL '24 hours'
ORDER BY 
    CASE details->>'severity'
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        ELSE 4
    END,
    detected_at DESC;

-- ============================================
-- 14. Test Queries
-- ============================================

-- Test market intelligence
SELECT * FROM market_intelligence_master
WHERE query = 'What is the current market outlook for Bitcoin?'
AND market_data = (SELECT * FROM market_overview WHERE symbol = 'BTCUSDT')
LIMIT 1;

-- Test BTC forecast
SELECT * FROM btc_forecast_short
WHERE symbol = 'BTCUSDT'
LIMIT 24;

-- Test anomaly detection
SELECT * FROM anomaly_detection_agent
WHERE symbol IN ('BTCUSDT', 'ETHUSDT')
ORDER BY anomaly_score DESC
LIMIT 10;

-- Test sentiment analysis
SELECT * FROM crypto_sentiment_analyzer
WHERE social_text = 'Bitcoin is looking bullish! Major breakout incoming 🚀'
AND platform = 'twitter'
LIMIT 1; 