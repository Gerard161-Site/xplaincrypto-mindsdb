-- Sentiment Analysis Agent for XplainCrypto
-- Real-time social sentiment analysis across multiple platforms

CREATE MODEL IF NOT EXISTS crypto_sentiment_analyzer
PREDICT sentiment_analysis
USING
    engine = 'anthropic_engine',
    model_name = 'claude-3-sonnet-20240229',
    temperature = 0.6,
    max_tokens = 1000,
    prompt_template = 'Analyze cryptocurrency sentiment from social media:
    
    Text: {{social_text}}
    Source: {{platform}}
    Author Influence Score: {{author_score}}
    Engagement Metrics: {{engagement}}
    
    Return a JSON response with:
    {
        "sentiment": "bullish/bearish/neutral",
        "confidence": 0.0-1.0,
        "sentiment_score": -1.0 to 1.0,
        "key_topics": ["topic1", "topic2", ...],
        "mentioned_tokens": ["BTC", "ETH", ...],
        "influencer_score": 0-10,
        "manipulation_risk": 0.0-1.0,
        "reasoning": "Brief explanation",
        "market_impact": "low/medium/high"
    }
    
    Consider pump-and-dump indicators, coordinated shilling, and FUD campaigns.'; 