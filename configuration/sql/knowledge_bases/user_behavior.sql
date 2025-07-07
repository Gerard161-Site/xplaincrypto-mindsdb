
-- XplainCrypto User Behavior Analysis Knowledge Base
-- This KB analyzes user interactions, learning patterns, and trading behaviors

-- Create embedding model for user behavior content
CREATE MODEL user_behavior_embedding
PREDICT embedding
USING
    engine = 'openai_engine',
    model_name = 'text-embedding-3-small',
    input_columns = ['behavior_description'];

-- Create vector database for user behavior storage
CREATE DATABASE user_behavior_vectordb
WITH ENGINE = 'chromadb',
PARAMETERS = {
    "persist_directory": "/var/lib/mindsdb/user_behavior_vectors"
};

-- Create the User Behavior Analysis Knowledge Base
CREATE KNOWLEDGE BASE user_behavior_kb
USING
    model = user_behavior_embedding,
    storage = user_behavior_vectordb.user_patterns,
    content_columns = ['behavior_description', 'analysis', 'recommendations'],
    metadata_columns = ['user_segment', 'behavior_type', 'confidence_score', 'timestamp', 'platform_section'],
    id_column = 'behavior_id',
    description = 'User behavior patterns, learning preferences, and trading habits for personalized experiences';

-- Populate with user learning behavior patterns
INSERT INTO user_behavior_kb (
    behavior_id,
    behavior_description,
    analysis,
    recommendations,
    user_segment,
    behavior_type,
    confidence_score,
    timestamp,
    platform_section
)
SELECT 
    CONCAT('learning_', ROW_NUMBER() OVER (ORDER BY session_start)) as behavior_id,
    CONCAT(
        'User learning session: ', course_name, ' - ',
        'Duration: ', session_duration, ' minutes, ',
        'Completion: ', completion_percentage, '%, ',
        'Quiz Score: ', quiz_score, '%, ',
        'Interactions: ', interaction_count
    ) as behavior_description,
    CONCAT(
        'Learning Pattern Analysis: ',
        CASE 
            WHEN completion_percentage > 90 AND quiz_score > 80 THEN 'Highly engaged learner with strong comprehension'
            WHEN completion_percentage > 70 AND quiz_score > 60 THEN 'Consistent learner with good understanding'
            WHEN completion_percentage > 50 THEN 'Moderate engagement, may need additional support'
            ELSE 'Low engagement, requires intervention or content adjustment'
        END,
        '. Session duration suggests ',
        CASE 
            WHEN session_duration > 30 THEN 'deep focus and commitment'
            WHEN session_duration > 15 THEN 'adequate attention span'
            ELSE 'brief engagement or time constraints'
        END
    ) as analysis,
    CONCAT(
        'Recommendations: ',
        CASE 
            WHEN completion_percentage < 50 THEN 'Provide shorter content modules, gamification elements'
            WHEN quiz_score < 60 THEN 'Offer additional practice exercises, visual aids'
            WHEN session_duration < 15 THEN 'Create bite-sized learning chunks, mobile-friendly content'
            ELSE 'Continue with current content difficulty, consider advanced topics'
        END
    ) as recommendations,
    CASE 
        WHEN completion_percentage > 80 AND quiz_score > 75 THEN 'advanced_learner'
        WHEN completion_percentage > 60 AND quiz_score > 60 THEN 'intermediate_learner'
        ELSE 'beginner_learner'
    END as user_segment,
    'learning_behavior' as behavior_type,
    CASE 
        WHEN session_duration > 20 AND interaction_count > 10 THEN 0.9
        WHEN session_duration > 10 AND interaction_count > 5 THEN 0.7
        ELSE 0.5
    END as confidence_score,
    session_start as timestamp,
    'education' as platform_section
FROM user_data_db.learning_sessions 
WHERE session_start >= DATE_SUB(NOW(), INTERVAL 30 DAY)
LIMIT 1000;

-- Add trading behavior patterns
INSERT INTO user_behavior_kb (
    behavior_id,
    behavior_description,
    analysis,
    recommendations,
    user_segment,
    behavior_type,
    confidence_score,
    timestamp,
    platform_section
)
SELECT 
    CONCAT('trading_', trade_id) as behavior_id,
    CONCAT(
        'Trading Activity: ', trade_type, ' ', asset_symbol, ' - ',
        'Amount: $', trade_amount, ', ',
        'Profit/Loss: ', profit_loss_percentage, '%, ',
        'Hold Duration: ', hold_duration_hours, ' hours, ',
        'Risk Level: ', risk_level
    ) as behavior_description,
    CONCAT(
        'Trading Behavior Analysis: ',
        CASE 
            WHEN profit_loss_percentage > 10 THEN 'Successful trade with strong market timing'
            WHEN profit_loss_percentage > 0 THEN 'Profitable trade showing good decision making'
            WHEN profit_loss_percentage > -5 THEN 'Minor loss within acceptable risk parameters'
            ELSE 'Significant loss indicating need for strategy review'
        END,
        '. Risk management shows ',
        CASE 
            WHEN risk_level = 'low' AND trade_amount < 1000 THEN 'conservative approach suitable for beginners'
            WHEN risk_level = 'medium' THEN 'balanced risk-reward strategy'
            WHEN risk_level = 'high' THEN 'aggressive strategy requiring careful monitoring'
            ELSE 'risk level needs optimization'
        END
    ) as analysis,
    CONCAT(
        'Trading Recommendations: ',
        CASE 
            WHEN profit_loss_percentage < -10 THEN 'Review stop-loss strategy, consider smaller position sizes'
            WHEN hold_duration_hours < 1 THEN 'Avoid day trading, focus on longer-term strategies'
            WHEN risk_level = 'high' AND profit_loss_percentage < 0 THEN 'Reduce risk exposure, implement better risk management'
            ELSE 'Continue current strategy with minor optimizations'
        END
    ) as recommendations,
    CASE 
        WHEN AVG(profit_loss_percentage) OVER (PARTITION BY user_id ORDER BY trade_date ROWS BETWEEN 9 PRECEDING AND CURRENT ROW) > 5 THEN 'profitable_trader'
        WHEN AVG(profit_loss_percentage) OVER (PARTITION BY user_id ORDER BY trade_date ROWS BETWEEN 9 PRECEDING AND CURRENT ROW) > 0 THEN 'moderate_trader'
        ELSE 'learning_trader'
    END as user_segment,
    'trading_behavior' as behavior_type,
    CASE 
        WHEN ABS(profit_loss_percentage) > 20 THEN 0.9
        WHEN ABS(profit_loss_percentage) > 5 THEN 0.7
        ELSE 0.5
    END as confidence_score,
    trade_date as timestamp,
    'trading' as platform_section
FROM user_data_db.user_trades 
WHERE trade_date >= DATE_SUB(NOW(), INTERVAL 30 DAY);

-- Add social interaction patterns
INSERT INTO user_behavior_kb (
    behavior_id,
    behavior_description,
    analysis,
    recommendations,
    user_segment,
    behavior_type,
    confidence_score,
    timestamp,
    platform_section
)
SELECT 
    CONCAT('social_', interaction_id) as behavior_id,
    CONCAT(
        'Social Interaction: ', interaction_type, ' - ',
        'Content: ', LEFT(content, 200), '... ',
        'Engagement: ', likes_count, ' likes, ', comments_count, ' comments, ',
        'Sentiment: ', sentiment_score
    ) as behavior_description,
    CONCAT(
        'Social Engagement Analysis: ',
        CASE 
            WHEN likes_count > 50 AND comments_count > 10 THEN 'High-value content creator with strong community engagement'
            WHEN likes_count > 10 AND comments_count > 3 THEN 'Active community member with valuable contributions'
            WHEN likes_count > 0 OR comments_count > 0 THEN 'Moderate engagement, building community presence'
            ELSE 'Low engagement, may need encouragement or content guidance'
        END,
        '. Sentiment analysis indicates ',
        CASE 
            WHEN sentiment_score > 0.5 THEN 'positive community influence'
            WHEN sentiment_score > 0 THEN 'neutral to positive interactions'
            WHEN sentiment_score > -0.5 THEN 'mixed sentiment requiring attention'
            ELSE 'negative sentiment needing moderation'
        END
    ) as analysis,
    CONCAT(
        'Social Recommendations: ',
        CASE 
            WHEN sentiment_score < -0.3 THEN 'Provide educational resources, encourage positive discussions'
            WHEN likes_count = 0 AND comments_count = 0 THEN 'Suggest engaging with trending topics, ask questions'
            WHEN likes_count > 20 THEN 'Consider featuring content, invite to expert discussions'
            ELSE 'Encourage continued participation, provide feedback on contributions'
        END
    ) as recommendations,
    CASE 
        WHEN likes_count > 20 AND sentiment_score > 0.5 THEN 'community_leader'
        WHEN likes_count > 5 AND sentiment_score > 0 THEN 'active_member'
        ELSE 'casual_member'
    END as user_segment,
    'social_behavior' as behavior_type,
    CASE 
        WHEN likes_count + comments_count > 20 THEN 0.9
        WHEN likes_count + comments_count > 5 THEN 0.7
        ELSE 0.5
    END as confidence_score,
    created_at as timestamp,
    'community' as platform_section
FROM user_data_db.social_interactions 
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 14 DAY);

-- Create aggregated user behavior insights view
CREATE VIEW user_behavior_insights AS
SELECT 
    user_segment,
    behavior_type,
    platform_section,
    COUNT(*) as behavior_count,
    AVG(confidence_score) as avg_confidence,
    MAX(timestamp) as latest_activity,
    STRING_AGG(DISTINCT LEFT(recommendations, 100), '; ') as common_recommendations
FROM user_behavior_kb
WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY user_segment, behavior_type, platform_section
ORDER BY behavior_count DESC;

-- Create user personalization recommendations view
CREATE VIEW user_personalization_recommendations AS
SELECT 
    user_segment,
    platform_section,
    COUNT(*) as pattern_frequency,
    AVG(confidence_score) as reliability_score,
    STRING_AGG(DISTINCT recommendations, ' | ') as aggregated_recommendations,
    CASE 
        WHEN AVG(confidence_score) > 0.8 THEN 'high_confidence'
        WHEN AVG(confidence_score) > 0.6 THEN 'medium_confidence'
        ELSE 'low_confidence'
    END as recommendation_confidence
FROM user_behavior_kb
WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 14 DAY)
GROUP BY user_segment, platform_section
HAVING COUNT(*) >= 5
ORDER BY reliability_score DESC, pattern_frequency DESC;

-- Test queries for user behavior analysis
-- Query 1: Get learning behavior patterns for advanced users
SELECT behavior_description, analysis, recommendations
FROM user_behavior_kb
WHERE user_segment = 'advanced_learner' 
AND behavior_type = 'learning_behavior'
ORDER BY confidence_score DESC
LIMIT 10;

-- Query 2: Analyze trading patterns for profitable traders
SELECT behavior_description, analysis, recommendations
FROM user_behavior_kb
WHERE user_segment = 'profitable_trader' 
AND behavior_type = 'trading_behavior'
ORDER BY timestamp DESC
LIMIT 10;

-- Query 3: Get social engagement recommendations
SELECT user_segment, aggregated_recommendations, reliability_score
FROM user_personalization_recommendations
WHERE platform_section = 'community'
AND recommendation_confidence = 'high_confidence';

-- Create indexes for performance optimization
CREATE INDEX idx_user_behavior_segment ON user_behavior_kb(user_segment);
CREATE INDEX idx_user_behavior_type ON user_behavior_kb(behavior_type);
CREATE INDEX idx_user_behavior_timestamp ON user_behavior_kb(timestamp);
CREATE INDEX idx_user_behavior_platform ON user_behavior_kb(platform_section);
CREATE INDEX idx_user_behavior_confidence ON user_behavior_kb(confidence_score);

-- Success validation query
SELECT 
    'User Behavior Analysis KB' as component,
    COUNT(*) as total_behaviors,
    COUNT(DISTINCT user_segment) as user_segments,
    COUNT(DISTINCT behavior_type) as behavior_types,
    AVG(confidence_score) as avg_confidence,
    MAX(timestamp) as latest_behavior
FROM user_behavior_kb;
