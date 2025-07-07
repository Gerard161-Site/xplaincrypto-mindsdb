
-- XplainCrypto User Behavior Analysis Job
-- Automated job for analyzing user behavior patterns and generating insights

-- Create comprehensive user behavior analysis job
CREATE JOB user_behavior_analysis_master AS (
    -- Analyze learning behavior patterns
    INSERT INTO user_data_db.learning_behavior_insights (
        user_id,
        analysis_date,
        learning_pattern,
        engagement_level,
        completion_trend,
        preferred_content_type,
        optimal_session_duration,
        learning_velocity,
        knowledge_retention_score,
        recommended_next_topics,
        personalization_score,
        created_at
    )
    SELECT 
        ls.user_id,
        CURDATE() as analysis_date,
        CASE 
            WHEN AVG(ls.session_duration) > 30 AND AVG(ls.completion_percentage) > 80 THEN 'Deep Learner'
            WHEN AVG(ls.session_duration) BETWEEN 15 AND 30 AND AVG(ls.completion_percentage) > 60 THEN 'Consistent Learner'
            WHEN AVG(ls.session_duration) < 15 AND COUNT(*) > 10 THEN 'Micro Learner'
            WHEN AVG(ls.completion_percentage) < 50 THEN 'Struggling Learner'
            ELSE 'Casual Learner'
        END as learning_pattern,
        CASE 
            WHEN COUNT(*) > 20 AND AVG(ls.interaction_count) > 15 THEN 'Highly Engaged'
            WHEN COUNT(*) > 10 AND AVG(ls.interaction_count) > 8 THEN 'Moderately Engaged'
            WHEN COUNT(*) > 5 THEN 'Occasionally Engaged'
            ELSE 'Low Engagement'
        END as engagement_level,
        CASE 
            WHEN (AVG(ls.completion_percentage) - LAG(AVG(ls.completion_percentage)) OVER (PARTITION BY ls.user_id ORDER BY DATE(ls.session_start))) > 10 THEN 'Improving'
            WHEN (AVG(ls.completion_percentage) - LAG(AVG(ls.completion_percentage)) OVER (PARTITION BY ls.user_id ORDER BY DATE(ls.session_start))) < -10 THEN 'Declining'
            ELSE 'Stable'
        END as completion_trend,
        (
            SELECT course_name 
            FROM user_data_db.learning_sessions ls2 
            WHERE ls2.user_id = ls.user_id 
            AND ls2.session_start >= DATE_SUB(NOW(), INTERVAL 30 DAY)
            GROUP BY course_name 
            ORDER BY AVG(completion_percentage) DESC, COUNT(*) DESC 
            LIMIT 1
        ) as preferred_content_type,
        ROUND(AVG(ls.session_duration), 0) as optimal_session_duration,
        COUNT(*) / GREATEST(DATEDIFF(MAX(ls.session_start), MIN(ls.session_start)), 1) as learning_velocity,
        AVG(ls.quiz_score) as knowledge_retention_score,
        (
            SELECT GROUP_CONCAT(DISTINCT topic SEPARATOR ', ')
            FROM educational_content_kb ec
            WHERE ec.difficulty_level = CASE 
                WHEN AVG(ls.quiz_score) > 80 THEN 'advanced'
                WHEN AVG(ls.quiz_score) > 60 THEN 'intermediate'
                ELSE 'beginner'
            END
            AND ec.topic NOT IN (
                SELECT DISTINCT course_name 
                FROM user_data_db.learning_sessions ls3 
                WHERE ls3.user_id = ls.user_id
            )
            LIMIT 5
        ) as recommended_next_topics,
        CASE 
            WHEN AVG(ls.completion_percentage) > 75 AND AVG(ls.quiz_score) > 70 AND COUNT(*) > 15 THEN 0.9
            WHEN AVG(ls.completion_percentage) > 60 AND AVG(ls.quiz_score) > 60 AND COUNT(*) > 10 THEN 0.7
            WHEN AVG(ls.completion_percentage) > 50 AND COUNT(*) > 5 THEN 0.5
            ELSE 0.3
        END as personalization_score,
        NOW() as created_at
    FROM user_data_db.learning_sessions ls
    WHERE ls.session_start >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    GROUP BY ls.user_id
    HAVING COUNT(*) >= 3;
    
    -- Analyze trading behavior patterns
    INSERT INTO user_data_db.trading_behavior_insights (
        user_id,
        analysis_date,
        trading_style,
        risk_profile,
        performance_trend,
        preferred_assets,
        avg_hold_duration,
        win_rate,
        profit_factor,
        risk_adjusted_return,
        trading_frequency,
        emotional_trading_score,
        recommended_strategies,
        created_at
    )
    SELECT 
        ut.user_id,
        CURDATE() as analysis_date,
        CASE 
            WHEN AVG(ut.hold_duration_hours) < 24 THEN 'Day Trader'
            WHEN AVG(ut.hold_duration_hours) BETWEEN 24 AND 168 THEN 'Swing Trader'
            WHEN AVG(ut.hold_duration_hours) BETWEEN 168 AND 720 THEN 'Position Trader'
            ELSE 'Long-term Investor'
        END as trading_style,
        CASE 
            WHEN AVG(ut.trade_amount) > 10000 AND ut.risk_level = 'high' THEN 'Aggressive'
            WHEN AVG(ut.trade_amount) > 5000 AND ut.risk_level IN ('medium', 'high') THEN 'Moderate'
            WHEN ut.risk_level = 'low' THEN 'Conservative'
            ELSE 'Cautious'
        END as risk_profile,
        CASE 
            WHEN (AVG(ut.profit_loss_percentage) - LAG(AVG(ut.profit_loss_percentage)) OVER (PARTITION BY ut.user_id ORDER BY DATE(ut.trade_date))) > 2 THEN 'Improving'
            WHEN (AVG(ut.profit_loss_percentage) - LAG(AVG(ut.profit_loss_percentage)) OVER (PARTITION BY ut.user_id ORDER BY DATE(ut.trade_date))) < -2 THEN 'Declining'
            ELSE 'Stable'
        END as performance_trend,
        (
            SELECT GROUP_CONCAT(asset_symbol ORDER BY COUNT(*) DESC SEPARATOR ', ')
            FROM user_data_db.user_trades ut2
            WHERE ut2.user_id = ut.user_id
            AND ut2.trade_date >= DATE_SUB(NOW(), INTERVAL 30 DAY)
            GROUP BY asset_symbol
            ORDER BY COUNT(*) DESC
            LIMIT 3
        ) as preferred_assets,
        AVG(ut.hold_duration_hours) as avg_hold_duration,
        (SUM(CASE WHEN ut.profit_loss_percentage > 0 THEN 1 ELSE 0 END) / COUNT(*)) * 100 as win_rate,
        CASE 
            WHEN SUM(CASE WHEN ut.profit_loss_percentage < 0 THEN ABS(ut.profit_loss_percentage) ELSE 0 END) > 0 THEN
                SUM(CASE WHEN ut.profit_loss_percentage > 0 THEN ut.profit_loss_percentage ELSE 0 END) / 
                SUM(CASE WHEN ut.profit_loss_percentage < 0 THEN ABS(ut.profit_loss_percentage) ELSE 0 END)
            ELSE 0
        END as profit_factor,
        AVG(ut.profit_loss_percentage) / NULLIF(STDDEV(ut.profit_loss_percentage), 0) as risk_adjusted_return,
        COUNT(*) / GREATEST(DATEDIFF(MAX(ut.trade_date), MIN(ut.trade_date)), 1) as trading_frequency,
        CASE 
            WHEN STDDEV(ut.trade_amount) / AVG(ut.trade_amount) > 1 THEN 0.8  -- High variance in trade sizes
            WHEN COUNT(CASE WHEN ut.hold_duration_hours < 1 THEN 1 END) / COUNT(*) > 0.3 THEN 0.7  -- Many very short trades
            WHEN AVG(ut.profit_loss_percentage) < -5 AND COUNT(*) > 10 THEN 0.6  -- Consistent losses
            ELSE 0.3
        END as emotional_trading_score,
        CASE 
            WHEN AVG(ut.profit_loss_percentage) < 0 AND COUNT(*) > 10 THEN 'Focus on risk management, consider stop-losses'
            WHEN AVG(ut.hold_duration_hours) < 1 THEN 'Avoid overtrading, consider longer timeframes'
            WHEN STDDEV(ut.trade_amount) / AVG(ut.trade_amount) > 1 THEN 'Maintain consistent position sizing'
            WHEN (SUM(CASE WHEN ut.profit_loss_percentage > 0 THEN 1 ELSE 0 END) / COUNT(*)) < 0.4 THEN 'Improve entry timing and analysis'
            ELSE 'Continue current strategy with minor optimizations'
        END as recommended_strategies,
        NOW() as created_at
    FROM user_data_db.user_trades ut
    WHERE ut.trade_date >= DATE_SUB(NOW(), INTERVAL 60 DAY)
    GROUP BY ut.user_id
    HAVING COUNT(*) >= 5;
    
    -- Analyze social engagement patterns
    INSERT INTO user_data_db.social_engagement_insights (
        user_id,
        analysis_date,
        engagement_style,
        community_influence,
        content_quality_score,
        interaction_frequency,
        sentiment_contribution,
        preferred_topics,
        network_growth_rate,
        reputation_score,
        recommended_actions,
        created_at
    )
    SELECT 
        si.user_id,
        CURDATE() as analysis_date,
        CASE 
            WHEN AVG(si.likes_count + si.comments_count) > 50 THEN 'Influencer'
            WHEN COUNT(CASE WHEN si.interaction_type = 'post' THEN 1 END) > COUNT(CASE WHEN si.interaction_type = 'comment' THEN 1 END) THEN 'Content Creator'
            WHEN COUNT(CASE WHEN si.interaction_type = 'comment' THEN 1 END) > COUNT(CASE WHEN si.interaction_type = 'post' THEN 1 END) THEN 'Active Commenter'
            WHEN COUNT(CASE WHEN si.interaction_type = 'like' THEN 1 END) > COUNT(*) * 0.7 THEN 'Supporter'
            ELSE 'Observer'
        END as engagement_style,
        CASE 
            WHEN AVG(si.likes_count) > 20 AND AVG(si.sentiment_score) > 0.5 THEN 'High Positive Influence'
            WHEN AVG(si.likes_count) > 10 AND AVG(si.sentiment_score) > 0.3 THEN 'Moderate Positive Influence'
            WHEN AVG(si.likes_count) > 5 THEN 'Some Influence'
            ELSE 'Limited Influence'
        END as community_influence,
        CASE 
            WHEN AVG(LENGTH(si.content)) > 200 AND AVG(si.sentiment_score) > 0.3 THEN 0.9
            WHEN AVG(LENGTH(si.content)) > 100 AND AVG(si.sentiment_score) > 0.1 THEN 0.7
            WHEN AVG(LENGTH(si.content)) > 50 THEN 0.5
            ELSE 0.3
        END as content_quality_score,
        COUNT(*) / GREATEST(DATEDIFF(MAX(si.created_at), MIN(si.created_at)), 1) as interaction_frequency,
        AVG(si.sentiment_score) as sentiment_contribution,
        (
            SELECT GROUP_CONCAT(DISTINCT topic SEPARATOR ', ')
            FROM (
                SELECT 
                    CASE 
                        WHEN si2.content LIKE '%bitcoin%' OR si2.content LIKE '%BTC%' THEN 'Bitcoin'
                        WHEN si2.content LIKE '%ethereum%' OR si2.content LIKE '%ETH%' THEN 'Ethereum'
                        WHEN si2.content LIKE '%defi%' THEN 'DeFi'
                        WHEN si2.content LIKE '%nft%' THEN 'NFT'
                        WHEN si2.content LIKE '%trading%' THEN 'Trading'
                        ELSE 'General'
                    END as topic,
                    COUNT(*) as topic_count
                FROM user_data_db.social_interactions si2
                WHERE si2.user_id = si.user_id
                AND si2.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
                GROUP BY topic
                ORDER BY topic_count DESC
                LIMIT 3
            ) topics
        ) as preferred_topics,
        (COUNT(*) - LAG(COUNT(*)) OVER (PARTITION BY si.user_id ORDER BY DATE(si.created_at))) / 
        NULLIF(LAG(COUNT(*)) OVER (PARTITION BY si.user_id ORDER BY DATE(si.created_at)), 0) * 100 as network_growth_rate,
        LEAST(100, 
            (AVG(si.likes_count) * 0.4) + 
            (AVG(si.comments_count) * 0.3) + 
            (AVG(si.sentiment_score) * 50 * 0.2) + 
            (COUNT(*) * 0.1)
        ) as reputation_score,
        CASE 
            WHEN AVG(si.sentiment_score) < 0 THEN 'Focus on positive contributions to improve community standing'
            WHEN COUNT(*) < 5 THEN 'Increase participation to build community presence'
            WHEN AVG(si.likes_count) < 2 THEN 'Create more engaging content to increase interaction'
            WHEN AVG(LENGTH(si.content)) < 50 THEN 'Provide more detailed and thoughtful responses'
            ELSE 'Continue positive community engagement'
        END as recommended_actions,
        NOW() as created_at
    FROM user_data_db.social_interactions si
    WHERE si.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    GROUP BY si.user_id
    HAVING COUNT(*) >= 3;
)
EVERY 1 day
START '2024-01-01 02:00:00';

-- Create user segmentation and personalization job
CREATE JOB user_segmentation_analysis AS (
    -- Create comprehensive user segments
    INSERT INTO user_data_db.user_segments (
        user_id,
        segment_date,
        primary_segment,
        secondary_segment,
        engagement_score,
        value_score,
        retention_risk,
        growth_potential,
        personalization_vector,
        recommended_features,
        content_preferences,
        interaction_preferences,
        created_at
    )
    SELECT 
        u.user_id,
        CURDATE() as segment_date,
        CASE 
            WHEN lbi.learning_pattern = 'Deep Learner' AND tbi.trading_style IN ('Position Trader', 'Long-term Investor') THEN 'Expert User'
            WHEN lbi.engagement_level = 'Highly Engaged' AND tbi.performance_trend = 'Improving' THEN 'Rising Star'
            WHEN lbi.learning_pattern IN ('Consistent Learner', 'Deep Learner') AND tbi.win_rate > 60 THEN 'Successful Trader'
            WHEN lbi.engagement_level IN ('Moderately Engaged', 'Highly Engaged') AND sei.community_influence LIKE '%Positive%' THEN 'Community Leader'
            WHEN lbi.learning_pattern = 'Struggling Learner' OR tbi.performance_trend = 'Declining' THEN 'Needs Support'
            WHEN lbi.engagement_level = 'Low Engagement' AND DATEDIFF(NOW(), u.last_login) > 14 THEN 'At Risk'
            ELSE 'Regular User'
        END as primary_segment,
        CASE 
            WHEN tbi.trading_frequency > 1 THEN 'Active Trader'
            WHEN lbi.learning_velocity > 0.5 THEN 'Active Learner'
            WHEN sei.interaction_frequency > 0.5 THEN 'Social User'
            ELSE 'Passive User'
        END as secondary_segment,
        COALESCE(
            (COALESCE(lbi.personalization_score, 0) * 0.4) +
            (COALESCE(tbi.risk_adjusted_return, 0) * 0.1 + 0.3) * 0.3 +
            (COALESCE(sei.reputation_score, 0) / 100 * 0.3)
        , 0.3) as engagement_score,
        COALESCE(
            (COALESCE(tbi.trading_frequency, 0) * 100) +
            (COALESCE(lbi.learning_velocity, 0) * 50) +
            (COALESCE(sei.interaction_frequency, 0) * 30)
        , 50) as value_score,
        CASE 
            WHEN DATEDIFF(NOW(), u.last_login) > 30 THEN 'High'
            WHEN DATEDIFF(NOW(), u.last_login) > 14 THEN 'Medium'
            WHEN lbi.engagement_level = 'Low Engagement' AND tbi.performance_trend = 'Declining' THEN 'Medium'
            ELSE 'Low'
        END as retention_risk,
        CASE 
            WHEN lbi.learning_pattern IN ('Deep Learner', 'Consistent Learner') AND tbi.performance_trend = 'Improving' THEN 'High'
            WHEN lbi.engagement_level = 'Highly Engaged' OR sei.community_influence LIKE '%Positive%' THEN 'Medium'
            WHEN lbi.learning_pattern = 'Struggling Learner' AND DATEDIFF(NOW(), u.created_at) < 90 THEN 'Medium'
            ELSE 'Low'
        END as growth_potential,
        JSON_OBJECT(
            'learning_preference', COALESCE(lbi.preferred_content_type, 'general'),
            'trading_style', COALESCE(tbi.trading_style, 'none'),
            'risk_tolerance', COALESCE(tbi.risk_profile, 'unknown'),
            'social_style', COALESCE(sei.engagement_style, 'observer'),
            'optimal_session_time', COALESCE(lbi.optimal_session_duration, 15),
            'preferred_topics', COALESCE(sei.preferred_topics, 'general')
        ) as personalization_vector,
        CASE 
            WHEN lbi.learning_pattern = 'Struggling Learner' THEN 'Simplified tutorials, gamification, mentorship'
            WHEN tbi.performance_trend = 'Declining' THEN 'Risk management tools, educational content, alerts'
            WHEN sei.community_influence LIKE '%High%' THEN 'Advanced features, beta access, community moderation'
            WHEN lbi.engagement_level = 'Highly Engaged' THEN 'Advanced content, personalized recommendations, premium features'
            ELSE 'Standard features, basic recommendations'
        END as recommended_features,
        COALESCE(lbi.recommended_next_topics, 'Basic cryptocurrency concepts') as content_preferences,
        CASE 
            WHEN sei.engagement_style = 'Content Creator' THEN 'Publishing tools, analytics, community features'
            WHEN tbi.trading_style = 'Day Trader' THEN 'Real-time alerts, advanced charts, quick actions'
            WHEN lbi.learning_pattern = 'Micro Learner' THEN 'Short content, mobile-first, bite-sized lessons'
            ELSE 'Standard interface, balanced content mix'
        END as interaction_preferences,
        NOW() as created_at
    FROM user_data_db.users u
    LEFT JOIN user_data_db.learning_behavior_insights lbi ON u.user_id = lbi.user_id 
        AND lbi.analysis_date = CURDATE()
    LEFT JOIN user_data_db.trading_behavior_insights tbi ON u.user_id = tbi.user_id 
        AND tbi.analysis_date = CURDATE()
    LEFT JOIN user_data_db.social_engagement_insights sei ON u.user_id = sei.user_id 
        AND sei.analysis_date = CURDATE()
    WHERE u.created_at <= DATE_SUB(NOW(), INTERVAL 7 DAY);  -- Only analyze users with at least 7 days of activity
)
EVERY 1 day
START '2024-01-01 03:00:00';

-- Create user journey analysis job
CREATE JOB user_journey_analysis AS (
    -- Track user progression and milestones
    INSERT INTO user_data_db.user_journey_milestones (
        user_id,
        milestone_date,
        milestone_type,
        milestone_description,
        progress_score,
        time_to_milestone,
        next_suggested_milestone,
        created_at
    )
    -- Learning milestones
    SELECT 
        user_id,
        CURDATE() as milestone_date,
        'learning' as milestone_type,
        CASE 
            WHEN courses_completed >= 10 THEN 'Learning Expert - Completed 10+ courses'
            WHEN courses_completed >= 5 THEN 'Advanced Learner - Completed 5+ courses'
            WHEN courses_completed >= 3 THEN 'Consistent Learner - Completed 3+ courses'
            WHEN total_sessions >= 20 THEN 'Engaged Student - 20+ learning sessions'
            WHEN total_sessions >= 10 THEN 'Active Student - 10+ learning sessions'
            ELSE 'Learning Beginner - Started learning journey'
        END as milestone_description,
        LEAST(100, (courses_completed * 10) + (total_sessions * 2) + (avg_completion_rate)) as progress_score,
        DATEDIFF(CURDATE(), MIN(session_start)) as time_to_milestone,
        CASE 
            WHEN courses_completed < 3 THEN 'Complete 3 courses'
            WHEN avg_completion_rate < 80 THEN 'Improve completion rate to 80%'
            WHEN courses_completed < 5 THEN 'Complete 5 courses'
            WHEN courses_completed < 10 THEN 'Become a learning expert'
            ELSE 'Explore advanced topics'
        END as next_suggested_milestone,
        NOW() as created_at
    FROM user_learning_analytics
    WHERE latest_activity >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    
    UNION ALL
    
    -- Trading milestones
    SELECT 
        user_id,
        CURDATE() as milestone_date,
        'trading' as milestone_type,
        CASE 
            WHEN total_trades >= 100 AND avg_profit_loss > 5 THEN 'Expert Trader - 100+ profitable trades'
            WHEN total_trades >= 50 AND avg_profit_loss > 0 THEN 'Experienced Trader - 50+ trades with profit'
            WHEN total_trades >= 20 THEN 'Active Trader - 20+ trades completed'
            WHEN total_trades >= 10 THEN 'Regular Trader - 10+ trades'
            WHEN total_trades >= 5 THEN 'Beginner Trader - First 5 trades'
            ELSE 'Trading Newcomer - Started trading'
        END as milestone_description,
        LEAST(100, (total_trades * 2) + (GREATEST(0, avg_profit_loss) * 10) + (win_rate)) as progress_score,
        DATEDIFF(CURDATE(), MIN(trade_date)) as time_to_milestone,
        CASE 
            WHEN total_trades < 5 THEN 'Complete 5 trades'
            WHEN avg_profit_loss < 0 THEN 'Achieve positive returns'
            WHEN win_rate < 50 THEN 'Improve win rate to 50%'
            WHEN total_trades < 20 THEN 'Reach 20 total trades'
            ELSE 'Optimize risk-adjusted returns'
        END as next_suggested_milestone,
        NOW() as created_at
    FROM user_trading_analytics
    WHERE latest_trade >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    
    UNION ALL
    
    -- Social milestones
    SELECT 
        user_id,
        CURDATE() as milestone_date,
        'social' as milestone_type,
        CASE 
            WHEN total_interactions >= 100 AND avg_sentiment_score > 0.5 THEN 'Community Leader - 100+ positive interactions'
            WHEN total_interactions >= 50 THEN 'Active Community Member - 50+ interactions'
            WHEN total_interactions >= 20 THEN 'Regular Contributor - 20+ interactions'
            WHEN total_interactions >= 10 THEN 'Community Participant - 10+ interactions'
            WHEN total_interactions >= 5 THEN 'Social Newcomer - First interactions'
            ELSE 'Community Observer - Joined community'
        END as milestone_description,
        LEAST(100, (total_interactions * 2) + (avg_sentiment_score * 50) + 20) as progress_score,
        DATEDIFF(CURDATE(), MIN(created_at)) as time_to_milestone,
        CASE 
            WHEN total_interactions < 5 THEN 'Make first 5 interactions'
            WHEN avg_sentiment_score < 0.3 THEN 'Improve contribution quality'
            WHEN total_interactions < 20 THEN 'Reach 20 interactions'
            WHEN total_interactions < 50 THEN 'Become active member'
            ELSE 'Lead community discussions'
        END as next_suggested_milestone,
        NOW() as created_at
    FROM user_social_analytics
    WHERE latest_activity >= DATE_SUB(NOW(), INTERVAL 7 DAY);
)
EVERY 1 day
START '2024-01-01 04:00:00';

-- Create behavior prediction and recommendation job
CREATE JOB user_behavior_prediction AS (
    -- Generate personalized recommendations
    INSERT INTO user_data_db.personalized_recommendations (
        user_id,
        recommendation_date,
        recommendation_type,
        recommendation_title,
        recommendation_description,
        priority_score,
        expected_engagement,
        success_probability,
        expires_at,
        created_at
    )
    -- Learning recommendations
    SELECT 
        us.user_id,
        CURDATE() as recommendation_date,
        'learning' as recommendation_type,
        CONCAT('Recommended: ', SUBSTRING_INDEX(us.content_preferences, ',', 1)) as recommendation_title,
        CONCAT('Based on your learning pattern (', lbi.learning_pattern, '), we recommend focusing on ', 
               SUBSTRING_INDEX(us.content_preferences, ',', 1), ' to improve your knowledge.') as recommendation_description,
        CASE 
            WHEN us.engagement_score > 0.7 THEN 90
            WHEN us.engagement_score > 0.5 THEN 75
            WHEN us.engagement_score > 0.3 THEN 60
            ELSE 45
        END as priority_score,
        us.engagement_score * 100 as expected_engagement,
        CASE 
            WHEN lbi.learning_pattern IN ('Deep Learner', 'Consistent Learner') THEN 0.8
            WHEN lbi.learning_pattern = 'Micro Learner' THEN 0.7
            WHEN lbi.learning_pattern = 'Struggling Learner' THEN 0.5
            ELSE 0.6
        END as success_probability,
        DATE_ADD(CURDATE(), INTERVAL 7 DAY) as expires_at,
        NOW() as created_at
    FROM user_data_db.user_segments us
    JOIN user_data_db.learning_behavior_insights lbi ON us.user_id = lbi.user_id
    WHERE us.segment_date = CURDATE()
    AND us.primary_segment NOT IN ('At Risk')
    AND lbi.analysis_date = CURDATE()
    
    UNION ALL
    
    -- Trading recommendations
    SELECT 
        us.user_id,
        CURDATE() as recommendation_date,
        'trading' as recommendation_type,
        CASE 
            WHEN tbi.performance_trend = 'Declining' THEN 'Risk Management Focus'
            WHEN tbi.emotional_trading_score > 0.6 THEN 'Emotional Trading Control'
            WHEN tbi.win_rate < 50 THEN 'Strategy Improvement'
            ELSE 'Portfolio Optimization'
        END as recommendation_title,
        tbi.recommended_strategies as recommendation_description,
        CASE 
            WHEN tbi.performance_trend = 'Declining' THEN 95
            WHEN tbi.emotional_trading_score > 0.6 THEN 85
            WHEN tbi.win_rate < 40 THEN 80
            ELSE 60
        END as priority_score,
        GREATEST(30, us.engagement_score * 80) as expected_engagement,
        CASE 
            WHEN tbi.trading_style IN ('Position Trader', 'Long-term Investor') THEN 0.8
            WHEN tbi.risk_profile = 'Conservative' THEN 0.7
            WHEN tbi.performance_trend = 'Improving' THEN 0.75
            ELSE 0.6
        END as success_probability,
        DATE_ADD(CURDATE(), INTERVAL 14 DAY) as expires_at,
        NOW() as created_at
    FROM user_data_db.user_segments us
    JOIN user_data_db.trading_behavior_insights tbi ON us.user_id = tbi.user_id
    WHERE us.segment_date = CURDATE()
    AND tbi.analysis_date = CURDATE()
    
    UNION ALL
    
    -- Social engagement recommendations
    SELECT 
        us.user_id,
        CURDATE() as recommendation_date,
        'social' as recommendation_type,
        'Community Engagement' as recommendation_title,
        sei.recommended_actions as recommendation_description,
        CASE 
            WHEN sei.reputation_score < 30 THEN 70
            WHEN sei.interaction_frequency < 0.2 THEN 60
            ELSE 40
        END as priority_score,
        LEAST(80, sei.reputation_score + 20) as expected_engagement,
        CASE 
            WHEN sei.engagement_style IN ('Content Creator', 'Active Commenter') THEN 0.8
            WHEN sei.sentiment_contribution > 0.3 THEN 0.7
            ELSE 0.5
        END as success_probability,
        DATE_ADD(CURDATE(), INTERVAL 10 DAY) as expires_at,
        NOW() as created_at
    FROM user_data_db.user_segments us
    JOIN user_data_db.social_engagement_insights sei ON us.user_id = sei.user_id
    WHERE us.segment_date = CURDATE()
    AND sei.analysis_date = CURDATE();
)
EVERY 1 day
START '2024-01-01 05:00:00';

-- Success validation
SELECT 'User Behavior Analysis Jobs created successfully' as status;

-- Verify job creation
SELECT 
    'User Behavior Analysis Jobs Status' as component,
    COUNT(*) as total_jobs_created,
    GROUP_CONCAT(event_name) as job_names
FROM information_schema.events 
WHERE event_schema = 'mindsdb' 
AND (event_name LIKE '%user%' OR event_name LIKE '%behavior%' OR event_name LIKE '%segment%');
