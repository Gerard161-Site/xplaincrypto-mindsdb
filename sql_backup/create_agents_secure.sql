-- XplainCrypto Advanced AI Agents Deployment Script (SECURE VERSION)
-- This script creates all the AI agents using MindsDB with environment variables

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
  model_name = 'claude-3-sonnet-20241022',
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
-- 4. DeFi Yield Optimization Agent
-- ============================================
CREATE MODEL IF NOT EXISTS defi_yield_optimizer
USING
  engine = 'openai',
  model_name = 'gpt-4',
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
-- 5. Sentiment Analysis Agent
-- ============================================
CREATE MODEL IF NOT EXISTS crypto_sentiment_analyzer
USING
  engine = 'anthropic',
  model_name = 'claude-3-sonnet-20241022',
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
-- 6. Risk Management Agent
-- ============================================
CREATE MODEL IF NOT EXISTS risk_management_agent
USING
  engine = 'openai',
  model_name = 'gpt-4',
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
-- 7. Technical Analysis Agent
-- ============================================
CREATE MODEL IF NOT EXISTS technical_analysis_agent
USING
  engine = 'openai',
  model_name = 'gpt-4',
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
-- 8. Agent Orchestrator
-- ============================================
CREATE MODEL IF NOT EXISTS agent_orchestrator
USING
  engine = 'anthropic',
  model_name = 'claude-3-sonnet-20241022',
  api_key = '{{ANTHROPIC_API_KEY}}',
  mode = 'conversational',
  prompt_template = 'You are the Master Agent Orchestrator for XplainCrypto.
    
User Query: {{query}}
User Context: {{user_context}}
Available Agents: [
  "market_intelligence_master",
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
-- 9. Create Supporting Tables
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
-- 10. Create Views for Easy Access
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