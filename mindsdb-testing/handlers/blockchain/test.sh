
#!/bin/bash

# Blockchain Handler Test Script
# Comprehensive testing for blockchain data integration

set -e

echo "🧪 Testing Blockchain Handler..."

# Test configuration
HANDLER_NAME="blockchain_db"
TEST_RESULTS_FILE="test_results.log"

# Initialize test results
echo "Blockchain Handler Test Results - $(date)" > $TEST_RESULTS_FILE
echo "================================================" >> $TEST_RESULTS_FILE

# Test functions
test_connection() {
    echo "Testing connection to Blockchain API..."
    
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

test_stats_data() {
    echo "Testing network statistics..."
    
    cat > test_stats.sql << 'EOF'
-- Test network stats
SELECT * FROM blockchain_db.stats LIMIT 1;
EOF
    
    if mindsdb -f test_stats.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Network stats test passed"
        return 0
    else
        echo "❌ Network stats test failed"
        return 1
    fi
}

test_block_data() {
    echo "Testing block data retrieval..."
    
    cat > test_blocks.sql << 'EOF'
-- Test block data (latest block)
SELECT hash, height, time, n_tx 
FROM blockchain_db.blocks 
ORDER BY height DESC 
LIMIT 1;
EOF
    
    if mindsdb -f test_blocks.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Block data test passed"
        return 0
    else
        echo "❌ Block data test failed"
        return 1
    fi
}

test_address_data() {
    echo "Testing address data..."
    
    cat > test_addresses.sql << 'EOF'
-- Test address data (sample Bitcoin address)
SELECT address, final_balance, n_tx, total_received 
FROM blockchain_db.addresses 
WHERE address = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'
LIMIT 1;
EOF
    
    if mindsdb -f test_addresses.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Address data test passed"
        return 0
    else
        echo "❌ Address data test failed"
        return 1
    fi
}

test_performance() {
    echo "Testing performance..."
    
    start_time=$(date +%s)
    
    cat > test_performance.sql << 'EOF'
-- Performance test
SELECT * FROM blockchain_db.stats;
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
    
    echo "Starting Blockchain handler tests..."
    
    # Run all tests
    test_connection && ((passed++))
    test_stats_data && ((passed++))
    test_block_data && ((passed++))
    test_address_data && ((passed++))
    test_performance && ((passed++))
    
    # Summary
    echo ""
    echo "Test Summary:"
    echo "Passed: $passed/$total"
    echo "Results saved to: $TEST_RESULTS_FILE"
    
    if [ $passed -eq $total ]; then
        echo "🎉 All Blockchain handler tests passed!"
        exit 0
    else
        echo "❌ Some tests failed. Check $TEST_RESULTS_FILE for details."
        exit 1
    fi
}

main "$@"
