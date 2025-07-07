-- XplainCrypto MindsDB Complete Initialization
-- Databases, Models, and Agents

-- Create crypto data connections
CREATE DATABASE coinmarketcap_db
WITH ENGINE = 'coinmarketcap',
PARAMETERS = {
    "api_key": "{{ COINMARKETCAP_API_KEY }}"
};

-- Create AI engines  
CREATE ML_ENGINE anthropic_engine
FROM anthropic
USING
    api_key = "{{ ANTHROPIC_API_KEY }}";

-- Create prediction agent
CREATE MODEL crypto_prediction_agent
PREDICT response
USING
    engine = 'anthropic_engine',
    model_name = 'claude-3-sonnet',
    prompt_template = 'You are a crypto prediction specialist...'; 