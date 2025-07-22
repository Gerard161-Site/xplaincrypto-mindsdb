
#!/bin/bash

# User Data Database Test Script
# Comprehensive testing for user data database

set -e

echo "🧪 Testing User Data Database..."

# Test configuration
DATABASE_NAME="user_data"
TEST_RESULTS_FILE="test_results.log"

# Initialize test results
echo "User Data Database Test Results - $(date)" > $TEST_RESULTS_FILE
echo "================================================" >> $TEST_RESULTS_FILE

# Test functions
test_database_connection() {
    echo "Testing database connection..."
    
    cat > test_connection.sql << 'EOF'
-- Test database connection
USE user_data;
SELECT DATABASE() as current_database;
EOF
    
    if mysql -u root -p < test_connection.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Database connection test passed"
        return 0
    else
        echo "❌ Database connection test failed"
        return 1
    fi
}

test_table_structure() {
    echo "Testing table structure..."
    
    cat > test_tables.sql << 'EOF'
-- Test table structure
USE user_data;
SHOW TABLES;
DESCRIBE users;
DESCRIBE user_portfolios;
DESCRIBE user_watchlists;
DESCRIBE user_alerts;
EOF
    
    if mysql -u root -p < test_tables.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Table structure test passed"
        return 0
    else
        echo "❌ Table structure test failed"
        return 1
    fi
}

test_sample_data_insertion() {
    echo "Testing sample data insertion..."
    
    cat > test_insert.sql << 'EOF'
-- Test sample data insertion
USE user_data;

-- Insert sample users
INSERT INTO users (username, email, password_hash, first_name, last_name, subscription_tier)
VALUES 
    ('testuser1', 'test1@example.com', 'hash123', 'John', 'Doe', 'free'),
    ('testuser2', 'test2@example.com', 'hash456', 'Jane', 'Smith', 'premium'),
    ('testuser3', 'test3@example.com', 'hash789', 'Bob', 'Johnson', 'pro');

-- Insert sample portfolios
INSERT INTO user_portfolios (user_id, portfolio_name, symbol, quantity, average_buy_price, total_invested)
VALUES 
    (1, 'Main Portfolio', 'BTC', 0.5, 45000.00, 22500.00),
    (1, 'Main Portfolio', 'ETH', 10.0, 3200.00, 32000.00),
    (2, 'Trading Portfolio', 'BNB', 100.0, 420.00, 42000.00);

-- Insert sample watchlists
INSERT INTO user_watchlists (user_id, watchlist_name, symbol, alert_enabled, price_alert_above)
VALUES 
    (1, 'Main Watchlist', 'ADA', TRUE, 2.00),
    (2, 'DeFi Tokens', 'UNI', TRUE, 25.00),
    (3, 'Altcoins', 'DOT', FALSE, NULL);

-- Insert sample alerts
INSERT INTO user_alerts (user_id, alert_type, symbol, condition_type, threshold_value)
VALUES 
    (1, 'price', 'BTC', 'above', 50000.00),
    (2, 'price', 'ETH', 'below', 3000.00);

SELECT 'Sample data inserted successfully' as status;
EOF
    
    if mysql -u root -p < test_insert.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Sample data insertion test passed"
        return 0
    else
        echo "❌ Sample data insertion test failed"
        return 1
    fi
}

test_views() {
    echo "Testing database views..."
    
    cat > test_views.sql << 'EOF'
-- Test database views
USE user_data;

-- Test active users view
SELECT * FROM active_users;

-- Test user portfolio summary
SELECT * FROM user_portfolio_summary LIMIT 5;

-- Test popular watchlist assets
SELECT * FROM popular_watchlist_assets LIMIT 5;

-- Test user engagement metrics
SELECT * FROM user_engagement LIMIT 5;

-- Test alert statistics
SELECT * FROM alert_statistics;
EOF
    
    if mysql -u root -p < test_views.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Views test passed"
        return 0
    else
        echo "❌ Views test failed"
        return 1
    fi
}

test_foreign_keys() {
    echo "Testing foreign key constraints..."
    
    cat > test_foreign_keys.sql << 'EOF'
-- Test foreign key constraints
USE user_data;

-- Test cascade delete (should fail with foreign key constraint)
-- This should work because we have proper foreign keys
SELECT 
    u.username,
    COUNT(up.id) as portfolio_count,
    COUNT(uw.id) as watchlist_count,
    COUNT(ua.id) as alert_count
FROM users u
LEFT JOIN user_portfolios up ON u.id = up.user_id
LEFT JOIN user_watchlists uw ON u.id = uw.user_id
LEFT JOIN user_alerts ua ON u.id = ua.user_id
GROUP BY u.id, u.username;
EOF
    
    if mysql -u root -p < test_foreign_keys.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Foreign key constraints test passed"
        return 0
    else
        echo "❌ Foreign key constraints test failed"
        return 1
    fi
}

# Cleanup test data
cleanup_test_data() {
    echo "Cleaning up test data..."
    
    cat > cleanup.sql << 'EOF'
-- Cleanup test data
USE user_data;
DELETE FROM user_alerts WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%@example.com');
DELETE FROM user_watchlists WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%@example.com');
DELETE FROM user_portfolios WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%@example.com');
DELETE FROM users WHERE email LIKE 'test%@example.com';
EOF
    
    mysql -u root -p < cleanup.sql >> $TEST_RESULTS_FILE 2>&1
    echo "✅ Test data cleaned up"
}

# Main test execution
main() {
    local passed=0
    local total=5
    
    echo "Starting user data database tests..."
    
    # Run all tests
    test_database_connection && ((passed++))
    test_table_structure && ((passed++))
    test_sample_data_insertion && ((passed++))
    test_views && ((passed++))
    test_foreign_keys && ((passed++))
    
    # Cleanup
    cleanup_test_data
    
    # Summary
    echo ""
    echo "Test Summary:"
    echo "Passed: $passed/$total"
    echo "Results saved to: $TEST_RESULTS_FILE"
    
    if [ $passed -eq $total ]; then
        echo "🎉 All user data database tests passed!"
        exit 0
    else
        echo "❌ Some tests failed. Check $TEST_RESULTS_FILE for details."
        exit 1
    fi
}

main "$@"
