
-- XplainCrypto Market Analysis Knowledge Base Skill
-- Reusable AI skill for retrieving market intelligence and analysis from the knowledge base

-- Create the market analysis knowledge base skill
CREATE SKILL market_analysis_kb_skill
USING
    type = 'knowledge_base',
    source = 'crypto_market_intel',
    description = 'Comprehensive crypto market intelligence including price analysis, DeFi trends, news sentiment, and expert insights. Provides contextual market analysis for trading decisions and market understanding.';

-- Create enhanced market analysis queries and templates
CREATE TABLE crypto_data_db.market_analysis_query_templates (
    template_id VARCHAR(50) PRIMARY KEY,
    template_name VARCHAR(200),
    description TEXT,
    query_pattern TEXT,
    context_filters JSON,
    example_questions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO crypto_data_db.market_analysis_query_templates VALUES
('price_trend_analysis',
 'Price trend and momentum analysis',
 'Analyze price trends, momentum, and technical patterns for specific assets',
 'What is the current price trend and momentum for {asset}? Include technical analysis and market sentiment.',
 '{"asset_filter": "asset = \"{asset}\"", "category_filter": "category IN (\"price_analysis\", \"technical_analysis\")", "timeframe": "timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)"}',
 'What is the current price trend for Bitcoin? How is Ethereum performing technically?',
 NOW()),

('defi_protocol_analysis',
 'DeFi protocol performance and trends',
 'Analyze DeFi protocol metrics, TVL changes, and ecosystem health',
 'Analyze the performance and trends of {protocol} DeFi protocol. Include TVL analysis, user growth, and market position.',
 '{"protocol_filter": "asset = \"{protocol}\" OR content LIKE \"%{protocol}%\"", "category_filter": "category = \"defi_analysis\"", "timeframe": "timestamp >= DATE_SUB(NOW(), INTERVAL 14 DAY)"}',
 'How is Uniswap performing? What are the trends in Aave protocol?',
 NOW()),

('market_sentiment_analysis',
 'Market sentiment and news impact',
 'Analyze market sentiment, news impact, and social trends',
 'What is the current market sentiment for {asset}? Include news analysis and social media trends.',
 '{"asset_filter": "asset = \"{asset}\" OR mentioned_assets LIKE \"%{asset}%\"", "category_filter": "category IN (\"news_analysis\", \"sentiment_analysis\")", "sentiment_filter": "sentiment_score IS NOT NULL"}',
 'What is the market sentiment for Bitcoin? How is news affecting Ethereum price?',
 NOW()),

('sector_analysis',
 'Crypto sector and category analysis',
 'Analyze performance and trends within specific crypto sectors',
 'Analyze the {sector} sector in cryptocurrency. Include performance comparison, trends, and outlook.',
 '{"sector_filter": "category = \"{sector}\" OR content LIKE \"%{sector}%\"", "timeframe": "timestamp >= DATE_SUB(NOW(), INTERVAL 30 DAY)", "importance_filter": "importance_level IN (\"high\", \"medium\")"}',
 'How is the DeFi sector performing? What are the trends in Layer 1 blockchains?',
 NOW()),

('risk_assessment',
 'Risk analysis and market warnings',
 'Assess market risks, volatility, and potential warning signals',
 'What are the current risk factors and warnings for {asset} or the broader market?',
 '{"risk_filter": "sentiment_score < 0.3 OR content LIKE \"%risk%\" OR content LIKE \"%warning%\"", "category_filter": "category IN (\"risk_analysis\", \"market_analysis\")", "importance_filter": "importance_level = \"high\""}',
 'What are the risk factors for Bitcoin? Are there any market warnings?',
 NOW()),

('opportunity_identification',
 'Market opportunities and positive signals',
 'Identify market opportunities, positive trends, and growth signals',
 'What are the current opportunities and positive signals in {asset} or {sector}?',
 '{"opportunity_filter": "sentiment_score > 0.6 OR content LIKE \"%opportunity%\" OR content LIKE \"%growth%\"", "category_filter": "category IN (\"opportunity_analysis\", \"growth_analysis\")", "timeframe": "timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)"}',
 'What opportunities exist in DeFi? Are there growth signals in altcoins?',
 NOW()),

('comparative_analysis',
 'Comparative market analysis',
 'Compare performance and metrics between different assets or protocols',
 'Compare {asset1} and {asset2} in terms of performance, trends, and market position.',
 '{"comparison_filter": "asset IN (\"{asset1}\", \"{asset2}\") OR content LIKE \"%{asset1}%\" OR content LIKE \"%{asset2}%\"", "timeframe": "timestamp >= DATE_SUB(NOW(), INTERVAL 14 DAY)"}',
 'Compare Bitcoin and Ethereum performance. How does Uniswap compare to SushiSwap?',
 NOW()),

('market_overview',
 'General market overview and summary',
 'Provide comprehensive market overview and current state analysis',
 'Provide a comprehensive overview of the current cryptocurrency market state and trends.',
 '{"overview_filter": "importance_level = \"high\"", "timeframe": "timestamp >= DATE_SUB(NOW(), INTERVAL 3 DAY)", "category_filter": "category IN (\"market_analysis\", \"price_analysis\")"}',
 'What is the current state of the crypto market? Give me a market overview.',
 NOW());

-- Create market analysis helper functions
DELIMITER //

CREATE FUNCTION get_market_sentiment_summary(asset_param VARCHAR(20))
RETURNS TEXT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE sentiment_summary TEXT;
    
    SELECT 
        CONCAT(
            'Market Sentiment for ', asset_param, ': ',
            CASE 
                WHEN AVG(sentiment_score) > 0.6 THEN 'Very Positive'
                WHEN AVG(sentiment_score) > 0.3 THEN 'Positive'
                WHEN AVG(sentiment_score) > -0.3 THEN 'Neutral'
                WHEN AVG(sentiment_score) > -0.6 THEN 'Negative'
                ELSE 'Very Negative'
            END,
            ' (Score: ', ROUND(AVG(sentiment_score), 2), '). ',
            'Based on ', COUNT(*), ' recent analyses. ',
            'Key themes: ', GROUP_CONCAT(DISTINCT LEFT(analysis, 100) SEPARATOR '; ')
        )
    INTO sentiment_summary
    FROM crypto_market_intel
    WHERE asset = asset_param 
    AND timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    AND sentiment_score IS NOT NULL;
    
    RETURN COALESCE(sentiment_summary, CONCAT('No recent sentiment data available for ', asset_param));
END //

CREATE FUNCTION get_trending_topics()
RETURNS TEXT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE trending_summary TEXT;
    
    SELECT 
        CONCAT(
            'Trending Market Topics: ',
            GROUP_CONCAT(
                CONCAT(asset, ' (', category, ')') 
                ORDER BY sentiment_score DESC, timestamp DESC 
                SEPARATOR ', '
            )
        )
    INTO trending_summary
    FROM (
        SELECT 
            asset,
            category,
            AVG(sentiment_score) as sentiment_score,
            MAX(timestamp) as timestamp,
            COUNT(*) as mention_count
        FROM crypto_market_intel
        WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        AND importance_level IN ('high', 'medium')
        GROUP BY asset, category
        HAVING mention_count >= 2
        ORDER BY sentiment_score DESC, mention_count DESC
        LIMIT 10
    ) trending;
    
    RETURN COALESCE(trending_summary, 'No trending topics identified in recent data');
END //

CREATE FUNCTION get_risk_alerts()
RETURNS TEXT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE risk_summary TEXT;
    
    SELECT 
        CONCAT(
            'Current Risk Alerts: ',
            GROUP_CONCAT(
                CONCAT(asset, ' - ', LEFT(analysis, 150))
                ORDER BY sentiment_score ASC, timestamp DESC
                SEPARATOR '; '
            )
        )
    INTO risk_summary
    FROM crypto_market_intel
    WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
    AND sentiment_score < 0.3
    AND importance_level = 'high'
    AND (content LIKE '%risk%' OR content LIKE '%warning%' OR content LIKE '%alert%')
    LIMIT 5;
    
    RETURN COALESCE(risk_summary, 'No significant risk alerts in recent data');
END //

DELIMITER ;

-- Create market analysis views for quick access
CREATE VIEW market_sentiment_dashboard AS
SELECT 
    asset,
    COUNT(*) as total_mentions,
    AVG(sentiment_score) as avg_sentiment,
    MAX(timestamp) as latest_analysis,
    SUM(CASE WHEN sentiment_score > 0.5 THEN 1 ELSE 0 END) as positive_mentions,
    SUM(CASE WHEN sentiment_score < -0.5 THEN 1 ELSE 0 END) as negative_mentions,
    CASE 
        WHEN AVG(sentiment_score) > 0.5 THEN 'Bullish'
        WHEN AVG(sentiment_score) > 0 THEN 'Slightly Bullish'
        WHEN AVG(sentiment_score) > -0.5 THEN 'Slightly Bearish'
        ELSE 'Bearish'
    END as sentiment_label,
    importance_level
FROM crypto_market_intel
WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY asset, importance_level
HAVING total_mentions >= 2
ORDER BY avg_sentiment DESC, total_mentions DESC;

CREATE VIEW defi_analysis_summary AS
SELECT 
    asset as protocol_name,
    COUNT(*) as analysis_count,
    AVG(sentiment_score) as avg_sentiment,
    MAX(timestamp) as latest_update,
    GROUP_CONCAT(DISTINCT category) as analysis_categories,
    LEFT(GROUP_CONCAT(DISTINCT analysis SEPARATOR ' | '), 500) as key_insights,
    importance_level
FROM crypto_market_intel
WHERE category = 'defi_analysis'
AND timestamp >= DATE_SUB(NOW(), INTERVAL 14 DAY)
GROUP BY asset, importance_level
ORDER BY avg_sentiment DESC, analysis_count DESC;

CREATE VIEW news_impact_analysis AS
SELECT 
    asset,
    category,
    COUNT(*) as news_count,
    AVG(sentiment_score) as avg_impact_score,
    MAX(timestamp) as latest_news,
    SUM(CASE WHEN sentiment_score > 0.6 THEN 1 ELSE 0 END) as highly_positive_news,
    SUM(CASE WHEN sentiment_score < -0.6 THEN 1 ELSE 0 END) as highly_negative_news,
    LEFT(GROUP_CONCAT(DISTINCT summary SEPARATOR ' | '), 300) as recent_headlines
FROM crypto_market_intel
WHERE category = 'news_analysis'
AND timestamp >= DATE_SUB(NOW(), INTERVAL 3 DAY)
GROUP BY asset, category
ORDER BY avg_impact_score DESC, news_count DESC;

-- Create market analysis performance tracking
CREATE TABLE crypto_data_db.market_analysis_usage (
    usage_id INT AUTO_INCREMENT PRIMARY KEY,
    query_type VARCHAR(100),
    asset_queried VARCHAR(50),
    results_returned INT,
    relevance_score DECIMAL(3,2),
    user_feedback VARCHAR(20),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create sample market analysis queries for testing
CREATE VIEW sample_market_queries AS
SELECT 
    'Bitcoin Price Analysis' as query_example,
    'What is the current price trend and technical analysis for Bitcoin?' as sample_question,
    'price_trend_analysis' as template_type
UNION ALL
SELECT 
    'DeFi Sector Overview',
    'How is the DeFi sector performing? What are the key trends?',
    'sector_analysis'
UNION ALL
SELECT 
    'Market Sentiment Check',
    'What is the current market sentiment? Are there any risk factors?',
    'market_overview'
UNION ALL
SELECT 
    'Ethereum vs Bitcoin',
    'Compare Ethereum and Bitcoin performance and market position.',
    'comparative_analysis'
UNION ALL
SELECT 
    'Risk Assessment',
    'What are the current risk factors in the cryptocurrency market?',
    'risk_assessment';

-- Test the market analysis skill
SELECT 
    'Market Analysis KB Skill Test' as test_type,
    COUNT(*) as total_market_intelligence,
    COUNT(DISTINCT asset) as assets_covered,
    COUNT(DISTINCT category) as analysis_categories,
    AVG(sentiment_score) as avg_market_sentiment,
    MAX(timestamp) as latest_analysis
FROM crypto_market_intel
WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY);

-- Test sentiment analysis capability
SELECT 
    'Sentiment Analysis Test' as test_type,
    asset,
    AVG(sentiment_score) as avg_sentiment,
    COUNT(*) as analysis_count,
    CASE 
        WHEN AVG(sentiment_score) > 0.5 THEN 'Bullish'
        WHEN AVG(sentiment_score) > 0 THEN 'Slightly Bullish'
        WHEN AVG(sentiment_score) > -0.5 THEN 'Slightly Bearish'
        ELSE 'Bearish'
    END as market_outlook
FROM crypto_market_intel
WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 3 DAY)
AND asset IN ('BTC', 'ETH', 'BNB')
GROUP BY asset
ORDER BY avg_sentiment DESC;

-- Test DeFi analysis capability
SELECT 
    'DeFi Analysis Test' as test_type,
    asset as protocol,
    COUNT(*) as analysis_entries,
    AVG(sentiment_score) as protocol_sentiment,
    MAX(timestamp) as latest_analysis,
    LEFT(GROUP_CONCAT(DISTINCT analysis SEPARATOR ' | '), 200) as key_insights
FROM crypto_market_intel
WHERE category = 'defi_analysis'
AND timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY asset
ORDER BY protocol_sentiment DESC
LIMIT 5;

-- Success validation
SELECT 'Market Analysis Knowledge Base Skill created successfully' as status;

SELECT 
    'Knowledge Base Content Summary' as summary_type,
    COUNT(*) as total_entries,
    COUNT(DISTINCT asset) as unique_assets,
    COUNT(DISTINCT category) as analysis_categories,
    COUNT(DISTINCT source) as data_sources,
    MIN(timestamp) as earliest_data,
    MAX(timestamp) as latest_data
FROM crypto_market_intel;
