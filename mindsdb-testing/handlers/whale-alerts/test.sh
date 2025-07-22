
#!/bin/bash

# Whale Alert Handler Test Script
# Comprehensive testing for Whale Alert integration

set -e

echo "🧪 Testing Whale Alert Handler..."

# Test configuration
HANDLER_NAME="whale_alert_db"
TEST_RESULTS_FILE="test_results.log"

# Initialize test results
echo "Whale Alert Handler Test Results - $(date)" > $TEST_RESULTS_FILE
echo "================================================" >> $TEST_RESULTS_FILE

# Test functions
test_connection() {
    echo "Testing connection to Whale Alert..."
    
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

test_status() {
    echo "Testing API status..."
    
    cat > test_status.sql << 'EOF'
-- Test API status
SELECT * FROM whale_alert_db.status;
EOF
    
    if mindsdb -f test_status.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ API status test passed"
        return 0
    else
        echo "❌ API status test failed"
        return 1
    fi
}

test_blockchains() {
    echo "Testing supported blockchains..."
    
    cat > test_blockchains.sql << 'EOF'
-- Test supported blockchains
SELECT * FROM whale_alert_db.blockchains LIMIT 10;
EOF
    
    if mindsdb -f test_blockchains.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Blockchains test passed"
        return 0
    else
        echo "❌ Blockchains test failed"
        return 1
    fi
}

test_transactions() {
    echo "Testing transaction data..."
    
    cat > test_transactions.sql << 'EOF'
-- Test recent transactions
SELECT blockchain, symbol, amount, amount_usd, from_address, to_address, timestamp
FROM whale_alert_db.transactions 
WHERE min_value = 500000
LIMIT 10;
EOF
    
    if mindsdb -f test_transactions.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Transactions test passed"
        return 0
    else
        echo "❌ Transactions test failed"
        return 1
    fi
}

test_performance() {
    echo "Testing performance..."
    
    start_time=$(date +%s)
    
    cat > test_performance.sql << 'EOF'
-- Performance test
SELECT COUNT(*) as total_blockchains FROM whale_alert_db.blockchains;
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
    
    echo "Starting Whale Alert handler tests..."
    
    # Run all tests
    test_connection && ((passed++))
    test_status && ((passed++))
    test_blockchains && ((passed++))
    test_transactions && ((passed++))
    test_performance && ((passed++))
    
    # Summary
    echo ""
    echo "Test Summary:"
    echo "Passed: $passed/$total"
    echo "Results saved to: $TEST_RESULTS_FILE"
    
    if [ $passed -eq $total ]; then
        echo "🎉 All Whale Alert handler tests passed!"
        exit 0
    else
        echo "❌ Some tests failed. Check $TEST_RESULTS_FILE for details."
        exit 1
    fi
}

main "$@"
