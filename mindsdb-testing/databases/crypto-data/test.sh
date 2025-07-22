
#!/bin/bash

# Crypto Data Database Test Script
# Comprehensive testing for crypto data database

set -e

echo "🧪 Testing Crypto Data Database..."

# Test configuration
DATABASE_NAME="crypto_data"
TEST_RESULTS_FILE="test_results.log"

# Initialize test results
echo "Crypto Data Database Test Results - $(date)" > $TEST_RESULTS_FILE
echo "================================================" >> $TEST_RESULTS_FILE

# Test functions
test_database_connection() {
    echo "Testing database connection..."
    
    cat > test_connection.sql << 'EOF'
-- Test database connection
USE crypto_data;
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
USE crypto_data;
SHOW TABLES;
DESCRIBE price_data;
DESCRIBE defi_protocols;
DESCRIBE whale_transactions;
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
USE crypto_data;

-- Insert sample price data
INSERT INTO price_data (symbol, price, volume_24h, market_cap, price_change_24h, source)
VALUES 
    ('BTC', 45000.00, 25000000000, 850000000000, 2.5, 'test'),
    ('ETH', 3200.00, 15000000000, 380000000000, 1.8, 'test'),
    ('BNB', 420.00, 2000000000, 65000000000, -0.5, 'test');

-- Insert sample DeFi data
INSERT INTO defi_protocols (protocol_name, category, blockchain, tvl_usd, volume_24h)
VALUES 
    ('Uniswap', 'DEX', 'Ethereum', 8500000000, 1200000000),
    ('Aave', 'Lending', 'Ethereum', 12000000000, 500000000),
    ('PancakeSwap', 'DEX', 'BSC', 4200000000, 800000000);

-- Insert sample whale transaction
INSERT INTO whale_transactions (blockchain, transaction_hash, symbol, amount_usd, transaction_type)
VALUES 
    ('Bitcoin', 'test_hash_123', 'BTC', 15000000, 'transfer'),
    ('Ethereum', 'test_hash_456', 'ETH', 8000000, 'exchange_deposit');

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
USE crypto_data;

-- Test latest prices view
SELECT * FROM latest_prices LIMIT 5;

-- Test top cryptos view
SELECT * FROM top_cryptos LIMIT 5;

-- Test DeFi protocols view
SELECT * FROM top_defi_protocols LIMIT 5;

-- Test market overview
SELECT * FROM market_overview;
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
USE crypto_data;

-- Complex aggregation query
SELECT 
    symbol,
    COUNT(*) as price_points,
    AVG(price) as avg_price,
    MAX(price) as max_price,
    MIN(price) as min_price,
    STDDEV(price) as price_volatility
FROM price_data 
GROUP BY symbol
ORDER BY price_volatility DESC;

-- Join query test
SELECT p.symbol, p.current_price, d.protocol_name, d.current_tvl
FROM latest_prices p
LEFT JOIN top_defi_protocols d ON p.symbol = CONCAT(SUBSTRING(d.protocol_name, 1, 3), 'USDT')
LIMIT 10;
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
USE crypto_data;
DELETE FROM price_data WHERE source = 'test';
DELETE FROM defi_protocols WHERE protocol_name IN ('Uniswap', 'Aave', 'PancakeSwap');
DELETE FROM whale_transactions WHERE transaction_hash LIKE 'test_hash_%';
EOF
    
    mysql -u root -p < cleanup.sql >> $TEST_RESULTS_FILE 2>&1
    echo "✅ Test data cleaned up"
}

# Main test execution
main() {
    local passed=0
    local total=5
    
    echo "Starting crypto data database tests..."
    
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
        echo "🎉 All crypto data database tests passed!"
        exit 0
    else
        echo "❌ Some tests failed. Check $TEST_RESULTS_FILE for details."
        exit 1
    fi
}

main "$@"
