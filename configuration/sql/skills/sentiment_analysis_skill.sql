
-- XplainCrypto Sentiment Analysis Skill
-- Reusable AI skill for analyzing market sentiment, social media trends, and news impact

-- Create sentiment analysis model for crypto content
CREATE MODEL crypto_sentiment_analyzer
PREDICT sentiment_score, sentiment_label, confidence_score
USING
    engine = 'openai_engine',
    model_name = 'gpt-4',
    prompt_template = 'Analyze the sentiment of this crypto-related text: "{{text}}". 
    Consider market impact, emotional tone, and trading implications. 
    Return sentiment score (-1 to 1), sentiment label (very_negative, negative, neutral, positive, very_positive), 
    and confidence score (0 to 1).',
    input_columns = ['text'],
    max_tokens = 150,
    temperature = 0.1;

-- Create the sentiment analysis skill
CREATE SKILL sentiment_analysis_skill
USING
    type = 'text2sql',
    database = 'crypto_data_db',
    tables = [
        'social_sentiment',
        'crypto_news_real_time',
        'market_sentiment_analysis',
        'social_media_mentions',
        'news_impact_scores'
    ],
    description = 'Advanced sentiment analysis for cryptocurrency markets including social media sentiment, news impact analysis, and market emotion tracking. Provides real-time sentiment scores and trend analysis.';

-- Create sentiment analysis helper tables
CREATE TABLE crypto_data_db.sentiment_keywords (
    keyword_id INT AUTO_INCREMENT PRIMARY KEY,
    keyword VARCHAR(100),
    category VARCHAR(50),
    sentiment_weight DECIMAL(3,2),
    market_impact VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO crypto_data_db.sentiment_keywords VALUES
(NULL, 'bullish', 'market_direction', 0.8, 'high', NOW()),
(NULL, 'bearish', 'market_direction', -0.8, 'high', NOW()),
(NULL, 'moon', 'price_movement', 0.9, 'medium', NOW()),
(NULL, 'crash', 'price_movement', -0.9, 'high', NOW()),
(NULL, 'pump', 'price_movement', 0.7, 'medium', NOW()),
(NULL, 'dump', 'price_movement', -0.7, 'medium', NOW()),
(NULL, 'hodl', 'strategy', 0.6, 'medium', NOW()),
(NULL, 'fud', 'market_emotion', -0.8, 'high', NOW()),
(NULL, 'fomo', 'market_emotion', 0.5, 'medium', NOW()),
(NULL, 'diamond hands', 'strategy', 0.7, 'medium', NOW()),
(NULL, 'paper hands', 'strategy', -0.5, 'low', NOW()),
(NULL, 'rug pull', 'risk', -0.9, 'high', NOW()),
(NULL, 'scam', 'risk', -0.9, 'high', NOW()),
(NULL, 'adoption', 'growth', 0.8, 'high', NOW()),
(NULL, 'regulation', 'policy', -0.3, 'high', NOW()),
(NULL, 'innovation', 'technology', 0.7, 'medium', NOW()),
(NULL, 'partnership', 'business', 0.6, 'medium', NOW()),
(NULL, 'hack', 'security', -0.8, 'high', NOW()),
(NULL, 'upgrade', 'technology', 0.6, 'medium', NOW()),
(NULL, 'mainnet', 'technology', 0.7, 'medium', NOW());

-- Create sentiment analysis functions
DELIMITER //

CREATE FUNCTION calculate_text_sentiment(text_input TEXT)
RETURNS DECIMAL(3,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE sentiment_score DECIMAL(3,2) DEFAULT 0;
    DECLARE keyword_count INT DEFAULT 0;
    
    SELECT 
        SUM(sentiment_weight * 
            (LENGTH(LOWER(text_input)) - LENGTH(REPLACE(LOWER(text_input), LOWER(keyword), ''))) / LENGTH(keyword)
        ) / COUNT(*),
        COUNT(*)
    INTO sentiment_score, keyword_count
    FROM crypto_data_db.sentiment_keywords
    WHERE LOWER(text_input) LIKE CONCAT('%', LOWER(keyword), '%');
    
    -- Normalize sentiment score
    SET sentiment_score = GREATEST(-1, LEAST(1, COALESCE(sentiment_score, 0)));
    
    RETURN sentiment_score;
END //

CREATE FUNCTION get_sentiment_label(sentiment_score DECIMAL(3,2))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    RETURN CASE 
        WHEN sentiment_score > 0.6 THEN 'very_positive'
        WHEN sentiment_score > 0.2 THEN 'positive'
        WHEN sentiment_score > -0.2 THEN 'neutral'
        WHEN sentiment_score > -0.6 THEN 'negative'
        ELSE 'very_negative'
    END;
END //

CREATE FUNCTION analyze_market_fear_greed(asset_symbol VARCHAR(10))
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE fear_greed_data JSON;
    
    SELECT JSON_OBJECT(
        'asset', asset_symbol,
        'fear_greed_index', 
        CASE 
            WHEN AVG(sentiment_score) > 0.5 THEN 'Extreme Greed'
            WHEN AVG(sentiment_score) > 0.2 THEN 'Greed'
            WHEN AVG(sentiment_score) > -0.2 THEN 'Neutral'
            WHEN AVG(sentiment_score) > -0.5 THEN 'Fear'
            ELSE 'Extreme Fear'
        END,
        'sentiment_score', ROUND(AVG(sentiment_score), 2),
        'mention_count', COUNT(*),
        'trend', 
        CASE 
            WHEN AVG(sentiment_score) > LAG(AVG(sentiment_score)) OVER (ORDER BY DATE(last_updated)) THEN 'improving'
            WHEN AVG(sentiment_score) < LAG(AVG(sentiment_score)) OVER (ORDER BY DATE(last_updated)) THEN 'declining'
            ELSE 'stable'
        END
    )
    INTO fear_greed_data
    FROM crypto_data_db.social_sentiment
    WHERE asset_symbol = asset_symbol
    AND last_updated >= DATE_SUB(NOW(), INTERVAL 24 HOUR);
    
    RETURN COALESCE(fear_greed_data, JSON_OBJECT('error', 'No data available'));
END //

DELIMITER ;

-- Create sentiment analysis views
CREATE VIEW real_time_sentiment_dashboard AS
SELECT 
    ss.asset_symbol,
    COUNT(*) as total_mentions,
    AVG(ss.sentiment_score) as avg_sentiment,
    STDDEV(ss.sentiment_score) as sentiment_volatility,
    SUM(ss.mention_count) as total_social_mentions,
    AVG(ss.engagement_score) as avg_engagement,
    MAX(ss.last_updated) as latest_update,
    get_sentiment_label(AVG(ss.sentiment_score)) as sentiment_label,
    CASE 
        WHEN AVG(ss.sentiment_score) > 0.5 AND STDDEV(ss.sentiment_score) < 0.3 THEN 'Strong Bullish'
        WHEN AVG(ss.sentiment_score) > 0.2 AND STDDEV(ss.sentiment_score) < 0.4 THEN 'Bullish'
        WHEN AVG(ss.sentiment_score) > -0.2 AND STDDEV(ss.sentiment_score) < 0.3 THEN 'Neutral'
        WHEN AVG(ss.sentiment_score) < -0.2 AND STDDEV(ss.sentiment_score) < 0.4 THEN 'Bearish'
        WHEN AVG(ss.sentiment_score) < -0.5 AND STDDEV(ss.sentiment_score) < 0.3 THEN 'Strong Bearish'
        ELSE 'Volatile/Uncertain'
    END as market_sentiment_signal
FROM crypto_data_db.social_sentiment ss
WHERE ss.last_updated >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY ss.asset_symbol
ORDER BY avg_sentiment DESC, total_mentions DESC;

CREATE VIEW news_sentiment_impact AS
SELECT 
    n.mentioned_assets,
    COUNT(*) as news_count,
    AVG(n.sentiment_score) as avg_news_sentiment,
    AVG(n.impact_score) as avg_impact_score,
    SUM(CASE WHEN n.sentiment_score > 0.5 THEN 1 ELSE 0 END) as positive_news,
    SUM(CASE WHEN n.sentiment_score < -0.5 THEN 1 ELSE 0 END) as negative_news,
    MAX(n.published_at) as latest_news,
    GROUP_CONCAT(DISTINCT n.category) as news_categories,
    AVG(n.source_reliability) as avg_source_reliability,
    CASE 
        WHEN AVG(n.sentiment_score) > 0.3 AND AVG(n.impact_score) > 0.6 THEN 'Highly Positive Impact'
        WHEN AVG(n.sentiment_score) > 0.1 AND AVG(n.impact_score) > 0.4 THEN 'Positive Impact'
        WHEN AVG(n.sentiment_score) > -0.1 AND AVG(n.impact_score) > 0.3 THEN 'Neutral Impact'
        WHEN AVG(n.sentiment_score) < -0.1 AND AVG(n.impact_score) > 0.4 THEN 'Negative Impact'
        ELSE 'Highly Negative Impact'
    END as news_impact_assessment
FROM crypto_data_db.crypto_news_real_time n
WHERE n.published_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
AND n.mentioned_assets IS NOT NULL
GROUP BY n.mentioned_assets
ORDER BY avg_impact_score DESC, news_count DESC;

CREATE VIEW sentiment_trend_analysis AS
SELECT 
    asset_symbol,
    DATE(last_updated) as sentiment_date,
    AVG(sentiment_score) as daily_avg_sentiment,
    COUNT(*) as daily_mentions,
    AVG(engagement_score) as daily_avg_engagement,
    LAG(AVG(sentiment_score)) OVER (PARTITION BY asset_symbol ORDER BY DATE(last_updated)) as prev_day_sentiment,
    (AVG(sentiment_score) - LAG(AVG(sentiment_score)) OVER (PARTITION BY asset_symbol ORDER BY DATE(last_updated))) as sentiment_change,
    CASE 
        WHEN (AVG(sentiment_score) - LAG(AVG(sentiment_score)) OVER (PARTITION BY asset_symbol ORDER BY DATE(last_updated))) > 0.1 THEN 'Improving'
        WHEN (AVG(sentiment_score) - LAG(AVG(sentiment_score)) OVER (PARTITION BY asset_symbol ORDER BY DATE(last_updated))) < -0.1 THEN 'Declining'
        ELSE 'Stable'
    END as sentiment_trend
FROM crypto_data_db.social_sentiment
WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY asset_symbol, DATE(last_updated)
ORDER BY asset_symbol, sentiment_date DESC;

-- Create sentiment analysis query templates
CREATE TABLE crypto_data_db.sentiment_analysis_templates (
    template_id VARCHAR(50) PRIMARY KEY,
    template_name VARCHAR(200),
    description TEXT,
    sql_template TEXT,
    parameters JSON,
    example_usage TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO crypto_data_db.sentiment_analysis_templates VALUES
('current_sentiment',
 'Current market sentiment for asset',
 'Get current sentiment analysis for a specific cryptocurrency',
 'SELECT asset_symbol, avg_sentiment, sentiment_label, total_mentions, market_sentiment_signal FROM real_time_sentiment_dashboard WHERE asset_symbol = "{asset}" ORDER BY latest_update DESC LIMIT 1',
 '{"asset": "BTC"}',
 'What is the current sentiment for Bitcoin?',
 NOW()),

('sentiment_comparison',
 'Compare sentiment between assets',
 'Compare sentiment scores between multiple cryptocurrencies',
 'SELECT asset_symbol, avg_sentiment, sentiment_label, total_mentions FROM real_time_sentiment_dashboard WHERE asset_symbol IN ({assets}) ORDER BY avg_sentiment DESC',
 '{"assets": ["BTC", "ETH", "ADA"]}',
 'Compare sentiment between Bitcoin, Ethereum, and Cardano',
 NOW()),

('sentiment_trend',
 'Sentiment trend analysis',
 'Analyze sentiment trends over time for an asset',
 'SELECT sentiment_date, daily_avg_sentiment, sentiment_change, sentiment_trend FROM sentiment_trend_analysis WHERE asset_symbol = "{asset}" AND sentiment_date >= DATE_SUB(CURDATE(), INTERVAL {days} DAY) ORDER BY sentiment_date DESC',
 '{"asset": "ETH", "days": 7}',
 'Show Ethereum sentiment trend for the last 7 days',
 NOW()),

('news_impact',
 'News sentiment impact analysis',
 'Analyze how news sentiment is impacting specific assets',
 'SELECT mentioned_assets, avg_news_sentiment, avg_impact_score, positive_news, negative_news, news_impact_assessment FROM news_sentiment_impact WHERE mentioned_assets LIKE "%{asset}%" ORDER BY avg_impact_score DESC',
 '{"asset": "BTC"}',
 'How is news sentiment impacting Bitcoin?',
 NOW()),

('fear_greed_index',
 'Fear and Greed Index analysis',
 'Calculate fear and greed index for market sentiment',
 'SELECT asset_symbol, analyze_market_fear_greed(asset_symbol) as fear_greed_analysis FROM (SELECT DISTINCT asset_symbol FROM crypto_data_db.social_sentiment WHERE asset_symbol = "{asset}" AND last_updated >= DATE_SUB(NOW(), INTERVAL 24 HOUR)) assets',
 '{"asset": "BTC"}',
 'What is the fear and greed index for Bitcoin?',
 NOW()),

('sentiment_alerts',
 'Sentiment-based alerts',
 'Identify assets with extreme sentiment changes',
 'SELECT asset_symbol, daily_avg_sentiment, sentiment_change, sentiment_trend FROM sentiment_trend_analysis WHERE ABS(sentiment_change) > {threshold} AND sentiment_date = CURDATE() ORDER BY ABS(sentiment_change) DESC',
 '{"threshold": 0.3}',
 'Show assets with significant sentiment changes today',
 NOW()),

('social_engagement',
 'Social media engagement analysis',
 'Analyze social media engagement and its correlation with sentiment',
 'SELECT asset_symbol, total_mentions, avg_sentiment, avg_engagement, sentiment_label FROM real_time_sentiment_dashboard WHERE total_mentions > {min_mentions} ORDER BY avg_engagement DESC LIMIT {limit}',
 '{"min_mentions": 100, "limit": 10}',
 'Show top 10 assets by social engagement with significant mention volume',
 NOW()),

('sentiment_volatility',
 'Sentiment volatility analysis',
 'Identify assets with high sentiment volatility',
 'SELECT asset_symbol, avg_sentiment, sentiment_volatility, market_sentiment_signal FROM real_time_sentiment_dashboard WHERE sentiment_volatility > {threshold} ORDER BY sentiment_volatility DESC LIMIT {limit}',
 '{"threshold": 0.4, "limit": 10}',
 'Show assets with high sentiment volatility',
 NOW());

-- Create sentiment analysis performance tracking
CREATE TABLE crypto_data_db.sentiment_analysis_performance (
    analysis_id INT AUTO_INCREMENT PRIMARY KEY,
    asset_symbol VARCHAR(10),
    analysis_type VARCHAR(50),
    sentiment_score DECIMAL(3,2),
    confidence_score DECIMAL(3,2),
    data_sources_count INT,
    processing_time_ms INT,
    accuracy_feedback DECIMAL(3,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create real-time sentiment processing job
CREATE JOB real_time_sentiment_processing AS (
    -- Process new social media mentions
    INSERT INTO crypto_data_db.processed_sentiment (
        source_id,
        asset_symbol,
        platform,
        content,
        sentiment_score,
        sentiment_label,
        confidence_score,
        engagement_metrics,
        processed_at
    )
    SELECT 
        si.interaction_id as source_id,
        COALESCE(si.mentioned_asset, 'GENERAL') as asset_symbol,
        'social_media' as platform,
        si.content,
        calculate_text_sentiment(si.content) as sentiment_score,
        get_sentiment_label(calculate_text_sentiment(si.content)) as sentiment_label,
        CASE 
            WHEN LENGTH(si.content) > 100 AND si.likes_count + si.comments_count > 10 THEN 0.9
            WHEN LENGTH(si.content) > 50 AND si.likes_count + si.comments_count > 5 THEN 0.7
            ELSE 0.5
        END as confidence_score,
        JSON_OBJECT(
            'likes', si.likes_count,
            'comments', si.comments_count,
            'shares', COALESCE(si.shares_count, 0),
            'engagement_rate', (si.likes_count + si.comments_count) / GREATEST(si.follower_count, 1)
        ) as engagement_metrics,
        NOW() as processed_at
    FROM user_data_db.social_interactions si
    WHERE si.created_at > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 15 MINUTE))
    AND LENGTH(si.content) > 20
    AND si.sentiment_score IS NULL;
    
    -- Process news articles
    INSERT INTO crypto_data_db.processed_sentiment (
        source_id,
        asset_symbol,
        platform,
        content,
        sentiment_score,
        sentiment_label,
        confidence_score,
        engagement_metrics,
        processed_at
    )
    SELECT 
        CONCAT('news_', n.news_id) as source_id,
        COALESCE(n.mentioned_assets, 'GENERAL') as asset_symbol,
        'news' as platform,
        CONCAT(n.title, '. ', LEFT(n.content, 500)) as content,
        n.sentiment_score,
        get_sentiment_label(n.sentiment_score) as sentiment_label,
        n.source_reliability as confidence_score,
        JSON_OBJECT(
            'impact_score', n.impact_score,
            'source_reliability', n.source_reliability,
            'category', n.category
        ) as engagement_metrics,
        NOW() as processed_at
    FROM crypto_data_db.crypto_news_real_time n
    WHERE n.published_at > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 30 MINUTE))
    AND n.sentiment_score IS NOT NULL;
)
EVERY 10 minutes;

-- Test the sentiment analysis skill
SELECT 
    'Sentiment Analysis Skill Test' as test_type,
    COUNT(*) as total_sentiment_records,
    COUNT(DISTINCT asset_symbol) as assets_with_sentiment,
    AVG(sentiment_score) as overall_market_sentiment,
    MAX(last_updated) as latest_sentiment_data
FROM crypto_data_db.social_sentiment
WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 24 HOUR);

-- Test sentiment calculation functions
SELECT 
    'Sentiment Function Test' as test_type,
    calculate_text_sentiment('Bitcoin is going to the moon! Very bullish on crypto adoption.') as positive_test,
    calculate_text_sentiment('Crypto crash incoming, this is a scam, pure FUD.') as negative_test,
    calculate_text_sentiment('Bitcoin price is stable today.') as neutral_test;

-- Test fear and greed analysis
SELECT 
    'Fear Greed Analysis Test' as test_type,
    asset_symbol,
    analyze_market_fear_greed(asset_symbol) as fear_greed_data
FROM (
    SELECT DISTINCT asset_symbol 
    FROM crypto_data_db.social_sentiment 
    WHERE asset_symbol IN ('BTC', 'ETH') 
    AND last_updated >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
    LIMIT 2
) test_assets;

-- Success validation
SELECT 'Sentiment Analysis Skill created successfully' as status;

SELECT 
    'Sentiment Analysis Summary' as summary_type,
    COUNT(*) as total_sentiment_entries,
    COUNT(DISTINCT asset_symbol) as assets_tracked,
    AVG(sentiment_score) as avg_market_sentiment,
    STDDEV(sentiment_score) as sentiment_volatility,
    MIN(last_updated) as earliest_data,
    MAX(last_updated) as latest_data
FROM crypto_data_db.social_sentiment
WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 7 DAY);
