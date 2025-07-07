
-- XplainCrypto Real-Time Data Synchronization
-- Sets up real-time data feeds and synchronization jobs for live crypto data

-- Create real-time data synchronization job for market prices
CREATE JOB real_time_market_sync AS (
    -- Sync latest price data from multiple sources
    INSERT INTO crypto_data_db.real_time_prices (
        symbol,
        price,
        volume_24h,
        market_cap,
        percent_change_1h,
        percent_change_24h,
        percent_change_7d,
        last_updated,
        source,
        data_quality_score
    )
    SELECT 
        symbol,
        price,
        volume_24h,
        market_cap,
        percent_change_1h,
        percent_change_24h,
        percent_change_7d,
        NOW() as last_updated,
        'coinmarketcap' as source,
        CASE 
            WHEN volume_24h > 1000000 AND price > 0 THEN 1.0
            WHEN volume_24h > 100000 AND price > 0 THEN 0.8
            WHEN price > 0 THEN 0.6
            ELSE 0.3
        END as data_quality_score
    FROM external_apis.coinmarketcap_live
    WHERE last_updated > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 5 MINUTE))
    AND symbol IN ('BTC', 'ETH', 'BNB', 'XRP', 'ADA', 'SOL', 'DOGE', 'DOT', 'AVAX', 'MATIC')
    
    UNION ALL
    
    -- Sync from Binance API for high-frequency data
    SELECT 
        symbol,
        price,
        volume,
        NULL as market_cap,
        price_change_percent as percent_change_1h,
        price_change_percent_24h as percent_change_24h,
        NULL as percent_change_7d,
        NOW() as last_updated,
        'binance' as source,
        CASE 
            WHEN volume > 1000000 AND price > 0 THEN 1.0
            WHEN volume > 100000 AND price > 0 THEN 0.9
            WHEN price > 0 THEN 0.7
            ELSE 0.4
        END as data_quality_score
    FROM external_apis.binance_ticker_24hr
    WHERE symbol LIKE '%USDT'
    AND last_updated > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 1 MINUTE))
)
EVERY 1 minute
IF (
    SELECT COUNT(*) 
    FROM external_apis.coinmarketcap_live 
    WHERE last_updated > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 5 MINUTE))
);

-- Create DeFi protocol real-time sync job
CREATE JOB real_time_defi_sync AS (
    INSERT INTO crypto_data_db.defi_real_time (
        protocol_name,
        tvl,
        volume_24h,
        fees_24h,
        revenue_24h,
        active_users,
        transactions_24h,
        tvl_change_24h,
        last_updated,
        source,
        chain,
        category
    )
    SELECT 
        name as protocol_name,
        tvl,
        volume_24h,
        fees_24h,
        revenue_24h,
        active_users,
        transactions_24h,
        ((tvl - LAG(tvl) OVER (PARTITION BY name ORDER BY timestamp)) / LAG(tvl) OVER (PARTITION BY name ORDER BY timestamp)) * 100 as tvl_change_24h,
        NOW() as last_updated,
        'defillama' as source,
        chain,
        category
    FROM external_apis.defillama_protocols
    WHERE timestamp > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 10 MINUTE))
    AND tvl > 1000000  -- Filter for protocols with significant TVL
)
EVERY 5 minutes
IF (
    SELECT COUNT(*) 
    FROM external_apis.defillama_protocols 
    WHERE timestamp > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 10 MINUTE))
);

-- Create social sentiment real-time sync job
CREATE JOB real_time_sentiment_sync AS (
    INSERT INTO crypto_data_db.social_sentiment (
        asset_symbol,
        platform,
        sentiment_score,
        mention_count,
        engagement_score,
        trending_rank,
        sentiment_change_24h,
        last_updated,
        source
    )
    SELECT 
        symbol as asset_symbol,
        'twitter' as platform,
        sentiment_score,
        mention_count,
        (likes + retweets + replies) / mention_count as engagement_score,
        trending_rank,
        sentiment_score - LAG(sentiment_score) OVER (PARTITION BY symbol ORDER BY timestamp) as sentiment_change_24h,
        NOW() as last_updated,
        'social_media_api' as source
    FROM external_apis.twitter_crypto_sentiment
    WHERE timestamp > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 15 MINUTE))
    AND mention_count > 10  -- Filter for meaningful sentiment data
    
    UNION ALL
    
    SELECT 
        symbol as asset_symbol,
        'reddit' as platform,
        sentiment_score,
        post_count as mention_count,
        (upvotes + comments) / post_count as engagement_score,
        subreddit_rank as trending_rank,
        sentiment_score - LAG(sentiment_score) OVER (PARTITION BY symbol ORDER BY timestamp) as sentiment_change_24h,
        NOW() as last_updated,
        'reddit_api' as source
    FROM external_apis.reddit_crypto_sentiment
    WHERE timestamp > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 15 MINUTE))
    AND post_count > 5
)
EVERY 10 minutes;

-- Create blockchain metrics real-time sync job
CREATE JOB real_time_blockchain_sync AS (
    INSERT INTO crypto_data_db.blockchain_metrics (
        blockchain,
        block_height,
        hash_rate,
        difficulty,
        transaction_count_24h,
        avg_transaction_fee,
        active_addresses,
        network_utilization,
        last_updated,
        source
    )
    SELECT 
        'bitcoin' as blockchain,
        block_height,
        hash_rate,
        difficulty,
        transaction_count_24h,
        avg_fee_usd as avg_transaction_fee,
        active_addresses,
        (transaction_count_24h / max_tps) * 100 as network_utilization,
        NOW() as last_updated,
        'blockchain_info' as source
    FROM external_apis.bitcoin_network_stats
    WHERE last_updated > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 30 MINUTE))
    
    UNION ALL
    
    SELECT 
        'ethereum' as blockchain,
        block_number as block_height,
        hash_rate,
        difficulty,
        transaction_count_24h,
        avg_gas_price_gwei * gas_used_avg / 1e9 * eth_price as avg_transaction_fee,
        active_addresses,
        gas_used_percentage as network_utilization,
        NOW() as last_updated,
        'etherscan' as source
    FROM external_apis.ethereum_network_stats
    WHERE last_updated > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 30 MINUTE))
)
EVERY 15 minutes;

-- Create news and events real-time sync job
CREATE JOB real_time_news_sync AS (
    INSERT INTO crypto_data_db.crypto_news_real_time (
        title,
        content,
        source_url,
        published_at,
        sentiment_score,
        impact_score,
        mentioned_assets,
        category,
        source_reliability,
        last_updated
    )
    SELECT 
        title,
        content,
        url as source_url,
        published_at,
        sentiment_score,
        CASE 
            WHEN source_domain IN ('coindesk.com', 'cointelegraph.com', 'decrypt.co') THEN 0.9
            WHEN source_domain IN ('coinmarketcap.com', 'coingecko.com') THEN 0.8
            WHEN source_domain LIKE '%.com' THEN 0.6
            ELSE 0.4
        END * ABS(sentiment_score) as impact_score,
        mentioned_cryptocurrencies as mentioned_assets,
        category,
        source_reliability,
        NOW() as last_updated
    FROM external_apis.crypto_news_feed
    WHERE published_at > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 1 HOUR))
    AND sentiment_score IS NOT NULL
    AND LENGTH(content) > 100  -- Filter for substantial content
)
EVERY 30 minutes;

-- Create data quality monitoring job
CREATE JOB data_quality_monitor AS (
    -- Monitor data freshness and quality
    INSERT INTO crypto_data_db.data_quality_metrics (
        table_name,
        record_count,
        latest_timestamp,
        data_freshness_minutes,
        quality_score,
        issues_detected,
        last_checked
    )
    SELECT 
        'real_time_prices' as table_name,
        COUNT(*) as record_count,
        MAX(last_updated) as latest_timestamp,
        TIMESTAMPDIFF(MINUTE, MAX(last_updated), NOW()) as data_freshness_minutes,
        AVG(data_quality_score) as quality_score,
        SUM(CASE WHEN data_quality_score < 0.5 THEN 1 ELSE 0 END) as issues_detected,
        NOW() as last_checked
    FROM crypto_data_db.real_time_prices
    WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    
    UNION ALL
    
    SELECT 
        'defi_real_time' as table_name,
        COUNT(*) as record_count,
        MAX(last_updated) as latest_timestamp,
        TIMESTAMPDIFF(MINUTE, MAX(last_updated), NOW()) as data_freshness_minutes,
        AVG(CASE WHEN tvl > 0 THEN 1.0 ELSE 0.0 END) as quality_score,
        SUM(CASE WHEN tvl <= 0 OR tvl IS NULL THEN 1 ELSE 0 END) as issues_detected,
        NOW() as last_checked
    FROM crypto_data_db.defi_real_time
    WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    
    UNION ALL
    
    SELECT 
        'social_sentiment' as table_name,
        COUNT(*) as record_count,
        MAX(last_updated) as latest_timestamp,
        TIMESTAMPDIFF(MINUTE, MAX(last_updated), NOW()) as data_freshness_minutes,
        AVG(CASE WHEN sentiment_score BETWEEN -1 AND 1 THEN 1.0 ELSE 0.0 END) as quality_score,
        SUM(CASE WHEN sentiment_score NOT BETWEEN -1 AND 1 THEN 1 ELSE 0 END) as issues_detected,
        NOW() as last_checked
    FROM crypto_data_db.social_sentiment
    WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
)
EVERY 15 minutes;

-- Create real-time aggregation job for dashboard views
CREATE JOB real_time_aggregation AS (
    -- Create real-time market overview
    CREATE OR REPLACE TABLE crypto_data_db.market_overview_real_time AS
    SELECT 
        'market_summary' as metric_type,
        COUNT(DISTINCT symbol) as total_assets,
        SUM(market_cap) as total_market_cap,
        AVG(percent_change_24h) as avg_change_24h,
        SUM(volume_24h) as total_volume_24h,
        COUNT(CASE WHEN percent_change_24h > 0 THEN 1 END) as gainers_count,
        COUNT(CASE WHEN percent_change_24h < 0 THEN 1 END) as losers_count,
        MAX(last_updated) as last_updated
    FROM crypto_data_db.real_time_prices
    WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)
    AND data_quality_score > 0.5;
    
    -- Create trending assets view
    CREATE OR REPLACE TABLE crypto_data_db.trending_assets_real_time AS
    SELECT 
        symbol,
        price,
        percent_change_24h,
        volume_24h,
        market_cap,
        RANK() OVER (ORDER BY ABS(percent_change_24h) DESC) as volatility_rank,
        RANK() OVER (ORDER BY volume_24h DESC) as volume_rank,
        RANK() OVER (ORDER BY market_cap DESC) as market_cap_rank,
        last_updated
    FROM crypto_data_db.real_time_prices
    WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)
    AND data_quality_score > 0.7
    ORDER BY ABS(percent_change_24h) DESC
    LIMIT 50;
    
    -- Create DeFi overview
    CREATE OR REPLACE TABLE crypto_data_db.defi_overview_real_time AS
    SELECT 
        'defi_summary' as metric_type,
        COUNT(DISTINCT protocol_name) as total_protocols,
        SUM(tvl) as total_tvl,
        SUM(volume_24h) as total_volume_24h,
        SUM(fees_24h) as total_fees_24h,
        AVG(tvl_change_24h) as avg_tvl_change_24h,
        MAX(last_updated) as last_updated
    FROM crypto_data_db.defi_real_time
    WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 10 MINUTE)
    AND tvl > 1000000;
)
EVERY 5 minutes;

-- Create alert generation job for significant market events
CREATE JOB market_alert_generator AS (
    INSERT INTO crypto_data_db.market_alerts (
        alert_type,
        asset_symbol,
        alert_message,
        severity_level,
        trigger_value,
        current_value,
        threshold_breached,
        created_at
    )
    -- Price movement alerts
    SELECT 
        'price_movement' as alert_type,
        symbol as asset_symbol,
        CONCAT(symbol, ' has moved ', ABS(percent_change_1h), '% in the last hour') as alert_message,
        CASE 
            WHEN ABS(percent_change_1h) > 20 THEN 'critical'
            WHEN ABS(percent_change_1h) > 10 THEN 'high'
            WHEN ABS(percent_change_1h) > 5 THEN 'medium'
            ELSE 'low'
        END as severity_level,
        5.0 as trigger_value,
        ABS(percent_change_1h) as current_value,
        'price_change_1h' as threshold_breached,
        NOW() as created_at
    FROM crypto_data_db.real_time_prices
    WHERE ABS(percent_change_1h) > 5
    AND last_updated >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)
    AND symbol IN ('BTC', 'ETH', 'BNB', 'XRP', 'ADA')
    
    UNION ALL
    
    -- Volume spike alerts
    SELECT 
        'volume_spike' as alert_type,
        symbol as asset_symbol,
        CONCAT(symbol, ' volume has increased significantly: $', FORMAT(volume_24h, 0)) as alert_message,
        CASE 
            WHEN volume_24h > avg_volume * 5 THEN 'critical'
            WHEN volume_24h > avg_volume * 3 THEN 'high'
            WHEN volume_24h > avg_volume * 2 THEN 'medium'
            ELSE 'low'
        END as severity_level,
        avg_volume * 2 as trigger_value,
        volume_24h as current_value,
        'volume_spike' as threshold_breached,
        NOW() as created_at
    FROM (
        SELECT 
            symbol,
            volume_24h,
            AVG(volume_24h) OVER (PARTITION BY symbol ORDER BY last_updated ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING) as avg_volume
        FROM crypto_data_db.real_time_prices
        WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    ) volume_analysis
    WHERE volume_24h > avg_volume * 2
    AND avg_volume > 0
)
EVERY 5 minutes;

-- Create performance optimization job
CREATE JOB real_time_optimization AS (
    -- Clean up old real-time data to maintain performance
    DELETE FROM crypto_data_db.real_time_prices 
    WHERE last_updated < DATE_SUB(NOW(), INTERVAL 24 HOUR);
    
    DELETE FROM crypto_data_db.defi_real_time 
    WHERE last_updated < DATE_SUB(NOW(), INTERVAL 24 HOUR);
    
    DELETE FROM crypto_data_db.social_sentiment 
    WHERE last_updated < DATE_SUB(NOW(), INTERVAL 48 HOUR);
    
    DELETE FROM crypto_data_db.market_alerts 
    WHERE created_at < DATE_SUB(NOW(), INTERVAL 7 DAY);
    
    -- Update statistics for query optimization
    ANALYZE TABLE crypto_data_db.real_time_prices;
    ANALYZE TABLE crypto_data_db.defi_real_time;
    ANALYZE TABLE crypto_data_db.social_sentiment;
)
EVERY 1 hour;

-- Create indexes for real-time query performance
CREATE INDEX idx_realtime_prices_symbol_updated ON crypto_data_db.real_time_prices(symbol, last_updated);
CREATE INDEX idx_realtime_prices_updated ON crypto_data_db.real_time_prices(last_updated);
CREATE INDEX idx_realtime_prices_quality ON crypto_data_db.real_time_prices(data_quality_score);

CREATE INDEX idx_defi_realtime_protocol_updated ON crypto_data_db.defi_real_time(protocol_name, last_updated);
CREATE INDEX idx_defi_realtime_tvl ON crypto_data_db.defi_real_time(tvl);
CREATE INDEX idx_defi_realtime_updated ON crypto_data_db.defi_real_time(last_updated);

CREATE INDEX idx_sentiment_symbol_updated ON crypto_data_db.social_sentiment(asset_symbol, last_updated);
CREATE INDEX idx_sentiment_platform ON crypto_data_db.social_sentiment(platform);
CREATE INDEX idx_sentiment_score ON crypto_data_db.social_sentiment(sentiment_score);

-- Success validation queries
SELECT 'Real-time sync jobs created successfully' as status;

SELECT 
    'Real-time Data Sync Status' as component,
    COUNT(*) as active_jobs
FROM information_schema.events 
WHERE event_schema = 'mindsdb' 
AND event_name LIKE '%real_time%';
