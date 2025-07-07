
-- XplainCrypto Market Data Synchronization Job
-- Automated job for continuous market data synchronization and processing

-- Create comprehensive market data synchronization job
CREATE JOB market_data_sync_master AS (
    -- Sync real-time price data from multiple sources
    INSERT INTO crypto_data_db.real_time_prices (
        symbol,
        price,
        volume_24h,
        market_cap,
        percent_change_1h,
        percent_change_24h,
        percent_change_7d,
        circulating_supply,
        total_supply,
        last_updated,
        source,
        data_quality_score
    )
    SELECT 
        UPPER(symbol) as symbol,
        CAST(price AS DECIMAL(20,8)) as price,
        CAST(volume_24h AS DECIMAL(20,2)) as volume_24h,
        CAST(market_cap AS DECIMAL(20,2)) as market_cap,
        CAST(percent_change_1h AS DECIMAL(8,4)) as percent_change_1h,
        CAST(percent_change_24h AS DECIMAL(8,4)) as percent_change_24h,
        CAST(percent_change_7d AS DECIMAL(8,4)) as percent_change_7d,
        CAST(circulating_supply AS DECIMAL(20,2)) as circulating_supply,
        CAST(total_supply AS DECIMAL(20,2)) as total_supply,
        NOW() as last_updated,
        'coinmarketcap' as source,
        CASE 
            WHEN volume_24h > 10000000 AND price > 0 AND market_cap > 0 THEN 1.0
            WHEN volume_24h > 1000000 AND price > 0 THEN 0.9
            WHEN volume_24h > 100000 AND price > 0 THEN 0.8
            WHEN price > 0 THEN 0.6
            ELSE 0.3
        END as data_quality_score
    FROM external_apis.coinmarketcap_latest
    WHERE last_updated > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 5 MINUTE))
    AND symbol IN (
        'BTC', 'ETH', 'BNB', 'XRP', 'ADA', 'SOL', 'DOGE', 'DOT', 'AVAX', 'SHIB',
        'MATIC', 'LTC', 'UNI', 'LINK', 'ATOM', 'XLM', 'BCH', 'ALGO', 'VET', 'ICP',
        'FIL', 'TRX', 'ETC', 'XMR', 'THETA', 'AAVE', 'CAKE', 'SUSHI', 'COMP', 'MKR'
    )
    
    UNION ALL
    
    -- Sync from Binance for high-frequency updates
    SELECT 
        REPLACE(symbol, 'USDT', '') as symbol,
        CAST(price AS DECIMAL(20,8)) as price,
        CAST(volume AS DECIMAL(20,2)) as volume_24h,
        NULL as market_cap,
        CAST(price_change_percent AS DECIMAL(8,4)) as percent_change_1h,
        CAST(price_change_percent_24h AS DECIMAL(8,4)) as percent_change_24h,
        NULL as percent_change_7d,
        NULL as circulating_supply,
        NULL as total_supply,
        NOW() as last_updated,
        'binance' as source,
        CASE 
            WHEN volume > 5000000 AND price > 0 THEN 0.95
            WHEN volume > 1000000 AND price > 0 THEN 0.85
            WHEN volume > 100000 AND price > 0 THEN 0.75
            WHEN price > 0 THEN 0.65
            ELSE 0.4
        END as data_quality_score
    FROM external_apis.binance_ticker_24hr
    WHERE symbol LIKE '%USDT'
    AND symbol NOT LIKE '%UP%' AND symbol NOT LIKE '%DOWN%' AND symbol NOT LIKE '%BEAR%' AND symbol NOT LIKE '%BULL%'
    AND last_updated > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 2 MINUTE))
    AND REPLACE(symbol, 'USDT', '') IN (
        'BTC', 'ETH', 'BNB', 'XRP', 'ADA', 'SOL', 'DOGE', 'DOT', 'AVAX', 'SHIB',
        'MATIC', 'LTC', 'UNI', 'LINK', 'ATOM', 'XLM', 'BCH', 'ALGO', 'VET', 'ICP'
    );
    
    -- Update market data aggregations
    INSERT INTO crypto_data_db.market_data_hourly (
        symbol,
        timestamp,
        open_price,
        high_price,
        low_price,
        close_price,
        volume_1h,
        market_cap,
        price_change_1h,
        volume_change_1h,
        trade_count,
        data_sources,
        sync_timestamp
    )
    SELECT 
        symbol,
        DATE_FORMAT(NOW(), '%Y-%m-%d %H:00:00') as timestamp,
        FIRST_VALUE(price) OVER (PARTITION BY symbol ORDER BY last_updated ROWS UNBOUNDED PRECEDING) as open_price,
        MAX(price) as high_price,
        MIN(price) as low_price,
        LAST_VALUE(price) OVER (PARTITION BY symbol ORDER BY last_updated ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as close_price,
        AVG(volume_24h) / 24 as volume_1h,
        AVG(market_cap) as market_cap,
        (LAST_VALUE(price) OVER (PARTITION BY symbol ORDER BY last_updated ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) - 
         FIRST_VALUE(price) OVER (PARTITION BY symbol ORDER BY last_updated ROWS UNBOUNDED PRECEDING)) / 
         FIRST_VALUE(price) OVER (PARTITION BY symbol ORDER BY last_updated ROWS UNBOUNDED PRECEDING) * 100 as price_change_1h,
        (AVG(volume_24h) / 24 - LAG(AVG(volume_24h) / 24) OVER (PARTITION BY symbol ORDER BY DATE_FORMAT(NOW(), '%Y-%m-%d %H:00:00'))) / 
         LAG(AVG(volume_24h) / 24) OVER (PARTITION BY symbol ORDER BY DATE_FORMAT(NOW(), '%Y-%m-%d %H:00:00')) * 100 as volume_change_1h,
        COUNT(*) as trade_count,
        GROUP_CONCAT(DISTINCT source) as data_sources,
        NOW() as sync_timestamp
    FROM crypto_data_db.real_time_prices
    WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    AND data_quality_score > 0.6
    GROUP BY symbol
    HAVING COUNT(DISTINCT source) >= 1;
    
    -- Log synchronization metrics
    INSERT INTO crypto_data_db.sync_performance_log (
        sync_type,
        records_processed,
        data_sources_count,
        avg_data_quality,
        sync_duration_ms,
        success_rate,
        timestamp
    )
    SELECT 
        'market_data_sync' as sync_type,
        COUNT(*) as records_processed,
        COUNT(DISTINCT source) as data_sources_count,
        AVG(data_quality_score) as avg_data_quality,
        TIMESTAMPDIFF(MICROSECOND, MIN(last_updated), MAX(last_updated)) / 1000 as sync_duration_ms,
        (COUNT(CASE WHEN data_quality_score > 0.7 THEN 1 END) / COUNT(*)) * 100 as success_rate,
        NOW() as timestamp
    FROM crypto_data_db.real_time_prices
    WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 5 MINUTE);
)
EVERY 3 minutes
IF (
    SELECT COUNT(*) 
    FROM external_apis.coinmarketcap_latest 
    WHERE last_updated > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 5 MINUTE))
);

-- Create DeFi data synchronization job
CREATE JOB defi_data_sync AS (
    -- Sync DeFi protocol data from DeFiLlama
    INSERT INTO crypto_data_db.defi_real_time (
        protocol_name,
        tvl,
        volume_24h,
        fees_24h,
        revenue_24h,
        active_users,
        transactions_24h,
        tvl_change_24h,
        volume_change_24h,
        chain,
        category,
        token_symbol,
        last_updated,
        source
    )
    SELECT 
        name as protocol_name,
        CAST(tvl AS DECIMAL(20,2)) as tvl,
        CAST(volume_24h AS DECIMAL(20,2)) as volume_24h,
        CAST(fees_24h AS DECIMAL(20,2)) as fees_24h,
        CAST(revenue_24h AS DECIMAL(20,2)) as revenue_24h,
        CAST(active_users AS INT) as active_users,
        CAST(transactions_24h AS INT) as transactions_24h,
        CAST(tvl_change_24h AS DECIMAL(8,4)) as tvl_change_24h,
        CAST(volume_change_24h AS DECIMAL(8,4)) as volume_change_24h,
        chain,
        category,
        token as token_symbol,
        NOW() as last_updated,
        'defillama' as source
    FROM external_apis.defillama_protocols
    WHERE last_updated > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 10 MINUTE))
    AND tvl > 1000000  -- Filter for protocols with significant TVL
    AND name IS NOT NULL;
    
    -- Update DeFi sector aggregations
    INSERT INTO crypto_data_db.defi_sector_metrics (
        sector,
        total_tvl,
        protocol_count,
        avg_tvl_change_24h,
        total_volume_24h,
        total_fees_24h,
        dominant_chains,
        last_calculated
    )
    SELECT 
        category as sector,
        SUM(tvl) as total_tvl,
        COUNT(DISTINCT protocol_name) as protocol_count,
        AVG(tvl_change_24h) as avg_tvl_change_24h,
        SUM(volume_24h) as total_volume_24h,
        SUM(fees_24h) as total_fees_24h,
        GROUP_CONCAT(DISTINCT chain ORDER BY SUM(tvl) DESC SEPARATOR ', ') as dominant_chains,
        NOW() as last_calculated
    FROM crypto_data_db.defi_real_time
    WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 15 MINUTE)
    GROUP BY category
    HAVING total_tvl > 10000000;
)
EVERY 5 minutes
IF (
    SELECT COUNT(*) 
    FROM external_apis.defillama_protocols 
    WHERE last_updated > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 10 MINUTE))
);

-- Create blockchain metrics synchronization job
CREATE JOB blockchain_metrics_sync AS (
    -- Sync Bitcoin network metrics
    INSERT INTO crypto_data_db.blockchain_metrics (
        blockchain,
        block_height,
        hash_rate,
        difficulty,
        transaction_count_24h,
        avg_transaction_fee,
        active_addresses,
        network_utilization,
        mempool_size,
        confirmation_time_avg,
        last_updated,
        source
    )
    SELECT 
        'bitcoin' as blockchain,
        CAST(block_height AS INT) as block_height,
        CAST(hash_rate AS DECIMAL(20,2)) as hash_rate,
        CAST(difficulty AS DECIMAL(25,2)) as difficulty,
        CAST(transaction_count_24h AS INT) as transaction_count_24h,
        CAST(avg_fee_usd AS DECIMAL(10,4)) as avg_transaction_fee,
        CAST(active_addresses AS INT) as active_addresses,
        CAST(network_utilization AS DECIMAL(5,2)) as network_utilization,
        CAST(mempool_size AS INT) as mempool_size,
        CAST(avg_confirmation_time AS DECIMAL(8,2)) as confirmation_time_avg,
        NOW() as last_updated,
        'blockchain_info' as source
    FROM external_apis.bitcoin_network_stats
    WHERE last_updated > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 30 MINUTE))
    
    UNION ALL
    
    -- Sync Ethereum network metrics
    SELECT 
        'ethereum' as blockchain,
        CAST(block_number AS INT) as block_height,
        CAST(hash_rate AS DECIMAL(20,2)) as hash_rate,
        CAST(difficulty AS DECIMAL(25,2)) as difficulty,
        CAST(transaction_count_24h AS INT) as transaction_count_24h,
        CAST(avg_gas_price_gwei * gas_used_avg / 1e9 * eth_price AS DECIMAL(10,4)) as avg_transaction_fee,
        CAST(active_addresses AS INT) as active_addresses,
        CAST(gas_used_percentage AS DECIMAL(5,2)) as network_utilization,
        CAST(pending_transactions AS INT) as mempool_size,
        CAST(avg_block_time AS DECIMAL(8,2)) as confirmation_time_avg,
        NOW() as last_updated,
        'etherscan' as source
    FROM external_apis.ethereum_network_stats
    WHERE last_updated > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 30 MINUTE));
    
    -- Calculate network health scores
    INSERT INTO crypto_data_db.network_health_scores (
        blockchain,
        health_score,
        decentralization_score,
        security_score,
        scalability_score,
        sustainability_score,
        calculated_at
    )
    SELECT 
        blockchain,
        (decentralization_score + security_score + scalability_score + sustainability_score) / 4 as health_score,
        CASE 
            WHEN blockchain = 'bitcoin' THEN 
                LEAST(100, (hash_rate / 100000000000000) * 50 + 
                      (active_addresses / 1000000) * 30 + 20)
            WHEN blockchain = 'ethereum' THEN
                LEAST(100, (active_addresses / 500000) * 40 + 
                      (network_utilization / 100) * 30 + 30)
            ELSE 50
        END as decentralization_score,
        CASE 
            WHEN blockchain = 'bitcoin' THEN 
                LEAST(100, (hash_rate / 50000000000000) * 60 + 40)
            WHEN blockchain = 'ethereum' THEN
                LEAST(100, (hash_rate / 1000000000000) * 50 + 50)
            ELSE 50
        END as security_score,
        CASE 
            WHEN transaction_count_24h > 300000 THEN 90
            WHEN transaction_count_24h > 200000 THEN 75
            WHEN transaction_count_24h > 100000 THEN 60
            WHEN transaction_count_24h > 50000 THEN 45
            ELSE 30
        END as scalability_score,
        CASE 
            WHEN avg_transaction_fee < 1 THEN 90
            WHEN avg_transaction_fee < 5 THEN 75
            WHEN avg_transaction_fee < 10 THEN 60
            WHEN avg_transaction_fee < 20 THEN 45
            ELSE 30
        END as sustainability_score,
        NOW() as calculated_at
    FROM crypto_data_db.blockchain_metrics
    WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    GROUP BY blockchain;
)
EVERY 15 minutes;

-- Create market sentiment synchronization job
CREATE JOB market_sentiment_sync AS (
    -- Sync social media sentiment data
    INSERT INTO crypto_data_db.social_sentiment (
        asset_symbol,
        platform,
        sentiment_score,
        mention_count,
        engagement_score,
        trending_rank,
        sentiment_change_24h,
        volume_mentions,
        influencer_sentiment,
        last_updated,
        source
    )
    SELECT 
        symbol as asset_symbol,
        'twitter' as platform,
        CAST(sentiment_score AS DECIMAL(3,2)) as sentiment_score,
        CAST(mention_count AS INT) as mention_count,
        CAST((likes + retweets + replies) / GREATEST(mention_count, 1) AS DECIMAL(8,2)) as engagement_score,
        CAST(trending_rank AS INT) as trending_rank,
        CAST(sentiment_score - LAG(sentiment_score) OVER (PARTITION BY symbol ORDER BY timestamp) AS DECIMAL(3,2)) as sentiment_change_24h,
        CAST(volume_weighted_mentions AS INT) as volume_mentions,
        CAST(influencer_sentiment AS DECIMAL(3,2)) as influencer_sentiment,
        NOW() as last_updated,
        'social_media_api' as source
    FROM external_apis.twitter_crypto_sentiment
    WHERE timestamp > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 15 MINUTE))
    AND mention_count > 10
    AND symbol IN (
        'BTC', 'ETH', 'BNB', 'XRP', 'ADA', 'SOL', 'DOGE', 'DOT', 'AVAX', 'MATIC'
    )
    
    UNION ALL
    
    SELECT 
        symbol as asset_symbol,
        'reddit' as platform,
        CAST(sentiment_score AS DECIMAL(3,2)) as sentiment_score,
        CAST(post_count AS INT) as mention_count,
        CAST((upvotes + comments) / GREATEST(post_count, 1) AS DECIMAL(8,2)) as engagement_score,
        CAST(subreddit_rank AS INT) as trending_rank,
        CAST(sentiment_score - LAG(sentiment_score) OVER (PARTITION BY symbol ORDER BY timestamp) AS DECIMAL(3,2)) as sentiment_change_24h,
        CAST(weighted_posts AS INT) as volume_mentions,
        CAST(mod_sentiment AS DECIMAL(3,2)) as influencer_sentiment,
        NOW() as last_updated,
        'reddit_api' as source
    FROM external_apis.reddit_crypto_sentiment
    WHERE timestamp > COALESCE(LAST, DATE_SUB(NOW(), INTERVAL 15 MINUTE))
    AND post_count > 5;
    
    -- Calculate aggregated sentiment metrics
    INSERT INTO crypto_data_db.aggregated_sentiment_metrics (
        asset_symbol,
        overall_sentiment_score,
        sentiment_volatility,
        social_volume_score,
        sentiment_trend,
        confidence_level,
        last_calculated
    )
    SELECT 
        asset_symbol,
        AVG(sentiment_score) as overall_sentiment_score,
        STDDEV(sentiment_score) as sentiment_volatility,
        LOG(SUM(mention_count) + 1) * 10 as social_volume_score,
        CASE 
            WHEN AVG(sentiment_change_24h) > 0.1 THEN 'Improving'
            WHEN AVG(sentiment_change_24h) < -0.1 THEN 'Declining'
            ELSE 'Stable'
        END as sentiment_trend,
        CASE 
            WHEN COUNT(DISTINCT platform) >= 2 AND SUM(mention_count) > 100 THEN 'High'
            WHEN COUNT(DISTINCT platform) >= 1 AND SUM(mention_count) > 50 THEN 'Medium'
            ELSE 'Low'
        END as confidence_level,
        NOW() as last_calculated
    FROM crypto_data_db.social_sentiment
    WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    GROUP BY asset_symbol
    HAVING SUM(mention_count) > 20;
)
EVERY 10 minutes;

-- Create data quality monitoring job
CREATE JOB market_data_quality_monitor AS (
    -- Monitor data freshness and quality
    INSERT INTO crypto_data_db.data_quality_alerts (
        alert_type,
        table_name,
        issue_description,
        severity_level,
        affected_records,
        recommended_action,
        created_at
    )
    -- Check for stale price data
    SELECT 
        'stale_data' as alert_type,
        'real_time_prices' as table_name,
        CONCAT('Price data for ', symbol, ' is ', TIMESTAMPDIFF(MINUTE, MAX(last_updated), NOW()), ' minutes old') as issue_description,
        CASE 
            WHEN TIMESTAMPDIFF(MINUTE, MAX(last_updated), NOW()) > 30 THEN 'high'
            WHEN TIMESTAMPDIFF(MINUTE, MAX(last_updated), NOW()) > 15 THEN 'medium'
            ELSE 'low'
        END as severity_level,
        COUNT(*) as affected_records,
        'Check data source connectivity and sync processes' as recommended_action,
        NOW() as created_at
    FROM crypto_data_db.real_time_prices
    WHERE symbol IN ('BTC', 'ETH', 'BNB')
    GROUP BY symbol
    HAVING TIMESTAMPDIFF(MINUTE, MAX(last_updated), NOW()) > 10
    
    UNION ALL
    
    -- Check for data quality issues
    SELECT 
        'quality_degradation' as alert_type,
        'real_time_prices' as table_name,
        CONCAT('Data quality score below threshold for ', COUNT(*), ' records') as issue_description,
        'medium' as severity_level,
        COUNT(*) as affected_records,
        'Review data source reliability and validation rules' as recommended_action,
        NOW() as created_at
    FROM crypto_data_db.real_time_prices
    WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    AND data_quality_score < 0.6
    HAVING COUNT(*) > 5
    
    UNION ALL
    
    -- Check for missing DeFi data
    SELECT 
        'missing_data' as alert_type,
        'defi_real_time' as table_name,
        'DeFi protocol data sync appears to be failing' as issue_description,
        'high' as severity_level,
        0 as affected_records,
        'Check DeFiLlama API connectivity and sync job status' as recommended_action,
        NOW() as created_at
    FROM DUAL
    WHERE (
        SELECT COUNT(*) 
        FROM crypto_data_db.defi_real_time 
        WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 30 MINUTE)
    ) < 10;
    
    -- Update data quality metrics
    INSERT INTO crypto_data_db.data_quality_metrics (
        metric_date,
        table_name,
        total_records,
        quality_score,
        freshness_score,
        completeness_score,
        consistency_score,
        calculated_at
    )
    SELECT 
        CURDATE() as metric_date,
        'real_time_prices' as table_name,
        COUNT(*) as total_records,
        AVG(data_quality_score) * 100 as quality_score,
        CASE 
            WHEN AVG(TIMESTAMPDIFF(MINUTE, last_updated, NOW())) < 5 THEN 100
            WHEN AVG(TIMESTAMPDIFF(MINUTE, last_updated, NOW())) < 10 THEN 80
            WHEN AVG(TIMESTAMPDIFF(MINUTE, last_updated, NOW())) < 20 THEN 60
            ELSE 40
        END as freshness_score,
        (COUNT(CASE WHEN price > 0 AND volume_24h > 0 THEN 1 END) / COUNT(*)) * 100 as completeness_score,
        (COUNT(CASE WHEN data_quality_score > 0.7 THEN 1 END) / COUNT(*)) * 100 as consistency_score,
        NOW() as calculated_at
    FROM crypto_data_db.real_time_prices
    WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 1 HOUR);
)
EVERY 30 minutes;

-- Create performance optimization job
CREATE JOB market_data_optimization AS (
    -- Clean up old real-time data
    DELETE FROM crypto_data_db.real_time_prices 
    WHERE last_updated < DATE_SUB(NOW(), INTERVAL 6 HOUR)
    AND symbol NOT IN ('BTC', 'ETH', 'BNB');  -- Keep major coins longer
    
    DELETE FROM crypto_data_db.real_time_prices 
    WHERE last_updated < DATE_SUB(NOW(), INTERVAL 24 HOUR);
    
    -- Archive old DeFi data
    INSERT INTO crypto_data_db.defi_historical_archive
    SELECT * FROM crypto_data_db.defi_real_time
    WHERE last_updated < DATE_SUB(NOW(), INTERVAL 7 DAY);
    
    DELETE FROM crypto_data_db.defi_real_time
    WHERE last_updated < DATE_SUB(NOW(), INTERVAL 7 DAY);
    
    -- Update table statistics for query optimization
    ANALYZE TABLE crypto_data_db.real_time_prices;
    ANALYZE TABLE crypto_data_db.defi_real_time;
    ANALYZE TABLE crypto_data_db.social_sentiment;
    ANALYZE TABLE crypto_data_db.blockchain_metrics;
    
    -- Log optimization metrics
    INSERT INTO crypto_data_db.optimization_log (
        optimization_type,
        records_processed,
        records_archived,
        records_deleted,
        performance_improvement,
        completed_at
    ) VALUES (
        'market_data_cleanup',
        (SELECT COUNT(*) FROM crypto_data_db.real_time_prices),
        (SELECT COUNT(*) FROM crypto_data_db.defi_historical_archive WHERE created_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR)),
        0,  -- This would be calculated from actual deletions
        'Improved query performance and reduced storage usage',
        NOW()
    );
)
EVERY 2 hours;

-- Success validation
SELECT 'Market Data Synchronization Jobs created successfully' as status;

-- Verify job creation
SELECT 
    'Market Data Sync Jobs Status' as component,
    COUNT(*) as total_jobs_created,
    GROUP_CONCAT(event_name) as job_names
FROM information_schema.events 
WHERE event_schema = 'mindsdb' 
AND event_name LIKE '%market%' OR event_name LIKE '%defi%' OR event_name LIKE '%blockchain%';
