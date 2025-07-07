
-- XplainCrypto AI Agents and Models Setup
-- Purpose: Create specialized AI agents for crypto analysis and prediction
-- Execute AFTER AI engines are created
-- Expected execution time: 3-5 minutes

-- ============================================================================
-- AI AGENTS AND MODELS SCRIPT
-- These agents use the engines created in the previous step
-- ============================================================================

-- Crypto Price Prediction Agent (TimeGPT)
-- Provides advanced time-series forecasting for cryptocurrency prices
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

-- Market Analysis Agent (Claude)
-- Provides comprehensive market intelligence and analysis
CREATE MODEL IF NOT EXISTS market_analysis_agent
PREDICT analysis
USING
    engine = 'anthropic_engine',
    model_name = 'claude-3-sonnet-20240229',
    temperature = 0.7,
    max_tokens = 1500,
    prompt_template = 'Analyze the following cryptocurrency data:
    
    Symbol: {{symbol}}
    Current Price: ${{price}}
    24h Change: {{change_24h}}%
    Volume: ${{volume}}
    Market Cap: ${{market_cap}}
    Additional Context: {{context}}
    
    Provide a comprehensive analysis including:
    1. Technical analysis with support/resistance levels
    2. Market sentiment assessment
    3. Key price levels to watch
    4. Short-term outlook (24-48 hours)
    5. Risk factors and considerations
    
    Be specific with price levels and percentages.';

-- Risk Assessment Agent (GPT-4)
-- Evaluates risk factors and provides risk management recommendations
CREATE MODEL IF NOT EXISTS risk_assessment_agent
PREDICT risk_analysis
USING
    engine = 'openai_engine',
    model_name = 'gpt-4',
    temperature = 0.3,
    max_tokens = 1200,
    prompt_template = 'Perform a comprehensive risk assessment for the following cryptocurrency investment:
    
    Asset: {{symbol}}
    Current Price: ${{price}}
    Position Size: {{position_size}}
    Market Data: {{market_data}}
    Portfolio Context: {{portfolio_context}}
    
    Provide detailed risk analysis including:
    1. Market risk assessment (1-10 scale)
    2. Volatility analysis and expected price ranges
    3. Liquidity risk evaluation
    4. Correlation risks with other assets
    5. Recommended position sizing
    6. Stop-loss and take-profit levels
    7. Risk mitigation strategies
    
    Format as structured analysis with specific recommendations.';

-- Sentiment Analysis Agent (GPT-4)
-- Analyzes social media and news sentiment for crypto assets
CREATE MODEL IF NOT EXISTS sentiment_analysis_agent
PREDICT sentiment_score
USING
    engine = 'openai_engine',
    model_name = 'gpt-4',
    temperature = 0.2,
    max_tokens = 800,
    prompt_template = 'Analyze the sentiment for cryptocurrency {{symbol}} based on the following data:
    
    News Headlines: {{news_data}}
    Social Media Posts: {{social_data}}
    Trading Volume: {{volume_data}}
    Price Action: {{price_action}}
    
    Provide sentiment analysis including:
    1. Overall sentiment score (-1 to +1)
    2. Bullish vs bearish indicators
    3. Key sentiment drivers
    4. Social media momentum
    5. News impact assessment
    6. Sentiment trend (improving/declining)
    
    Return structured JSON with sentiment_score, confidence_level, and key_factors.';

-- Anomaly Detection Agent (Claude)
-- Detects unusual patterns and potential market anomalies
CREATE MODEL IF NOT EXISTS anomaly_detection_agent
PREDICT anomaly_alert
USING
    engine = 'anthropic_engine',
    model_name = 'claude-3-sonnet-20240229',
    temperature = 0.1,
    max_tokens = 1000,
    prompt_template = 'Analyze the following cryptocurrency data for anomalies and unusual patterns:
    
    Symbol: {{symbol}}
    Price Data: {{price_data}}
    Volume Data: {{volume_data}}
    Market Cap Changes: {{market_cap_data}}
    Historical Patterns: {{historical_data}}
    
    Detect and report:
    1. Price anomalies (unusual spikes/drops)
    2. Volume anomalies (unusual trading activity)
    3. Market cap discrepancies
    4. Pattern breaks from historical norms
    5. Potential manipulation signals
    6. Arbitrage opportunities
    
    Rate anomaly severity (LOW/MEDIUM/HIGH) and provide actionable insights.';

-- Master Intelligence Agent (Claude Opus)
-- Orchestrates all other agents and provides unified market intelligence
CREATE MODEL IF NOT EXISTS master_intelligence_agent
PREDICT comprehensive_analysis
USING
    engine = 'anthropic_engine',
    model_name = 'claude-3-opus-20240229',
    temperature = 0.7,
    max_tokens = 2000,
    prompt_template = 'You are the Master Market Intelligence Agent for XplainCrypto.
    
    Current Market Data: {{market_data}}
    Historical Context: {{historical_patterns}}
    Social Sentiment: {{sentiment_data}}
    Risk Assessment: {{risk_data}}
    Anomaly Alerts: {{anomaly_data}}
    User Query: {{query}}
    
    Synthesize all available data and provide comprehensive market intelligence including:
    1. Executive summary of current market conditions
    2. Key opportunities and risks
    3. Actionable trading recommendations
    4. Risk management guidelines
    5. Market outlook and key levels to watch
    6. Portfolio allocation suggestions
    
    Format as a professional market intelligence report with clear sections and data-driven insights.';

-- ============================================================================
-- VERIFICATION QUERIES - Execute these to verify agents
-- ============================================================================

-- List all created models/agents
SELECT 'AI Agents Verification' as check_name;
SELECT name, engine, status, creation_date
FROM information_schema.models
WHERE name LIKE '%_agent'
ORDER BY name;

-- Verify specific agents
SELECT 'Agent Status Check' as check_name;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'crypto_prediction_agent')
        THEN 'CREATED: crypto_prediction_agent (TimeGPT Forecasting)'
        ELSE 'MISSING: crypto_prediction_agent'
    END as prediction_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'market_analysis_agent')
        THEN 'CREATED: market_analysis_agent (Claude Analysis)'
        ELSE 'MISSING: market_analysis_agent'
    END as analysis_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.models WHERE name = 'risk_assessment_agent')
        THEN 'CREATED: risk_assessment_agent (GPT-4 Risk)'
        ELSE 'MISSING: risk_assessment_agent'
    END as risk_status;

-- Check agent training status
SELECT 'Agent Training Status' as check_name;
SELECT name, status, training_log
FROM information_schema.models
WHERE name LIKE '%_agent'
AND status != 'complete';

-- ============================================================================
-- TROUBLESHOOTING:
-- ============================================================================
-- If agent creation fails:
-- 1. Ensure all AI engines were created successfully in previous step
-- 2. Check that engines have sufficient API credits
-- 3. Verify prompt templates are properly formatted
-- 4. Monitor MindsDB logs for detailed error messages
-- 5. Some agents may take 2-3 minutes to fully initialize
--
-- Agent Status Meanings:
-- - 'training': Agent is being created (normal, wait 1-2 minutes)
-- - 'complete': Agent is ready to use
-- - 'error': Check logs and retry creation
--
-- All agents use IF NOT EXISTS - safe to re-run this script
-- ============================================================================
