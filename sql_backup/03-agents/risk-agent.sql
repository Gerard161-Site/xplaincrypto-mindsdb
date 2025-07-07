-- Risk Management Agent for XplainCrypto
-- Portfolio risk assessment and management using GPT-4

CREATE MODEL IF NOT EXISTS crypto_risk_agent
PREDICT risk_assessment
USING
    engine = 'openai_engine',
    model_name = 'gpt-4-turbo-preview',
    mode = 'conversational',
    temperature = 0.7,
    max_tokens = 1500,
    prompt_template = 'You are a cryptocurrency risk assessment specialist.
    
    Analyze the portfolio risk:
    
    Portfolio: {{portfolio}}
    Market Conditions: {{market_state}}
    Correlation Matrix: {{correlations}}
    VaR Calculation: {{var_data}}
    
    Provide:
    1. Overall risk score (1-10, where 10 is highest risk)
    2. Specific vulnerabilities and exposure analysis
    3. Hedging recommendations with specific instruments
    4. Rebalancing suggestions with target allocations
    5. Stop-loss levels for each position
    
    Format response as structured JSON with clear metrics.';

-- DeFi Yield Optimization Agent
CREATE MODEL IF NOT EXISTS defi_yield_optimizer
PREDICT optimal_strategy
USING
    engine = 'openai_engine',
    model_name = 'gpt-4-turbo-preview',
    temperature = 0.6,
    max_tokens = 1500,
    prompt_template = 'Analyze DeFi yield opportunities across protocols:
    
    Current Yields:
    {{yield_data}}
    
    Risk Metrics:
    {{risk_scores}}
    
    Gas Costs:
    {{gas_prices}}
    
    User Profile:
    - Risk tolerance: {{risk_tolerance}}
    - Capital: ${{capital}}
    - Time horizon: {{time_horizon}}
    
    Recommend optimal yield strategies with:
    1. Risk-adjusted returns calculation
    2. Gas cost analysis
    3. Impermanent loss considerations
    4. Protocol safety scores
    5. Step-by-step implementation guide
    
    Prioritize safety and sustainable yields.'; 