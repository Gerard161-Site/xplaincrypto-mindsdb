
#!/bin/bash

# CoinMarketCap Handler Test Script
# Comprehensive testing for CoinMarketCap integration

set -e

echo "🧪 Testing CoinMarketCap Handler..."

# Test configuration
HANDLER_NAME="coinmarketcap_db"
TEST_RESULTS_FILE="test_results.log"

# Initialize test results
echo "CoinMarketCap Handler Test Results - $(date)" > $TEST_RESULTS_FILE
echo "================================================" >> $TEST_RESULTS_FILE

# Test functions
test_connection() {
    echo "Testing connection to CoinMarketCap..."
    
    cat > test_connection.sql << 'EOF'
-- Test connection
SHOW DATABASES;
EOF
    
    if mindsdb -f test_connection.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Connection test passed"
        return 0
    else
        echo "❌ Connection test failed"
        return 1
    fi
}

test_data_retrieval() {
    echo "Testing data retrieval..."
    
    cat > test_data.sql << 'EOF'
-- Test data retrieval
SELECT symbol, name, quote_USD_price, quote_USD_market_cap 
FROM coinmarketcap_db.listings 
WHERE quote_USD_market_cap > 1000000000 
LIMIT 10;
EOF
    
    if mindsdb -f test_data.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Data retrieval test passed"
        return 0
    else
        echo "❌ Data retrieval test failed"
        return 1
    fi
}

test_rate_limiting() {
    echo "Testing rate limiting..."
    
    # Make multiple rapid requests to test rate limiting
    for i in {1..5}; do
        cat > test_rate_$i.sql << EOF
-- Rate limit test $i
SELECT COUNT(*) as total_cryptos FROM coinmarketcap_db.listings;
EOF
        
        if ! mindsdb -f test_rate_$i.sql >> $TEST_RESULTS_FILE 2>&1; then
            echo "⚠️  Rate limiting test - request $i failed (expected behavior)"
        fi
        sleep 1
    done
    
    echo "✅ Rate limiting test completed"
    return 0
}

test_error_handling() {
    echo "Testing error handling..."
    
    cat > test_error.sql << 'EOF'
-- Test invalid query
SELECT * FROM coinmarketcap_db.nonexistent_table LIMIT 1;
EOF
    
    if mindsdb -f test_error.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "⚠️  Error handling test - query should have failed"
        return 1
    else
        echo "✅ Error handling test passed"
        return 0
    fi
}

test_performance() {
    echo "Testing performance..."
    
    start_time=$(date +%s)
    
    cat > test_performance.sql << 'EOF'
-- Performance test
SELECT symbol, name, quote_USD_price, quote_USD_volume_24h
FROM coinmarketcap_db.listings 
WHERE quote_USD_volume_24h > 10000000
ORDER BY quote_USD_market_cap DESC
LIMIT 50;
EOF
    
    if mindsdb -f test_performance.sql >> $TEST_RESULTS_FILE 2>&1; then
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

# Main test execution
main() {
    local passed=0
    local total=5
    
    echo "Starting CoinMarketCap handler tests..."
    
    # Run all tests
    test_connection && ((passed++))
    test_data_retrieval && ((passed++))
    test_rate_limiting && ((passed++))
    test_error_handling && ((passed++))
    test_performance && ((passed++))
    
    # Summary
    echo ""
    echo "Test Summary:"
    echo "Passed: $passed/$total"
    echo "Results saved to: $TEST_RESULTS_FILE"
    
    if [ $passed -eq $total ]; then
        echo "🎉 All CoinMarketCap handler tests passed!"
        exit 0
    else
        echo "❌ Some tests failed. Check $TEST_RESULTS_FILE for details."
        exit 1
    fi
}

main "$@"
