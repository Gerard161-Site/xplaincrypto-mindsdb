
#!/bin/bash

# Binance Handler Test Script
# Comprehensive testing for Binance integration

set -e

echo "🧪 Testing Binance Handler..."

# Test configuration
HANDLER_NAME="binance_db"
TEST_RESULTS_FILE="test_results.log"

# Initialize test results
echo "Binance Handler Test Results - $(date)" > $TEST_RESULTS_FILE
echo "================================================" >> $TEST_RESULTS_FILE

# Test functions
test_connection() {
    echo "Testing connection to Binance..."
    
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

test_ticker_data() {
    echo "Testing ticker data retrieval..."
    
    cat > test_tickers.sql << 'EOF'
-- Test ticker data
SELECT symbol, price, volume, priceChangePercent 
FROM binance_db.tickers 
WHERE symbol IN ('BTCUSDT', 'ETHUSDT', 'BNBUSDT');
EOF
    
    if mindsdb -f test_tickers.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Ticker data test passed"
        return 0
    else
        echo "❌ Ticker data test failed"
        return 1
    fi
}

test_orderbook_data() {
    echo "Testing orderbook data..."
    
    cat > test_orderbook.sql << 'EOF'
-- Test orderbook data
SELECT symbol, bids, asks 
FROM binance_db.orderbook 
WHERE symbol = 'BTCUSDT' 
LIMIT 1;
EOF
    
    if mindsdb -f test_orderbook.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Orderbook data test passed"
        return 0
    else
        echo "❌ Orderbook data test failed"
        return 1
    fi
}

test_trades_data() {
    echo "Testing trades data..."
    
    cat > test_trades.sql << 'EOF'
-- Test trades data
SELECT symbol, price, qty, time 
FROM binance_db.trades 
WHERE symbol = 'BTCUSDT' 
LIMIT 10;
EOF
    
    if mindsdb -f test_trades.sql >> $TEST_RESULTS_FILE 2>&1; then
        echo "✅ Trades data test passed"
        return 0
    else
        echo "❌ Trades data test failed"
        return 1
    fi
}

test_performance() {
    echo "Testing performance..."
    
    start_time=$(date +%s)
    
    cat > test_performance.sql << 'EOF'
-- Performance test
SELECT symbol, price, volume, priceChangePercent
FROM binance_db.tickers 
WHERE volume > 1000000
ORDER BY volume DESC
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
    
    echo "Starting Binance handler tests..."
    
    # Run all tests
    test_connection && ((passed++))
    test_ticker_data && ((passed++))
    test_orderbook_data && ((passed++))
    test_trades_data && ((passed++))
    test_performance && ((passed++))
    
    # Summary
    echo ""
    echo "Test Summary:"
    echo "Passed: $passed/$total"
    echo "Results saved to: $TEST_RESULTS_FILE"
    
    if [ $passed -eq $total ]; then
        echo "🎉 All Binance handler tests passed!"
        exit 0
    else
        echo "❌ Some tests failed. Check $TEST_RESULTS_FILE for details."
        exit 1
    fi
}

main "$@"
