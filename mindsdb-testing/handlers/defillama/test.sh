
#!/bin/bash

# DefiLlama Handler Test Script
# Comprehensive testing for DefiLlama integration

set -e

echo "🧪 Testing DefiLlama Handler..."

# Test configuration
HANDLER_NAME="defillama_db"
TEST_RESULTS_FILE="test_results.log"

# Initialize test results
echo "DefiLlama Handler Test Results - $(date)" > $TEST_RESULTS_FILE
echo "================================================" >> $TEST_RESULTS_FILE

# Test functions
test_connection() {
    echo "Testing connection to DefiLlama..."
    
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

test_protocol_data() {
    echo "Testing protocol data retrieval..."
    
    cat > test_protocols.sql << 'EOF'
-- Test protocol data
SELECT name, tvl, category, chains 
FROM defillama_db.protocols 
WHERE tvl > 100000000 
LIMIT 10;
EOF
    
    if mindsdb -f test_protocols.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Protocol data test passed"
        return 0
    else
        echo "❌ Protocol data test failed"
        return 1
    fi
}

test_tvl_data() {
    echo "Testing TVL historical data..."
    
    cat > test_tvl.sql << 'EOF'
-- Test TVL data
SELECT date, totalLiquidityUSD 
FROM defillama_db.tvl_historical 
ORDER BY date DESC 
LIMIT 30;
EOF
    
    if mindsdb -f test_tvl.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ TVL data test passed"
        return 0
    else
        echo "❌ TVL data test failed"
        return 1
    fi
}

test_chain_data() {
    echo "Testing chain data..."
    
    cat > test_chains.sql << 'EOF'
-- Test chain data
SELECT name, tvl, tokenSymbol 
FROM defillama_db.chains 
WHERE tvl > 1000000000 
ORDER BY tvl DESC;
EOF
    
    if mindsdb -f test_chains.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Chain data test passed"
        return 0
    else
        echo "❌ Chain data test failed"
        return 1
    fi
}

test_performance() {
    echo "Testing performance..."
    
    start_time=$(date +%s)
    
    cat > test_performance.sql << 'EOF'
-- Performance test
SELECT name, tvl, category, chains
FROM defillama_db.protocols 
WHERE category IN ('Dexes', 'Lending', 'Yield')
ORDER BY tvl DESC
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
    
    echo "Starting DefiLlama handler tests..."
    
    # Run all tests
    test_connection && ((passed++))
    test_protocol_data && ((passed++))
    test_tvl_data && ((passed++))
    test_chain_data && ((passed++))
    test_performance && ((passed++))
    
    # Summary
    echo ""
    echo "Test Summary:"
    echo "Passed: $passed/$total"
    echo "Results saved to: $TEST_RESULTS_FILE"
    
    if [ $passed -eq $total ]; then
        echo "🎉 All DefiLlama handler tests passed!"
        exit 0
    else
        echo "❌ Some tests failed. Check $TEST_RESULTS_FILE for details."
        exit 1
    fi
}

main "$@"
