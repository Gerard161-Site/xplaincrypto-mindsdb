
#!/bin/bash

# User Data Database Setup Script
# Sets up the user data database for XplainCrypto platform

set -e

echo "👤 Setting up User Data Database..."

# Configuration
DATABASE_NAME="user_data"

# Create database SQL
cat > create_database.sql << 'EOF'
-- Create User Data Database
CREATE DATABASE IF NOT EXISTS user_data;
USE user_data;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    profile_image_url VARCHAR(500),
    subscription_tier ENUM('free', 'premium', 'pro') DEFAULT 'free',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    email_verified BOOLEAN DEFAULT FALSE,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_subscription_tier (subscription_tier)
);

-- User portfolios
CREATE TABLE IF NOT EXISTS user_portfolios (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    portfolio_name VARCHAR(100) NOT NULL,
    symbol VARCHAR(20) NOT NULL,
    quantity DECIMAL(30,8) NOT NULL,
    average_buy_price DECIMAL(20,8),
    total_invested DECIMAL(20,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_symbol (symbol),
    INDEX idx_user_symbol (user_id, symbol)
);

-- User watchlists
CREATE TABLE IF NOT EXISTS user_watchlists (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    watchlist_name VARCHAR(100) NOT NULL,
    symbol VARCHAR(20) NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    alert_enabled BOOLEAN DEFAULT FALSE,
    price_alert_above DECIMAL(20,8),
    price_alert_below DECIMAL(20,8),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_watchlist_symbol (user_id, watchlist_name, symbol),
    INDEX idx_user_id (user_id),
    INDEX idx_symbol (symbol)
);

-- User preferences
CREATE TABLE IF NOT EXISTS user_preferences (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    preference_key VARCHAR(100) NOT NULL,
    preference_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_preference (user_id, preference_key),
    INDEX idx_user_id (user_id),
    INDEX idx_preference_key (preference_key)
);

-- User activity log
CREATE TABLE IF NOT EXISTS user_activity (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    activity_description TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_activity_type (activity_type),
    INDEX idx_created_at (created_at)
);

-- User alerts
CREATE TABLE IF NOT EXISTS user_alerts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    alert_type ENUM('price', 'volume', 'news', 'whale', 'defi') NOT NULL,
    symbol VARCHAR(20),
    condition_type ENUM('above', 'below', 'change_percent') NOT NULL,
    threshold_value DECIMAL(20,8),
    is_active BOOLEAN DEFAULT TRUE,
    triggered_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_alert_type (alert_type),
    INDEX idx_is_active (is_active)
);

-- User sessions
CREATE TABLE IF NOT EXISTS user_sessions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_session_token (session_token),
    INDEX idx_expires_at (expires_at)
);
EOF

# Create views SQL
cat > create_views.sql << 'EOF'
-- User Data Views
USE user_data;

-- Active users summary
CREATE OR REPLACE VIEW active_users AS
SELECT 
    COUNT(*) as total_active_users,
    COUNT(CASE WHEN subscription_tier = 'premium' THEN 1 END) as premium_users,
    COUNT(CASE WHEN subscription_tier = 'pro' THEN 1 END) as pro_users,
    COUNT(CASE WHEN last_login > NOW() - INTERVAL 24 HOUR THEN 1 END) as daily_active_users,
    COUNT(CASE WHEN last_login > NOW() - INTERVAL 7 DAY THEN 1 END) as weekly_active_users,
    COUNT(CASE WHEN created_at > NOW() - INTERVAL 30 DAY THEN 1 END) as new_users_30d
FROM users 
WHERE is_active = TRUE;

-- User portfolio summary
CREATE OR REPLACE VIEW user_portfolio_summary AS
SELECT 
    u.id as user_id,
    u.username,
    COUNT(DISTINCT up.symbol) as unique_assets,
    COUNT(*) as total_positions,
    SUM(up.total_invested) as total_invested_amount,
    AVG(up.quantity * up.average_buy_price) as avg_position_size
FROM users u
LEFT JOIN user_portfolios up ON u.id = up.user_id
WHERE u.is_active = TRUE
GROUP BY u.id, u.username;

-- Popular watchlist assets
CREATE OR REPLACE VIEW popular_watchlist_assets AS
SELECT 
    symbol,
    COUNT(DISTINCT user_id) as watchers_count,
    COUNT(CASE WHEN alert_enabled = TRUE THEN 1 END) as alert_enabled_count,
    AVG(price_alert_above) as avg_price_alert_above,
    AVG(price_alert_below) as avg_price_alert_below
FROM user_watchlists
GROUP BY symbol
ORDER BY watchers_count DESC;

-- User engagement metrics
CREATE OR REPLACE VIEW user_engagement AS
SELECT 
    u.id as user_id,
    u.username,
    u.subscription_tier,
    u.created_at as registration_date,
    u.last_login,
    DATEDIFF(NOW(), u.created_at) as days_since_registration,
    DATEDIFF(NOW(), u.last_login) as days_since_last_login,
    COUNT(DISTINCT ua.id) as total_activities,
    COUNT(DISTINCT up.id) as portfolio_positions,
    COUNT(DISTINCT uw.id) as watchlist_items,
    COUNT(DISTINCT ual.id) as active_alerts
FROM users u
LEFT JOIN user_activity ua ON u.id = ua.user_id
LEFT JOIN user_portfolios up ON u.id = up.user_id
LEFT JOIN user_watchlists uw ON u.id = uw.user_id
LEFT JOIN user_alerts ual ON u.id = ual.user_id AND ual.is_active = TRUE
WHERE u.is_active = TRUE
GROUP BY u.id;

-- Alert statistics
CREATE OR REPLACE VIEW alert_statistics AS
SELECT 
    alert_type,
    COUNT(*) as total_alerts,
    COUNT(CASE WHEN is_active = TRUE THEN 1 END) as active_alerts,
    COUNT(CASE WHEN triggered_at IS NOT NULL THEN 1 END) as triggered_alerts,
    AVG(threshold_value) as avg_threshold,
    COUNT(DISTINCT user_id) as unique_users
FROM user_alerts
GROUP BY alert_type
ORDER BY total_alerts DESC;
EOF

# Execute setup
execute_setup() {
    echo "Creating user data database and tables..."
    
    # Execute SQL commands
    if command -v mysql &> /dev/null; then
        mysql -u root -p < create_database.sql
        mysql -u root -p < create_views.sql
        echo "✅ User data database created successfully"
    elif command -v mindsdb &> /dev/null; then
        mindsdb -f create_database.sql
        mindsdb -f create_views.sql
        echo "✅ User data database created via MindsDB"
    else
        echo "⚠️  Neither MySQL nor MindsDB CLI found. SQL files created for manual execution."
    fi
}

# Validation
validate_setup() {
    echo "Validating user data database setup..."
    
    cat > validate.sql << 'EOF'
-- Validation queries
USE user_data;
SHOW TABLES;
DESCRIBE users;
DESCRIBE user_portfolios;
DESCRIBE user_watchlists;
SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = 'user_data';
EOF
    
    if command -v mysql &> /dev/null; then
        mysql -u root -p < validate.sql
        echo "✅ Validation completed"
    elif command -v mindsdb &> /dev/null; then
        mindsdb -f validate.sql
        echo "✅ Validation completed via MindsDB"
    else
        echo "⚠️  Manual validation required"
    fi
}

# Main execution
main() {
    execute_setup
    validate_setup
    echo "🎉 User data database setup completed!"
}

main "$@"
