-- AI Engines Setup for XplainCrypto Platform
-- This script creates ML engines for TimeGPT, Anthropic, and OpenAI

-- TimeGPT Engine for advanced time-series forecasting
CREATE ML_ENGINE IF NOT EXISTS timegpt_engine
FROM timegpt
USING
    api_key = '${TIMEGPT_API_KEY}';

-- Anthropic Engine for Claude-based analysis
CREATE ML_ENGINE IF NOT EXISTS anthropic_engine
FROM anthropic
USING
    api_key = '${ANTHROPIC_API_KEY}';

-- OpenAI Engine for GPT-4 based insights
CREATE ML_ENGINE IF NOT EXISTS openai_engine
FROM openai
USING
    api_key = '${OPENAI_API_KEY}'; 