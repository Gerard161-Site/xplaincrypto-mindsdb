
-- XplainCrypto User Analytics SQL Skill
-- Reusable AI skill for analyzing user behavior, learning patterns, and engagement metrics

-- Create the user analytics SQL skill
CREATE SKILL user_analytics_sql_skill
USING
    type = 'text2sql',
    database = 'user_data_db',
    tables = [
        'users',
        'user_profiles',
        'learning_sessions',
        'user_trades',
        'social_interactions',
        'user_preferences',
        'engagement_metrics',
        'learning_progress',
        'portfolio_performance',
        'user_feedback'
    ],
    description = 'Comprehensive user analytics including learning behavior, trading patterns, social engagement, portfolio performance, and personalization data. Enables analysis of user segments, learning effectiveness, and platform optimization.';

-- Create enhanced user analytics views
CREATE VIEW user_learning_analytics AS
SELECT 
    u.user_id,
    u.username,
    up.experience_level,
    up.learning_style,
    COUNT(ls.session_id) as total_sessions,
    AVG(ls.session_duration) as avg_session_duration,
    AVG(ls.completion_percentage) as avg_completion_rate,
    AVG(ls.quiz_score) as avg_quiz_score,
    SUM(ls.interaction_count) as total_interactions,
    MAX(ls.session_start) as last_learning_session,
    DATEDIFF(NOW(), MAX(ls.session_start)) as days_since_last_session,
    COUNT(DISTINCT ls.course_name) as courses_attempted,
    SUM(CASE WHEN ls.completion_percentage >= 90 THEN 1 ELSE 0 END) as courses_completed,
    CASE 
        WHEN AVG(ls.completion_percentage) > 80 AND AVG(ls.quiz_score) > 75 THEN 'High Performer'
        WHEN AVG(ls.completion_percentage) > 60 AND AVG(ls.quiz_score) > 60 THEN 'Consistent Learner'
        WHEN AVG(ls.completion_percentage) > 40 THEN 'Moderate Engagement'
        ELSE 'Needs Support'
    END as learning_segment
FROM user_data_db.users u
JOIN user_data_db.user_profiles up ON u.user_id = up.user_id
LEFT JOIN user_data_db.learning_sessions ls ON u.user_id = ls.user_id
WHERE u.created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
GROUP BY u.user_id, u.username, up.experience_level, up.learning_style;

CREATE VIEW user_trading_analytics AS
SELECT 
    u.user_id,
    u.username,
    up.risk_tolerance,
    up.investment_experience,
    COUNT(ut.trade_id) as total_trades,
    SUM(ut.trade_amount) as total_volume_traded,
    AVG(ut.trade_amount) as avg_trade_size,
    AVG(ut.profit_loss_percentage) as avg_profit_loss,
    SUM(CASE WHEN ut.profit_loss_percentage > 0 THEN 1 ELSE 0 END) as winning_trades,
    SUM(CASE WHEN ut.profit_loss_percentage < 0 THEN 1 ELSE 0 END) as losing_trades,
    (SUM(CASE WHEN ut.profit_loss_percentage > 0 THEN 1 ELSE 0 END) / COUNT(ut.trade_id)) * 100 as win_rate,
    SUM(ut.profit_loss_percentage * ut.trade_amount) / SUM(ut.trade_amount) as weighted_return,
    AVG(ut.hold_duration_hours) as avg_hold_duration,
    COUNT(DISTINCT ut.asset_symbol) as assets_traded,
    MAX(ut.trade_date) as last_trade_date,
    DATEDIFF(NOW(), MAX(ut.trade_date)) as days_since_last_trade,
    CASE 
        WHEN AVG(ut.profit_loss_percentage) > 5 AND COUNT(ut.trade_id) > 10 THEN 'Profitable Trader'
        WHEN AVG(ut.profit_loss_percentage) > 0 AND COUNT(ut.trade_id) > 5 THEN 'Moderate Trader'
        WHEN COUNT(ut.trade_id) > 0 THEN 'Learning Trader'
        ELSE 'Non-Trader'
    END as trading_segment
FROM user_data_db.users u
JOIN user_data_db.user_profiles up ON u.user_id = up.user_id
LEFT JOIN user_data_db.user_trades ut ON u.user_id = ut.user_id
WHERE u.created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
GROUP BY u.user_id, u.username, up.risk_tolerance, up.investment_experience;

CREATE VIEW user_social_analytics AS
SELECT 
    u.user_id,
    u.username,
    COUNT(si.interaction_id) as total_interactions,
    SUM(si.likes_count) as total_likes_received,
    SUM(si.comments_count) as total_comments_received,
    AVG(si.sentiment_score) as avg_sentiment_score,
    COUNT(DISTINCT si.interaction_type) as interaction_types,
    COUNT(CASE WHEN si.interaction_type = 'post' THEN 1 END) as posts_created,
    COUNT(CASE WHEN si.interaction_type = 'comment' THEN 1 END) as comments_made,
    COUNT(CASE WHEN si.interaction_type = 'like' THEN 1 END) as likes_given,
    MAX(si.created_at) as last_social_activity,
    DATEDIFF(NOW(), MAX(si.created_at)) as days_since_last_activity,
    AVG(si.likes_count + si.comments_count) as avg_engagement_per_post,
    CASE 
        WHEN COUNT(si.interaction_id) > 100 AND AVG(si.sentiment_score) > 0.5 THEN 'Community Leader'
        WHEN COUNT(si.interaction_id) > 50 AND AVG(si.sentiment_score) > 0.3 THEN 'Active Member'
        WHEN COUNT(si.interaction_id) > 10 THEN 'Casual Member'
        ELSE 'Observer'
    END as social_segment
FROM user_data_db.users u
LEFT JOIN user_data_db.social_interactions si ON u.user_id = si.user_id
WHERE u.created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
GROUP BY u.user_id, u.username;

-- Create comprehensive user segmentation view
CREATE VIEW comprehensive_user_segments AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    u.created_at as registration_date,
    DATEDIFF(NOW(), u.created_at) as days_since_registration,
    up.experience_level,
    up.risk_tolerance,
    up.learning_style,
    la.learning_segment,
    ta.trading_segment,
    sa.social_segment,
    la.total_sessions,
    la.avg_completion_rate,
    la.courses_completed,
    ta.total_trades,
    ta.avg_profit_loss,
    ta.win_rate,
    sa.total_interactions,
    sa.avg_sentiment_score,
    em.daily_active_days,
    em.weekly_active_weeks,
    em.monthly_active_months,
    CASE 
        WHEN la.learning_segment = 'High Performer' AND ta.trading_segment = 'Profitable Trader' THEN 'Expert User'
        WHEN la.learning_segment IN ('High Performer', 'Consistent Learner') AND ta.trading_segment IN ('Profitable Trader', 'Moderate Trader') THEN 'Advanced User'
        WHEN la.learning_segment IN ('Consistent Learner', 'Moderate Engagement') AND ta.trading_segment IN ('Moderate Trader', 'Learning Trader') THEN 'Intermediate User'
        WHEN la.learning_segment = 'Needs Support' OR ta.trading_segment = 'Learning Trader' THEN 'Beginner User'
        ELSE 'Inactive User'
    END as overall_user_segment,
    CASE 
        WHEN em.daily_active_days > 20 THEN 'Highly Engaged'
        WHEN em.daily_active_days > 10 THEN 'Moderately Engaged'
        WHEN em.daily_active_days > 3 THEN 'Occasionally Engaged'
        ELSE 'Low Engagement'
    END as engagement_level
FROM user_data_db.users u
JOIN user_data_db.user_profiles up ON u.user_id = up.user_id
LEFT JOIN user_learning_analytics la ON u.user_id = la.user_id
LEFT JOIN user_trading_analytics ta ON u.user_id = ta.user_id
LEFT JOIN user_social_analytics sa ON u.user_id = sa.user_id
LEFT JOIN user_data_db.engagement_metrics em ON u.user_id = em.user_id
WHERE u.created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH);

-- Create query templates for common user analytics use cases
CREATE TABLE user_data_db.user_analytics_templates (
    template_id VARCHAR(50) PRIMARY KEY,
    template_name VARCHAR(200),
    description TEXT,
    sql_template TEXT,
    parameters JSON,
    example_usage TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO user_data_db.user_analytics_templates VALUES
('user_engagement_trends',
 'User engagement trends over time',
 'Analyze user engagement patterns and trends',
 'SELECT DATE(created_at) as date, COUNT(DISTINCT user_id) as active_users, AVG(session_duration) as avg_session_duration FROM user_data_db.learning_sessions WHERE created_at >= DATE_SUB(NOW(), INTERVAL {days} DAY) GROUP BY DATE(created_at) ORDER BY date',
 '{"days": 30}',
 'Show user engagement trends for the last 30 days',
 NOW()),

('learning_effectiveness',
 'Learning effectiveness analysis',
 'Measure learning effectiveness across different content types',
 'SELECT course_name, COUNT(*) as total_sessions, AVG(completion_percentage) as avg_completion, AVG(quiz_score) as avg_quiz_score, AVG(session_duration) as avg_duration FROM user_data_db.learning_sessions WHERE session_start >= DATE_SUB(NOW(), INTERVAL {days} DAY) GROUP BY course_name ORDER BY avg_completion DESC',
 '{"days": 30}',
 'Analyze learning effectiveness for the last 30 days',
 NOW()),

('user_retention_cohort',
 'User retention cohort analysis',
 'Analyze user retention by registration cohort',
 'SELECT DATE_FORMAT(u.created_at, "%Y-%m") as cohort_month, COUNT(DISTINCT u.user_id) as total_users, COUNT(DISTINCT CASE WHEN ls.session_start >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN u.user_id END) as active_users_30d FROM user_data_db.users u LEFT JOIN user_data_db.learning_sessions ls ON u.user_id = ls.user_id WHERE u.created_at >= DATE_SUB(NOW(), INTERVAL {months} MONTH) GROUP BY DATE_FORMAT(u.created_at, "%Y-%m") ORDER BY cohort_month',
 '{"months": 12}',
 'Analyze user retention for the last 12 months',
 NOW()),

('trading_performance_segments',
 'Trading performance by user segments',
 'Compare trading performance across different user segments',
 'SELECT overall_user_segment, COUNT(*) as user_count, AVG(total_trades) as avg_trades, AVG(avg_profit_loss) as avg_return, AVG(win_rate) as avg_win_rate FROM comprehensive_user_segments WHERE total_trades > 0 GROUP BY overall_user_segment ORDER BY avg_return DESC',
 '{}',
 'Compare trading performance across user segments',
 NOW()),

('content_preferences',
 'Content preferences by user type',
 'Analyze content preferences across different user segments',
 'SELECT up.experience_level, ls.course_name, COUNT(*) as sessions, AVG(ls.completion_percentage) as avg_completion FROM user_data_db.user_profiles up JOIN user_data_db.learning_sessions ls ON up.user_id = ls.user_id WHERE ls.session_start >= DATE_SUB(NOW(), INTERVAL {days} DAY) GROUP BY up.experience_level, ls.course_name ORDER BY up.experience_level, avg_completion DESC',
 '{"days": 60}',
 'Analyze content preferences by experience level for the last 60 days',
 NOW()),

('social_engagement_patterns',
 'Social engagement patterns',
 'Analyze social interaction patterns and community health',
 'SELECT interaction_type, COUNT(*) as total_interactions, AVG(likes_count) as avg_likes, AVG(comments_count) as avg_comments, AVG(sentiment_score) as avg_sentiment FROM user_data_db.social_interactions WHERE created_at >= DATE_SUB(NOW(), INTERVAL {days} DAY) GROUP BY interaction_type ORDER BY total_interactions DESC',
 '{"days": 30}',
 'Analyze social engagement patterns for the last 30 days',
 NOW()),

('user_journey_analysis',
 'User journey and progression analysis',
 'Track user progression through learning and trading milestones',
 'SELECT u.user_id, u.username, u.created_at as registration_date, MIN(ls.session_start) as first_learning_session, MIN(ut.trade_date) as first_trade, COUNT(DISTINCT ls.course_name) as courses_tried, COUNT(ut.trade_id) as total_trades FROM user_data_db.users u LEFT JOIN user_data_db.learning_sessions ls ON u.user_id = ls.user_id LEFT JOIN user_data_db.user_trades ut ON u.user_id = ut.user_id WHERE u.created_at >= DATE_SUB(NOW(), INTERVAL {days} DAY) GROUP BY u.user_id, u.username, u.created_at ORDER BY u.created_at DESC',
 '{"days": 90}',
 'Analyze user journey for users registered in the last 90 days',
 NOW()),

('churn_risk_analysis',
 'Churn risk analysis',
 'Identify users at risk of churning based on engagement patterns',
 'SELECT user_id, username, days_since_last_session, days_since_last_trade, days_since_last_activity, engagement_level, CASE WHEN days_since_last_session > 30 AND days_since_last_trade > 30 AND days_since_last_activity > 30 THEN "High Risk" WHEN days_since_last_session > 14 OR days_since_last_trade > 14 OR days_since_last_activity > 14 THEN "Medium Risk" ELSE "Low Risk" END as churn_risk FROM comprehensive_user_segments WHERE engagement_level IN ("Low Engagement", "Occasionally Engaged") ORDER BY days_since_last_session DESC',
 '{}',
 'Identify users at risk of churning',
 NOW());

-- Create helper functions for user analytics
DELIMITER //

CREATE FUNCTION calculate_user_ltv(user_id_param INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE ltv_value DECIMAL(10,2);
    
    SELECT 
        COALESCE(SUM(subscription_revenue), 0) + 
        COALESCE(SUM(trading_fees), 0) + 
        COALESCE(SUM(premium_features_revenue), 0)
    INTO ltv_value
    FROM user_data_db.user_revenue
    WHERE user_id = user_id_param;
    
    RETURN COALESCE(ltv_value, 0);
END //

CREATE FUNCTION get_user_engagement_score(user_id_param INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE engagement_score DECIMAL(5,2);
    
    SELECT 
        (
            COALESCE(learning_score, 0) * 0.4 +
            COALESCE(trading_score, 0) * 0.3 +
            COALESCE(social_score, 0) * 0.3
        )
    INTO engagement_score
    FROM (
        SELECT 
            (COUNT(DISTINCT ls.session_id) / 30.0) * 100 as learning_score,
            (COUNT(DISTINCT ut.trade_id) / 10.0) * 100 as trading_score,
            (COUNT(DISTINCT si.interaction_id) / 20.0) * 100 as social_score
        FROM user_data_db.users u
        LEFT JOIN user_data_db.learning_sessions ls ON u.user_id = ls.user_id 
            AND ls.session_start >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        LEFT JOIN user_data_db.user_trades ut ON u.user_id = ut.user_id 
            AND ut.trade_date >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        LEFT JOIN user_data_db.social_interactions si ON u.user_id = si.user_id 
            AND si.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        WHERE u.user_id = user_id_param
    ) scores;
    
    RETURN LEAST(COALESCE(engagement_score, 0), 100);
END //

CREATE FUNCTION predict_user_churn_risk(user_id_param INT)
RETURNS VARCHAR(20)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE churn_risk VARCHAR(20);
    DECLARE days_inactive INT;
    DECLARE engagement_score DECIMAL(5,2);
    
    SELECT 
        GREATEST(
            COALESCE(DATEDIFF(NOW(), MAX(ls.session_start)), 999),
            COALESCE(DATEDIFF(NOW(), MAX(ut.trade_date)), 999),
            COALESCE(DATEDIFF(NOW(), MAX(si.created_at)), 999)
        ),
        get_user_engagement_score(user_id_param)
    INTO days_inactive, engagement_score
    FROM user_data_db.users u
    LEFT JOIN user_data_db.learning_sessions ls ON u.user_id = ls.user_id
    LEFT JOIN user_data_db.user_trades ut ON u.user_id = ut.user_id
    LEFT JOIN user_data_db.social_interactions si ON u.user_id = si.user_id
    WHERE u.user_id = user_id_param;
    
    SET churn_risk = CASE 
        WHEN days_inactive > 60 OR engagement_score < 20 THEN 'High Risk'
        WHEN days_inactive > 30 OR engagement_score < 40 THEN 'Medium Risk'
        WHEN days_inactive > 14 OR engagement_score < 60 THEN 'Low Risk'
        ELSE 'Active'
    END;
    
    RETURN churn_risk;
END //

DELIMITER ;

-- Create performance tracking for user analytics
CREATE TABLE user_data_db.analytics_performance_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    query_type VARCHAR(100),
    execution_time_ms INT,
    rows_analyzed INT,
    insights_generated INT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Success validation queries
SELECT 'User Analytics SQL Skill created successfully' as status;

-- Test the skill functionality
SELECT 
    'User Analytics Validation' as test_type,
    COUNT(DISTINCT user_id) as total_users,
    COUNT(DISTINCT CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN user_id END) as new_users_30d,
    COUNT(DISTINCT CASE WHEN last_login >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN user_id END) as active_users_7d
FROM user_data_db.users;

SELECT 
    'Learning Analytics Available' as test_type,
    COUNT(DISTINCT user_id) as users_with_sessions,
    COUNT(*) as total_sessions,
    AVG(completion_percentage) as avg_completion_rate
FROM user_data_db.learning_sessions
WHERE session_start >= DATE_SUB(NOW(), INTERVAL 30 DAY);

SELECT 
    'Trading Analytics Available' as test_type,
    COUNT(DISTINCT user_id) as users_with_trades,
    COUNT(*) as total_trades,
    AVG(profit_loss_percentage) as avg_return
FROM user_data_db.user_trades
WHERE trade_date >= DATE_SUB(NOW(), INTERVAL 30 DAY);

SELECT 
    'Social Analytics Available' as test_type,
    COUNT(DISTINCT user_id) as socially_active_users,
    COUNT(*) as total_interactions,
    AVG(sentiment_score) as avg_sentiment
FROM user_data_db.social_interactions
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY);
