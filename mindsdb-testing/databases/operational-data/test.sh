
#!/bin/bash

# Operational Data Database Test Script
# Comprehensive testing for operational data database

set -e

echo "🧪 Testing Operational Data Database..."

# Test configuration
DATABASE_NAME="operational_data"
TEST_RESULTS_FILE="test_results.log"

# Initialize test results
echo "Operational Data Database Test Results - $(date)" > $TEST_RESULTS_FILE
echo "================================================" >> $TEST_RESULTS_FILE

# Test functions
test_database_connection() {
    echo "Testing database connection..."
    
    cat > test_connection.sql << 'EOF'
-- Test database connection
USE operational_data;
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
USE operational_data;
SHOW TABLES;
DESCRIBE system_metrics;
DESCRIBE api_usage;
DESCRIBE error_logs;
DESCRIBE pipeline_status;
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
USE operational_data;

-- Insert sample system metrics
INSERT INTO system_metrics (metric_name, metric_value, metric_unit, component, hostname)
VALUES 
    ('cpu_usage', 75.5, 'percent', 'web_server', 'web01'),
    ('memory_usage', 82.3, 'percent', 'web_server', 'web01'),
    ('disk_usage', 45.2, 'percent', 'database', 'db01'),
    ('response_time', 250.0, 'ms', 'api_gateway', 'api01');

-- Insert sample API usage
INSERT INTO api_usage (endpoint, method, user_id, ip_address, response_code, response_time_ms)
VALUES 
    ('/api/v1/prices', 'GET', 1001, '192.168.1.100', 200, 150),
    ('/api/v1/portfolio', 'GET', 1002, '192.168.1.101', 200, 300),
    ('/api/v1/alerts', 'POST', 1003, '192.168.1.102', 201, 200),
    ('/api/v1/invalid', 'GET', NULL, '192.168.1.103', 404, 50);

-- Insert sample error logs
INSERT INTO error_logs (error_level, component, error_message, error_code, user_id)
VALUES 
    ('ERROR', 'price_handler', 'Failed to fetch price data from CoinMarketCap', 'CMC_API_ERROR', NULL),
    ('WARNING', 'user_auth', 'Multiple failed login attempts', 'AUTH_WARNING', 1001),
    ('CRITICAL', 'database', 'Connection pool exhausted', 'DB_POOL_ERROR', NULL);

-- Insert sample pipeline status
INSERT INTO pipeline_status (pipeline_name, pipeline_type, status, start_time, end_time, records_processed)
VALUES 
    ('price_data_sync', 'data_ingestion', 'completed', NOW() - INTERVAL 1 HOUR, NOW() - INTERVAL 50 MINUTE, 5000),
    ('defi_data_sync', 'data_ingestion', 'running', NOW() - INTERVAL 30 MINUTE, NULL, 2500),
    ('user_analytics', 'data_processing', 'failed', NOW() - INTERVAL 2 HOUR, NOW() - INTERVAL 1 HOUR, 0);

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
USE operational_data;

-- Test system health view
SELECT * FROM system_health;

-- Test API performance view
SELECT * FROM api_performance LIMIT 5;

-- Test error summary view
SELECT * FROM error_summary LIMIT 5;

-- Test pipeline health view
SELECT * FROM pipeline_health LIMIT 5;

-- Test active alerts view
SELECT * FROM active_alerts LIMIT 5;
EOF
    
    if mysql -u root -p < test_views.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Views test passed"
        return 0
    else
        echo "❌ Views test failed"
        return 1
    fi
}

test_performance() {
    echo "Testing database performance..."
    
    start_time=$(date +%s)
    
    cat > test_performance.sql << 'EOF'
-- Performance test queries
USE operational_data;

-- Complex aggregation query
SELECT 
    component,
    DATE(timestamp) as date,
    COUNT(*) as metric_count,
    AVG(metric_value) as avg_value,
    MAX(metric_value) as max_value,
    MIN(metric_value) as min_value
FROM system_metrics 
GROUP BY component, DATE(timestamp)
ORDER BY date DESC, component;

-- API usage analysis
SELECT 
    endpoint,
    COUNT(*) as request_count,
    AVG(response_time_ms) as avg_response_time,
    COUNT(CASE WHEN response_code >= 400 THEN 1 END) as error_count
FROM api_usage
GROUP BY endpoint
ORDER BY request_count DESC;
EOF
    
    if mysql -u root -p < test_performance.sql >> $TEST_RESULTS_FILE 2>&1; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo "✅ Performance test passed (${duration}s)"
        echo "Performance: ${duration}s" >> $TEST_RESULTS_FILE
        return 0
    else
        echo "❌ Performance test failed"
        return 1
    fi
}

# Cleanup test data
cleanup_test_data() {
    echo "Cleaning up test data..."
    
    cat > cleanup.sql << 'EOF'
-- Cleanup test data
USE operational_data;
DELETE FROM system_metrics WHERE hostname IN ('web01', 'db01', 'api01');
DELETE FROM api_usage WHERE ip_address LIKE '192.168.1.%';
DELETE FROM error_logs WHERE component IN ('price_handler', 'user_auth', 'database');
DELETE FROM pipeline_status WHERE pipeline_name IN ('price_data_sync', 'defi_data_sync', 'user_analytics');
EOF
    
    mysql -u root -p < cleanup.sql >> $TEST_RESULTS_FILE 2>&1
    echo "✅ Test data cleaned up"
}

# Main test execution
main() {
    local passed=0
    local total=5
    
    echo "Starting operational data database tests..."
    
    # Run all tests
    test_database_connection && ((passed++))
    test_table_structure && ((passed++))
    test_sample_data_insertion && ((passed++))
    test_views && ((passed++))
    test_performance && ((passed++))
    
    # Cleanup
    cleanup_test_data
    
    # Summary
    echo ""
    echo "Test Summary:"
    echo "Passed: $passed/$total"
    echo "Results saved to: $TEST_RESULTS_FILE"
    
    if [ $passed -eq $total ]; then
        echo "🎉 All operational data database tests passed!"
        exit 0
    else
        echo "❌ Some tests failed. Check $TEST_RESULTS_FILE for details."
        exit 1
    fi
}

main "$@"
