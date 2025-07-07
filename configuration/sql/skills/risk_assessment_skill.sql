
-- XplainCrypto Risk Assessment Skill
-- Reusable AI skill for analyzing investment risks, portfolio risks, and market risks

-- Create risk assessment model
CREATE MODEL crypto_risk_analyzer
PREDICT risk_score, risk_level, risk_factors, recommendations
USING
    engine = 'openai_engine',
    model_name = 'gpt-4',
    prompt_template = 'Analyze the risk profile for this cryptocurrency investment scenario: {{scenario_data}}. 
    Consider market volatility, liquidity, regulatory risks, technical risks, and portfolio concentration. 
    Provide risk_score (0-100), risk_level (low/medium/high/extreme), key risk_factors, and risk mitigation recommendations.',
    input_columns = ['scenario_data'],
    max_tokens = 200,
    temperature = 0.2;

-- Create the risk assessment skill
CREATE SKILL risk_assessment_skill
USING
    type = 'text2sql',
    database = 'crypto_data_db',
    tables = [
        'portfolio_risk_metrics',
        'asset_risk_profiles',
        'market_volatility_data',
        'liquidity_metrics',
        'regulatory_risk_indicators',
        'correlation_matrix'
    ],
    description = 'Comprehensive risk assessment for cryptocurrency investments including portfolio risk analysis, asset-specific risks, market volatility assessment, and regulatory risk monitoring.';

-- Create risk assessment helper tables
CREATE TABLE crypto_data_db.risk_factors_catalog (
    factor_id INT AUTO_INCREMENT PRIMARY KEY,
    risk_category VARCHAR(50),
    risk_factor VARCHAR(100),
    severity_weight DECIMAL(3,2),
    description TEXT,
    mitigation_strategy TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO crypto_data_db.risk_factors_catalog VALUES
(NULL, 'market_risk', 'high_volatility', 0.8, 'Asset shows high price volatility (>50% in 30 days)', 'Use position sizing and stop-losses', NOW()),
(NULL, 'market_risk', 'low_liquidity', 0.7, 'Low trading volume may cause slippage', 'Trade smaller amounts, use limit orders', NOW()),
(NULL, 'market_risk', 'correlation_risk', 0.6, 'High correlation with other portfolio assets', 'Diversify across uncorrelated assets', NOW()),
(NULL, 'technical_risk', 'smart_contract_risk', 0.9, 'Unaudited or recently deployed smart contracts', 'Only use audited protocols, start with small amounts', NOW()),
(NULL, 'technical_risk', 'centralization_risk', 0.7, 'High degree of centralization in governance or mining', 'Prefer decentralized alternatives', NOW()),
(NULL, 'regulatory_risk', 'regulatory_uncertainty', 0.8, 'Unclear or changing regulatory environment', 'Monitor regulatory developments, maintain compliance', NOW()),
(NULL, 'regulatory_risk', 'delisting_risk', 0.9, 'Risk of exchange delisting', 'Use multiple exchanges, consider regulatory compliance', NOW()),
(NULL, 'operational_risk', 'exchange_risk', 0.8, 'Centralized exchange custody risks', 'Use hardware wallets for long-term storage', NOW()),
(NULL, 'operational_risk', 'key_management_risk', 0.9, 'Risk of losing private keys', 'Use secure backup methods, consider multisig', NOW()),
(NULL, 'liquidity_risk', 'market_depth_risk', 0.6, 'Insufficient market depth for large trades', 'Break large orders into smaller chunks', NOW()),
(NULL, 'concentration_risk', 'portfolio_concentration', 0.7, 'Over-concentration in single asset or sector', 'Maintain diversified portfolio allocation', NOW()),
(NULL, 'market_risk', 'flash_crash_risk', 0.8, 'Susceptible to sudden price crashes', 'Use stop-losses and position limits', NOW());

-- Create risk assessment functions
DELIMITER //

CREATE FUNCTION calculate_volatility_risk(asset_symbol VARCHAR(10), days_period INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE volatility_score DECIMAL(5,2);
    
    SELECT 
        STDDEV((close_price - LAG(close_price) OVER (ORDER BY date)) / LAG(close_price) OVER (ORDER BY date) * 100) * SQRT(365)
    INTO volatility_score
    FROM crypto_data_db.daily_ohlcv
    WHERE symbol = asset_symbol
    AND date >= DATE_SUB(CURDATE(), INTERVAL days_period DAY)
    ORDER BY date;
    
    RETURN COALESCE(volatility_score, 0);
END //

CREATE FUNCTION assess_liquidity_risk(asset_symbol VARCHAR(10))
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE liquidity_assessment JSON;
    
    SELECT JSON_OBJECT(
        'avg_volume_24h', AVG(volume_24h),
        'volume_volatility', STDDEV(volume_24h) / AVG(volume_24h),
        'bid_ask_spread', AVG(bid_ask_spread),
        'market_depth_score', AVG(market_depth_score),
        'liquidity_risk_level', 
        CASE 
            WHEN AVG(volume_24h) > 10000000 AND AVG(bid_ask_spread) < 0.01 THEN 'Low'
            WHEN AVG(volume_24h) > 1000000 AND AVG(bid_ask_spread) < 0.05 THEN 'Medium'
            WHEN AVG(volume_24h) > 100000 THEN 'High'
            ELSE 'Extreme'
        END
    )
    INTO liquidity_assessment
    FROM crypto_data_db.liquidity_metrics
    WHERE symbol = asset_symbol
    AND timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY);
    
    RETURN COALESCE(liquidity_assessment, JSON_OBJECT('error', 'No liquidity data available'));
END //

CREATE FUNCTION calculate_portfolio_var(user_id_param INT, confidence_level DECIMAL(3,2))
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE var_value DECIMAL(10,2);
    
    -- Simplified VaR calculation using historical simulation
    SELECT 
        PERCENTILE_CONT(1 - confidence_level) WITHIN GROUP (ORDER BY daily_return) * portfolio_value
    INTO var_value
    FROM (
        SELECT 
            DATE(trade_date) as trade_date,
            SUM(profit_loss_percentage * trade_amount) / SUM(trade_amount) as daily_return,
            SUM(trade_amount) as portfolio_value
        FROM user_data_db.user_trades
        WHERE user_id = user_id_param
        AND trade_date >= DATE_SUB(NOW(), INTERVAL 90 DAY)
        GROUP BY DATE(trade_date)
        HAVING portfolio_value > 0
    ) daily_returns;
    
    RETURN COALESCE(ABS(var_value), 0);
END //

CREATE FUNCTION assess_concentration_risk(user_id_param INT)
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE concentration_data JSON;
    
    SELECT JSON_OBJECT(
        'herfindahl_index', SUM(POW(weight, 2)),
        'top_asset_weight', MAX(weight),
        'top_3_assets_weight', (
            SELECT SUM(weight) 
            FROM (
                SELECT weight 
                FROM portfolio_weights 
                ORDER BY weight DESC 
                LIMIT 3
            ) top3
        ),
        'concentration_risk_level',
        CASE 
            WHEN MAX(weight) > 0.5 THEN 'Extreme'
            WHEN MAX(weight) > 0.3 THEN 'High'
            WHEN MAX(weight) > 0.2 THEN 'Medium'
            ELSE 'Low'
        END,
        'diversification_score', 1 / SUM(POW(weight, 2))
    )
    INTO concentration_data
    FROM (
        SELECT 
            asset_symbol,
            SUM(trade_amount) / total_portfolio.total_value as weight
        FROM user_data_db.user_trades ut
        CROSS JOIN (
            SELECT SUM(trade_amount) as total_value 
            FROM user_data_db.user_trades 
            WHERE user_id = user_id_param
        ) total_portfolio
        WHERE ut.user_id = user_id_param
        AND ut.trade_date >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        GROUP BY asset_symbol
    ) portfolio_weights;
    
    RETURN COALESCE(concentration_data, JSON_OBJECT('error', 'No portfolio data available'));
END //

DELIMITER ;

-- Create risk assessment views
CREATE VIEW asset_risk_dashboard AS
SELECT 
    arp.symbol,
    arp.risk_score,
    arp.risk_level,
    calculate_volatility_risk(arp.symbol, 30) as volatility_30d,
    assess_liquidity_risk(arp.symbol) as liquidity_assessment,
    arp.market_cap_rank,
    arp.regulatory_risk_score,
    arp.technical_risk_score,
    arp.last_updated,
    CASE 
        WHEN arp.risk_score > 80 THEN 'Extreme Risk'
        WHEN arp.risk_score > 60 THEN 'High Risk'
        WHEN arp.risk_score > 40 THEN 'Medium Risk'
        WHEN arp.risk_score > 20 THEN 'Low Risk'
        ELSE 'Very Low Risk'
    END as risk_category,
    JSON_ARRAY(
        CASE WHEN calculate_volatility_risk(arp.symbol, 30) > 50 THEN 'High Volatility' END,
        CASE WHEN arp.regulatory_risk_score > 0.7 THEN 'Regulatory Risk' END,
        CASE WHEN arp.technical_risk_score > 0.7 THEN 'Technical Risk' END,
        CASE WHEN arp.market_cap_rank > 100 THEN 'Low Market Cap' END
    ) as risk_flags
FROM crypto_data_db.asset_risk_profiles arp
WHERE arp.last_updated >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
ORDER BY arp.risk_score DESC;

CREATE VIEW portfolio_risk_summary AS
SELECT 
    prm.user_id,
    prm.portfolio_value,
    prm.var_95 as value_at_risk_95,
    prm.var_99 as value_at_risk_99,
    prm.expected_shortfall,
    prm.sharpe_ratio,
    prm.max_drawdown,
    prm.beta_to_market,
    assess_concentration_risk(prm.user_id) as concentration_analysis,
    prm.last_calculated,
    CASE 
        WHEN prm.var_95 / prm.portfolio_value > 0.2 THEN 'High Risk'
        WHEN prm.var_95 / prm.portfolio_value > 0.1 THEN 'Medium Risk'
        WHEN prm.var_95 / prm.portfolio_value > 0.05 THEN 'Low Risk'
        ELSE 'Very Low Risk'
    END as portfolio_risk_level,
    CASE 
        WHEN prm.sharpe_ratio > 1.5 THEN 'Excellent'
        WHEN prm.sharpe_ratio > 1.0 THEN 'Good'
        WHEN prm.sharpe_ratio > 0.5 THEN 'Fair'
        ELSE 'Poor'
    END as risk_adjusted_performance
FROM crypto_data_db.portfolio_risk_metrics prm
WHERE prm.last_calculated >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
ORDER BY prm.var_95 / prm.portfolio_value DESC;

CREATE VIEW market_risk_indicators AS
SELECT 
    mvd.date,
    mvd.market_volatility_index,
    mvd.fear_greed_index,
    mvd.correlation_breakdown,
    mvd.liquidity_stress_indicator,
    mvd.regulatory_sentiment_score,
    CASE 
        WHEN mvd.market_volatility_index > 80 THEN 'Extreme Volatility'
        WHEN mvd.market_volatility_index > 60 THEN 'High Volatility'
        WHEN mvd.market_volatility_index > 40 THEN 'Medium Volatility'
        ELSE 'Low Volatility'
    END as volatility_regime,
    CASE 
        WHEN mvd.fear_greed_index > 75 THEN 'Extreme Greed'
        WHEN mvd.fear_greed_index > 55 THEN 'Greed'
        WHEN mvd.fear_greed_index > 45 THEN 'Neutral'
        WHEN mvd.fear_greed_index > 25 THEN 'Fear'
        ELSE 'Extreme Fear'
    END as market_sentiment,
    CASE 
        WHEN mvd.liquidity_stress_indicator > 0.7 THEN 'Liquidity Stress'
        WHEN mvd.liquidity_stress_indicator > 0.5 THEN 'Moderate Stress'
        ELSE 'Normal Liquidity'
    END as liquidity_condition
FROM crypto_data_db.market_volatility_data mvd
WHERE mvd.date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
ORDER BY mvd.date DESC;

-- Create risk assessment query templates
CREATE TABLE crypto_data_db.risk_assessment_templates (
    template_id VARCHAR(50) PRIMARY KEY,
    template_name VARCHAR(200),
    description TEXT,
    sql_template TEXT,
    parameters JSON,
    example_usage TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO crypto_data_db.risk_assessment_templates VALUES
('asset_risk_profile',
 'Individual asset risk assessment',
 'Comprehensive risk analysis for a specific cryptocurrency',
 'SELECT symbol, risk_score, risk_level, volatility_30d, liquidity_assessment, risk_category, risk_flags FROM asset_risk_dashboard WHERE symbol = "{asset}" ORDER BY last_updated DESC LIMIT 1',
 '{"asset": "BTC"}',
 'What is the risk profile for Bitcoin?',
 NOW()),

('portfolio_risk_analysis',
 'Portfolio risk assessment',
 'Complete portfolio risk analysis for a user',
 'SELECT portfolio_value, value_at_risk_95, expected_shortfall, concentration_analysis, portfolio_risk_level, risk_adjusted_performance FROM portfolio_risk_summary WHERE user_id = {user_id}',
 '{"user_id": 123}',
 'Analyze the risk profile of my portfolio',
 NOW()),

('market_risk_overview',
 'Current market risk conditions',
 'Overview of current market risk indicators and conditions',
 'SELECT date, volatility_regime, market_sentiment, liquidity_condition, market_volatility_index, fear_greed_index FROM market_risk_indicators ORDER BY date DESC LIMIT 1',
 '{}',
 'What are the current market risk conditions?',
 NOW()),

('high_risk_assets',
 'Identify high-risk assets',
 'Find assets with elevated risk levels',
 'SELECT symbol, risk_score, risk_level, risk_category, risk_flags FROM asset_risk_dashboard WHERE risk_score > {threshold} ORDER BY risk_score DESC LIMIT {limit}',
 '{"threshold": 70, "limit": 10}',
 'Show me the highest risk cryptocurrencies',
 NOW()),

('correlation_risk',
 'Portfolio correlation risk analysis',
 'Analyze correlation risks within portfolio',
 'SELECT asset1, asset2, correlation_coefficient, risk_contribution FROM crypto_data_db.correlation_matrix WHERE ABS(correlation_coefficient) > {threshold} AND (asset1 IN (SELECT DISTINCT asset_symbol FROM user_data_db.user_trades WHERE user_id = {user_id}) OR asset2 IN (SELECT DISTINCT asset_symbol FROM user_data_db.user_trades WHERE user_id = {user_id})) ORDER BY ABS(correlation_coefficient) DESC',
 '{"threshold": 0.7, "user_id": 123}',
 'What correlation risks exist in my portfolio?',
 NOW()),

('liquidity_risk_assessment',
 'Liquidity risk analysis',
 'Assess liquidity risks for assets or portfolio',
 'SELECT symbol, assess_liquidity_risk(symbol) as liquidity_data FROM (SELECT DISTINCT symbol FROM crypto_data_db.asset_risk_profiles WHERE symbol = "{asset}") assets',
 '{"asset": "ETH"}',
 'What is the liquidity risk for Ethereum?',
 NOW()),

('risk_budget_analysis',
 'Risk budget and allocation analysis',
 'Analyze risk budget utilization and allocation',
 'SELECT user_id, portfolio_value, value_at_risk_95, (value_at_risk_95 / portfolio_value * 100) as var_percentage, concentration_analysis FROM portfolio_risk_summary WHERE user_id = {user_id}',
 '{"user_id": 123}',
 'How is my risk budget allocated?',
 NOW()),

('stress_test_scenarios',
 'Portfolio stress testing',
 'Stress test portfolio under various market scenarios',
 'SELECT scenario_name, portfolio_impact, probability, recovery_time FROM crypto_data_db.stress_test_results WHERE user_id = {user_id} AND test_date >= DATE_SUB(NOW(), INTERVAL 7 DAY) ORDER BY portfolio_impact DESC',
 '{"user_id": 123}',
 'How would my portfolio perform under stress scenarios?',
 NOW());

-- Create risk monitoring and alerting job
CREATE JOB risk_monitoring_alerts AS (
    -- Monitor for high-risk conditions
    INSERT INTO crypto_data_db.risk_alerts (
        alert_type,
        asset_symbol,
        user_id,
        risk_level,
        alert_message,
        risk_score,
        recommended_action,
        created_at
    )
    -- Asset-level risk alerts
    SELECT 
        'asset_risk_spike' as alert_type,
        symbol as asset_symbol,
        NULL as user_id,
        risk_level,
        CONCAT(symbol, ' risk score increased to ', risk_score, ' (', risk_level, ')') as alert_message,
        risk_score,
        'Consider reducing position size or implementing stop-losses' as recommended_action,
        NOW() as created_at
    FROM crypto_data_db.asset_risk_profiles
    WHERE risk_score > 75
    AND last_updated >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    AND risk_score > (
        SELECT AVG(risk_score) * 1.2 
        FROM crypto_data_db.asset_risk_profiles arp2 
        WHERE arp2.symbol = asset_risk_profiles.symbol
        AND arp2.last_updated >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
    )
    
    UNION ALL
    
    -- Portfolio-level risk alerts
    SELECT 
        'portfolio_risk_breach' as alert_type,
        NULL as asset_symbol,
        user_id,
        CASE 
            WHEN var_95 / portfolio_value > 0.25 THEN 'extreme'
            WHEN var_95 / portfolio_value > 0.15 THEN 'high'
            ELSE 'medium'
        END as risk_level,
        CONCAT('Portfolio VaR breach: ', ROUND(var_95 / portfolio_value * 100, 1), '% of portfolio value') as alert_message,
        var_95 / portfolio_value * 100 as risk_score,
        'Review portfolio allocation and consider diversification' as recommended_action,
        NOW() as created_at
    FROM crypto_data_db.portfolio_risk_metrics
    WHERE var_95 / portfolio_value > 0.15
    AND last_calculated >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    
    UNION ALL
    
    -- Market-level risk alerts
    SELECT 
        'market_risk_spike' as alert_type,
        NULL as asset_symbol,
        NULL as user_id,
        CASE 
            WHEN market_volatility_index > 80 THEN 'extreme'
            WHEN market_volatility_index > 60 THEN 'high'
            ELSE 'medium'
        END as risk_level,
        CONCAT('Market volatility spike: VIX at ', market_volatility_index) as alert_message,
        market_volatility_index as risk_score,
        'Consider reducing overall market exposure' as recommended_action,
        NOW() as created_at
    FROM crypto_data_db.market_volatility_data
    WHERE market_volatility_index > 60
    AND date = CURDATE()
    AND market_volatility_index > (
        SELECT AVG(market_volatility_index) * 1.5
        FROM crypto_data_db.market_volatility_data mvd2
        WHERE mvd2.date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    );
)
EVERY 1 hour;

-- Test the risk assessment skill
SELECT 
    'Risk Assessment Skill Test' as test_type,
    COUNT(*) as total_risk_profiles,
    AVG(risk_score) as avg_risk_score,
    COUNT(CASE WHEN risk_level = 'high' THEN 1 END) as high_risk_assets,
    MAX(last_updated) as latest_risk_data
FROM crypto_data_db.asset_risk_profiles;

-- Test risk calculation functions
SELECT 
    'Risk Function Test' as test_type,
    'BTC' as test_asset,
    calculate_volatility_risk('BTC', 30) as btc_volatility_30d,
    assess_liquidity_risk('BTC') as btc_liquidity_risk;

-- Test portfolio risk functions (with sample user)
SELECT 
    'Portfolio Risk Test' as test_type,
    calculate_portfolio_var(1, 0.95) as sample_var_95,
    assess_concentration_risk(1) as sample_concentration_risk;

-- Success validation
SELECT 'Risk Assessment Skill created successfully' as status;

SELECT 
    'Risk Assessment Summary' as summary_type,
    COUNT(DISTINCT symbol) as assets_with_risk_profiles,
    AVG(risk_score) as avg_market_risk,
    COUNT(CASE WHEN risk_level IN ('high', 'extreme') THEN 1 END) as high_risk_count,
    COUNT(CASE WHEN risk_level IN ('low', 'very_low') THEN 1 END) as low_risk_count
FROM crypto_data_db.asset_risk_profiles
WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 24 HOUR);
