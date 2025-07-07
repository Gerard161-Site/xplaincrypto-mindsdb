
-- XplainCrypto Crypto Market Intelligence Knowledge Base
-- This KB stores and processes comprehensive crypto market data, news, and analysis

-- Create embedding model for crypto market content
CREATE MODEL crypto_market_embedding
PREDICT embedding
USING
    engine = 'openai_engine',
    model_name = 'text-embedding-3-large',
    input_columns = ['content'];

-- Create vector database for market intelligence storage
CREATE DATABASE crypto_market_vectordb
WITH ENGINE = 'chromadb',
PARAMETERS = {
    "persist_directory": "/var/lib/mindsdb/crypto_market_vectors"
};

-- Create the Crypto Market Intelligence Knowledge Base
CREATE KNOWLEDGE BASE crypto_market_intel
USING
    model = crypto_market_embedding,
    storage = crypto_market_vectordb.market_intelligence,
    content_columns = ['content', 'analysis', 'summary'],
    metadata_columns = ['source', 'timestamp', 'asset', 'category', 'sentiment_score', 'importance_level'],
    id_column = 'content_id',
    description = 'Comprehensive crypto market intelligence including price analysis, news, trends, and expert insights';

-- Populate with historical market analysis data
INSERT INTO crypto_market_intel (
    content_id,
    content,
    analysis,
    summary,
    source,
    timestamp,
    asset,
    category,
    sentiment_score,
    importance_level
)
SELECT 
    CONCAT('market_', ROW_NUMBER() OVER (ORDER BY date)) as content_id,
    CONCAT(
        'Market Analysis for ', symbol, ' on ', date, ': ',
        'Price: $', price, ', Volume: ', volume, ', ',
        'Market Cap: $', market_cap, ', ',
        'Price Change 24h: ', price_change_24h, '%'
    ) as content,
    CONCAT(
        'Technical Analysis: ',
        CASE 
            WHEN price_change_24h > 5 THEN 'Strong bullish momentum with high volume support'
            WHEN price_change_24h > 0 THEN 'Positive price action with moderate buying pressure'
            WHEN price_change_24h > -5 THEN 'Consolidation phase with mixed signals'
            ELSE 'Bearish pressure with potential support levels being tested'
        END
    ) as analysis,
    CONCAT(
        'Summary: ', symbol, ' ',
        CASE 
            WHEN price_change_24h > 0 THEN 'gained'
            ELSE 'lost'
        END,
        ' ', ABS(price_change_24h), '% in 24h trading'
    ) as summary,
    'crypto_data_db' as source,
    date as timestamp,
    symbol as asset,
    'price_analysis' as category,
    CASE 
        WHEN price_change_24h > 5 THEN 0.8
        WHEN price_change_24h > 0 THEN 0.6
        WHEN price_change_24h > -5 THEN 0.4
        ELSE 0.2
    END as sentiment_score,
    CASE 
        WHEN symbol IN ('BTC', 'ETH') THEN 'high'
        WHEN market_cap > 1000000000 THEN 'medium'
        ELSE 'low'
    END as importance_level
FROM crypto_data_db.historical_prices 
WHERE date >= DATE_SUB(NOW(), INTERVAL 30 DAY)
LIMIT 1000;

-- Add DeFi protocol analysis
INSERT INTO crypto_market_intel (
    content_id,
    content,
    analysis,
    summary,
    source,
    timestamp,
    asset,
    category,
    sentiment_score,
    importance_level
)
SELECT 
    CONCAT('defi_', protocol_id) as content_id,
    CONCAT(
        'DeFi Protocol Analysis: ', protocol_name, ' - ',
        'TVL: $', tvl, ', Volume 24h: $', volume_24h, ', ',
        'Users: ', active_users, ', Fees: $', fees_24h
    ) as content,
    CONCAT(
        'Protocol Health: ',
        CASE 
            WHEN tvl_change_7d > 10 THEN 'Excellent growth with strong user adoption'
            WHEN tvl_change_7d > 0 THEN 'Steady growth indicating healthy protocol'
            WHEN tvl_change_7d > -10 THEN 'Stable with minor fluctuations'
            ELSE 'Declining TVL requires attention'
        END
    ) as analysis,
    CONCAT(protocol_name, ' shows ', ABS(tvl_change_7d), '% TVL change over 7 days') as summary,
    'defi_data' as source,
    updated_at as timestamp,
    protocol_name as asset,
    'defi_analysis' as category,
    CASE 
        WHEN tvl_change_7d > 10 THEN 0.9
        WHEN tvl_change_7d > 0 THEN 0.7
        WHEN tvl_change_7d > -10 THEN 0.5
        ELSE 0.3
    END as sentiment_score,
    CASE 
        WHEN tvl > 1000000000 THEN 'high'
        WHEN tvl > 100000000 THEN 'medium'
        ELSE 'low'
    END as importance_level
FROM crypto_data_db.defi_protocols 
WHERE updated_at >= DATE_SUB(NOW(), INTERVAL 7 DAY);

-- Add news sentiment analysis
INSERT INTO crypto_market_intel (
    content_id,
    content,
    analysis,
    summary,
    source,
    timestamp,
    asset,
    category,
    sentiment_score,
    importance_level
)
SELECT 
    CONCAT('news_', news_id) as content_id,
    CONCAT(title, '. ', content) as content,
    CONCAT(
        'News Impact Analysis: ',
        CASE 
            WHEN sentiment_score > 0.7 THEN 'Highly positive news likely to drive bullish sentiment'
            WHEN sentiment_score > 0.3 THEN 'Moderately positive news with potential upside'
            WHEN sentiment_score > -0.3 THEN 'Neutral news with limited market impact'
            WHEN sentiment_score > -0.7 THEN 'Moderately negative news may create selling pressure'
            ELSE 'Highly negative news likely to cause significant market reaction'
        END
    ) as analysis,
    LEFT(title, 200) as summary,
    source_url as source,
    published_at as timestamp,
    COALESCE(mentioned_assets, 'GENERAL') as asset,
    'news_analysis' as category,
    sentiment_score,
    CASE 
        WHEN source_reliability > 0.8 THEN 'high'
        WHEN source_reliability > 0.5 THEN 'medium'
        ELSE 'low'
    END as importance_level
FROM crypto_data_db.crypto_news 
WHERE published_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
AND sentiment_score IS NOT NULL;

-- Create view for easy querying of market intelligence
CREATE VIEW crypto_market_intel_summary AS
SELECT 
    asset,
    category,
    AVG(sentiment_score) as avg_sentiment,
    COUNT(*) as total_entries,
    MAX(timestamp) as latest_update,
    importance_level
FROM crypto_market_intel
WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY asset, category, importance_level
ORDER BY avg_sentiment DESC, total_entries DESC;

-- Test the knowledge base with sample queries
-- Query 1: Get Bitcoin market sentiment
SELECT content, analysis, sentiment_score
FROM crypto_market_intel
WHERE asset = 'BTC' 
AND category = 'price_analysis'
ORDER BY timestamp DESC
LIMIT 5;

-- Query 2: Search for DeFi trends
SELECT content, analysis, summary
FROM crypto_market_intel
WHERE content LIKE '%DeFi%' 
AND sentiment_score > 0.6
ORDER BY timestamp DESC
LIMIT 10;

-- Query 3: Get high-importance market events
SELECT asset, content, analysis, importance_level
FROM crypto_market_intel
WHERE importance_level = 'high'
AND timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
ORDER BY sentiment_score DESC;

-- Create indexes for performance optimization
CREATE INDEX idx_crypto_market_asset ON crypto_market_intel(asset);
CREATE INDEX idx_crypto_market_timestamp ON crypto_market_intel(timestamp);
CREATE INDEX idx_crypto_market_category ON crypto_market_intel(category);
CREATE INDEX idx_crypto_market_sentiment ON crypto_market_intel(sentiment_score);
CREATE INDEX idx_crypto_market_importance ON crypto_market_intel(importance_level);

-- Success validation query
SELECT 
    'Crypto Market Intelligence KB' as component,
    COUNT(*) as total_entries,
    COUNT(DISTINCT asset) as unique_assets,
    COUNT(DISTINCT category) as categories,
    AVG(sentiment_score) as avg_sentiment,
    MAX(timestamp) as latest_entry
FROM crypto_market_intel;
