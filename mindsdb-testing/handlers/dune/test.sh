
#!/bin/bash

# Dune Analytics Handler Test Script
# Comprehensive testing for Dune Analytics integration

set -e

echo "🧪 Testing Dune Analytics Handler..."

# Test configuration
HANDLER_NAME="dune_db"
TEST_RESULTS_FILE="test_results.log"

# Initialize test results
echo "Dune Analytics Handler Test Results - $(date)" > $TEST_RESULTS_FILE
echo "================================================" >> $TEST_RESULTS_FILE

# Test functions
test_connection() {
    echo "Testing connection to Dune Analytics..."
    
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

test_query_execution() {
    echo "Testing query execution..."
    
    cat > test_execution.sql << 'EOF'
-- Test query execution (sample query ID)
SELECT execution_id, state, created_at 
FROM dune_db.executions 
WHERE query_id = 1234567
LIMIT 5;
EOF
    
    if mindsdb -f test_execution.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Query execution test passed"
        return 0
    else
        echo "❌ Query execution test failed"
        return 1
    fi
}

test_query_results() {
    echo "Testing query results retrieval..."
    
    cat > test_results.sql << 'EOF'
-- Test query results
SELECT * FROM dune_db.query_results 
WHERE execution_id = 'sample_execution_id'
LIMIT 10;
EOF
    
    if mindsdb -f test_results.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Query results test passed"
        return 0
    else
        echo "❌ Query results test failed"
        return 1
    fi
}

test_query_metadata() {
    echo "Testing query metadata..."
    
    cat > test_metadata.sql << 'EOF'
-- Test query metadata
SELECT query_id, name, description, created_at 
FROM dune_db.queries 
LIMIT 5;
EOF
    
    if mindsdb -f test_metadata.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Query metadata test passed"
        return 0
    else
        echo "❌ Query metadata test failed"
        return 1
    fi
}

test_performance() {
    echo "Testing performance..."
    
    start_time=$(date +%s)
    
    cat > test_performance.sql << 'EOF'
-- Performance test
SELECT COUNT(*) as total_queries FROM dune_db.queries;
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
    
    echo "Starting Dune Analytics handler tests..."
    
    # Run all tests
    test_connection && ((passed++))
    test_query_execution && ((passed++))
    test_query_results && ((passed++))
    test_query_metadata && ((passed++))
    test_performance && ((passed++))
    
    # Summary
    echo ""
    echo "Test Summary:"
    echo "Passed: $passed/$total"
    echo "Results saved to: $TEST_RESULTS_FILE"
    
    if [ $passed -eq $total ]; then
        echo "🎉 All Dune Analytics handler tests passed!"
        exit 0
    else
        echo "❌ Some tests failed. Check $TEST_RESULTS_FILE for details."
        exit 1
    fi
}

main "$@"
