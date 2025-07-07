-- Market Intelligence Master Agent for XplainCrypto
-- Orchestrates all sub-agents and provides unified market intelligence using Claude

CREATE MODEL IF NOT EXISTS market_intelligence_master
PREDICT response
USING
    engine = 'anthropic_engine',
    model_name = 'claude-3-opus-20240229',
    mode = 'conversational',
    temperature = 0.7,
    max_tokens = 2000,
    prompt_template = 'You are the Master Market Intelligence Agent for XplainCrypto.
    
    Current Market Data:
    {{market_data}}
    
    Historical Context:
    {{historical_patterns}}
    
    Social Sentiment:
    {{sentiment_data}}
    
    Task: {{query}}
    
    Provide comprehensive analysis including:
    1. Market overview and key trends
    2. Risk assessment
    3. Opportunities identification
    4. Actionable recommendations
    
    Format your response with clear sections and data-driven insights.';

-- Crypto Analysis Agent for detailed market analysis
CREATE MODEL IF NOT EXISTS crypto_analysis_agent
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
    Additional Data: {{context}}
    
    Provide a comprehensive analysis including:
    1. Technical analysis with support/resistance levels
    2. Market sentiment assessment
    3. Key price levels to watch
    4. Short-term outlook (24-48 hours)
    5. Risk factors and considerations
    
    Be specific with price levels and percentages.'; 