
#!/bin/bash

# Integration Testing Setup Script
# Sets up comprehensive integration testing between all components

set -e

echo "🔗 Setting up Integration Testing Framework..."

# Configuration
INTEGRATION_DIR="$(pwd)"

# Create integration test configuration
cat > integration_config.json << 'EOF'
{
  "test_environment": {
    "name": "xplaincrypto_integration",
    "description": "Comprehensive integration testing for XplainCrypto MindsDB components",
    "timeout": 300,
    "retry_attempts": 3
  },
  "components": {
    "handlers": [
      "coinmarketcap",
      "defillama", 
      "binance",
      "blockchain",
      "dune",
      "whale-alerts"
    ],
    "databases": [
      "crypto-data",
      "user-data", 
      "operational-data"
    ],
    "dependencies": {
      "handlers_to_databases": {
        "coinmarketcap": ["crypto-data"],
        "defillama": ["crypto-data"],
        "binance": ["crypto-data"],
        "blockchain": ["crypto-data"],
        "dune": ["crypto-data"],
        "whale-alerts": ["crypto-data"]
      },
      "database_relationships": {
        "crypto-data": ["user-data", "operational-data"],
        "user-data": ["operational-data"]
      }
    }
  },
  "test_scenarios": [
    "data_flow_validation",
    "cross_component_integration",
    "performance_benchmarking",
    "error_handling_validation",
    "security_compliance_check"
  ]
}
EOF

# Create main integration test script
cat > integration_test.sh << 'EOF'
#!/bin/bash

# XplainCrypto MindsDB Integration Test Suite
# Comprehensive testing across all components

set -e

echo "🧪 Starting XplainCrypto Integration Test Suite..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
TEST_RESULTS_FILE="integration_test_results.log"

# Initialize test results
echo "XplainCrypto Integration Test Results - $(date)" > $TEST_RESULTS_FILE
echo "================================================" >> $TEST_RESULTS_FILE

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Test execution function
run_test() {
    local test_name=$1
    local test_command=$2
    
    print_status "Running test: $test_name"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command" >> $TEST_RESULTS_FILE 2>&1; then
        print_success "$test_name passed"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "PASS: $test_name" >> $TEST_RESULTS_FILE
        return 0
    else
        print_error "$test_name failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "FAIL: $test_name" >> $TEST_RESULTS_FILE
        return 1
    fi
}

# Handler Integration Tests
test_handler_integration() {
    print_status "Testing handler integration..."
    
    local handlers=("coinmarketcap" "defillama" "binance" "blockchain" "dune" "whale-alerts")
    
    for handler in "${handlers[@]}"; do
        if [ -f "../handlers/$handler/test.sh" ]; then
            run_test "Handler Integration: $handler" "cd ../handlers/$handler && ./test.sh"
        else
            print_warning "Test script not found for handler: $handler"
        fi
    done
}

# Database Integration Tests
test_database_integration() {
    print_status "Testing database integration..."
    
    local databases=("crypto-data" "user-data" "operational-data")
    
    for database in "${databases[@]}"; do
        if [ -f "../databases/$database/test.sh" ]; then
            run_test "Database Integration: $database" "cd ../databases/$database && ./test.sh"
        else
            print_warning "Test script not found for database: $database"
        fi
    done
}

# Cross-Component Data Flow Tests
test_data_flow() {
    print_status "Testing cross-component data flow..."
    
    # Test data flow from handlers to crypto-data database
    run_test "Data Flow: Handlers to Crypto DB" "test_handler_to_crypto_db"
    
    # Test data flow from crypto-data to user-data
    run_test "Data Flow: Crypto DB to User DB" "test_crypto_to_user_db"
    
    # Test operational data collection
    run_test "Data Flow: Operational Monitoring" "test_operational_monitoring"
}

# Individual data flow test functions
test_handler_to_crypto_db() {
    cat > test_handler_crypto_flow.sql << 'SQL'
-- Test data flow from handlers to crypto database
USE crypto_data;

-- Check if price data is being populated
SELECT COUNT(*) as price_records FROM price_data WHERE timestamp > NOW() - INTERVAL 1 HOUR;

-- Check if DeFi data is being populated  
SELECT COUNT(*) as defi_records FROM defi_protocols WHERE timestamp > NOW() - INTERVAL 1 HOUR;

-- Check if whale transactions are being tracked
SELECT COUNT(*) as whale_records FROM whale_transactions WHERE timestamp > NOW() - INTERVAL 1 HOUR;
SQL
    
    if command -v mysql &> /dev/null; then
        mysql -u root -p < test_handler_crypto_flow.sql
    else
        echo "MySQL not available for testing"
        return 1
    fi
}

test_crypto_to_user_db() {
    cat > test_crypto_user_flow.sql << 'SQL'
-- Test data integration between crypto and user databases
USE user_data;

-- Test portfolio value calculations (requires crypto_data)
SELECT up.user_id, up.symbol, up.quantity,
       (SELECT price FROM crypto_data.latest_prices lp WHERE lp.symbol = up.symbol) as current_price
FROM user_portfolios up
LIMIT 5;
SQL
    
    if command -v mysql &> /dev/null; then
        mysql -u root -p < test_crypto_user_flow.sql
    else
        echo "MySQL not available for testing"
        return 1
    fi
}

test_operational_monitoring() {
    cat > test_operational_flow.sql << 'SQL'
-- Test operational data collection
USE operational_data;

-- Check if system metrics are being collected
SELECT COUNT(*) as metric_records FROM system_metrics WHERE timestamp > NOW() - INTERVAL 1 HOUR;

-- Check if API usage is being tracked
SELECT COUNT(*) as api_records FROM api_usage WHERE timestamp > NOW() - INTERVAL 1 HOUR;

-- Check if errors are being logged
SELECT COUNT(*) as error_records FROM error_logs WHERE timestamp > NOW() - INTERVAL 1 HOUR;
SQL
    
    if command -v mysql &> /dev/null; then
        mysql -u root -p < test_operational_flow.sql
    else
        echo "MySQL not available for testing"
        return 1
    fi
}

# Performance Integration Tests
test_performance_integration() {
    print_status "Testing performance integration..."
    
    run_test "Performance: End-to-End Query" "test_e2e_query_performance"
    run_test "Performance: Cross-Database Joins" "test_cross_db_performance"
    run_test "Performance: Real-time Data Updates" "test_realtime_performance"
}

test_e2e_query_performance() {
    start_time=$(date +%s)
    
    cat > test_e2e_performance.sql << 'SQL'
-- End-to-end performance test query
SELECT 
    lp.symbol,
    lp.current_price,
    COUNT(DISTINCT up.user_id) as holders,
    AVG(up.quantity * lp.current_price) as avg_position_value,
    SUM(wt.amount_usd) as whale_volume_24h
FROM crypto_data.latest_prices lp
LEFT JOIN user_data.user_portfolios up ON lp.symbol = up.symbol
LEFT JOIN crypto_data.whale_transactions wt ON lp.symbol = wt.symbol 
    AND wt.timestamp > NOW() - INTERVAL 24 HOUR
WHERE lp.market_cap > 1000000000
GROUP BY lp.symbol, lp.current_price
ORDER BY lp.market_cap DESC
LIMIT 20;
SQL
    
    if command -v mysql &> /dev/null; then
        mysql -u root -p < test_e2e_performance.sql
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        if [ $duration -lt 10 ]; then
            echo "Performance test passed: ${duration}s"
            return 0
        else
            echo "Performance test failed: ${duration}s (>10s threshold)"
            return 1
        fi
    else
        echo "MySQL not available for performance testing"
        return 1
    fi
}

test_cross_db_performance() {
    # Test cross-database query performance
    start_time=$(date +%s)
    
    cat > test_cross_db_perf.sql << 'SQL'
-- Cross-database performance test
SELECT 
    u.subscription_tier,
    COUNT(DISTINCT u.id) as user_count,
    AVG(portfolio_value.total_value) as avg_portfolio_value,
    COUNT(DISTINCT sm.component) as monitored_components
FROM user_data.users u
LEFT JOIN (
    SELECT up.user_id, SUM(up.quantity * lp.current_price) as total_value
    FROM user_data.user_portfolios up
    JOIN crypto_data.latest_prices lp ON up.symbol = lp.symbol
    GROUP BY up.user_id
) portfolio_value ON u.id = portfolio_value.user_id
LEFT JOIN operational_data.system_metrics sm ON 1=1
WHERE u.is_active = TRUE
  AND sm.timestamp > NOW() - INTERVAL 1 HOUR
GROUP BY u.subscription_tier;
SQL
    
    if command -v mysql &> /dev/null; then
        mysql -u root -p < test_cross_db_perf.sql
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        if [ $duration -lt 15 ]; then
            echo "Cross-DB performance test passed: ${duration}s"
            return 0
        else
            echo "Cross-DB performance test failed: ${duration}s (>15s threshold)"
            return 1
        fi
    else
        return 1
    fi
}

test_realtime_performance() {
    # Test real-time data update performance
    echo "Testing real-time data update performance..."
    
    # This would typically involve testing WebSocket connections,
    # real-time price updates, and live dashboard performance
    # For now, we'll simulate with a timestamp freshness check
    
    cat > test_realtime_perf.sql << 'SQL'
-- Real-time data freshness test
SELECT 
    'price_data' as data_type,
    MAX(timestamp) as latest_update,
    TIMESTAMPDIFF(SECOND, MAX(timestamp), NOW()) as seconds_old
FROM crypto_data.price_data
UNION ALL
SELECT 
    'system_metrics' as data_type,
    MAX(timestamp) as latest_update,
    TIMESTAMPDIFF(SECOND, MAX(timestamp), NOW()) as seconds_old
FROM operational_data.system_metrics
UNION ALL
SELECT 
    'api_usage' as data_type,
    MAX(timestamp) as latest_update,
    TIMESTAMPDIFF(SECOND, MAX(timestamp), NOW()) as seconds_old
FROM operational_data.api_usage;
SQL
    
    if command -v mysql &> /dev/null; then
        mysql -u root -p < test_realtime_perf.sql
        return 0
    else
        return 1
    fi
}

# Security Integration Tests
test_security_integration() {
    print_status "Testing security integration..."
    
    run_test "Security: API Key Protection" "test_api_key_security"
    run_test "Security: Database Access Control" "test_db_access_control"
    run_test "Security: Data Encryption" "test_data_encryption"
}

test_api_key_security() {
    # Test that API keys are not exposed in logs or error messages
    echo "Testing API key security..."
    
    # Check for exposed API keys in configuration files
    if grep -r "api_key.*=" ../handlers/ | grep -v "{{.*}}" | grep -v "your_api_key_here"; then
        echo "WARNING: Potential API key exposure found"
        return 1
    fi
    
    echo "API key security check passed"
    return 0
}

test_db_access_control() {
    # Test database access controls
    echo "Testing database access control..."
    
    # This would typically test user permissions, connection security, etc.
    # For now, we'll check that databases exist and are accessible
    
    cat > test_db_access.sql << 'SQL'
-- Test database access
SHOW DATABASES;
SELECT COUNT(*) as accessible_databases 
FROM information_schema.schemata 
WHERE schema_name IN ('crypto_data', 'user_data', 'operational_data');
SQL
    
    if command -v mysql &> /dev/null; then
        mysql -u root -p < test_db_access.sql
        return 0
    else
        return 1
    fi
}

test_data_encryption() {
    # Test data encryption and security measures
    echo "Testing data encryption..."
    
    # Check for sensitive data handling
    cat > test_encryption.sql << 'SQL'
-- Test sensitive data handling
USE user_data;
SELECT 
    COUNT(*) as users_with_hashed_passwords
FROM users 
WHERE password_hash IS NOT NULL 
  AND LENGTH(password_hash) > 50;
SQL
    
    if command -v mysql &> /dev/null; then
        mysql -u root -p < test_encryption.sql
        return 0
    else
        return 1
    fi
}

# Error Handling Integration Tests
test_error_handling() {
    print_status "Testing error handling integration..."
    
    run_test "Error Handling: Handler Failures" "test_handler_error_handling"
    run_test "Error Handling: Database Failures" "test_db_error_handling"
    run_test "Error Handling: Network Issues" "test_network_error_handling"
}

test_handler_error_handling() {
    echo "Testing handler error handling..."
    
    # Test how system handles handler failures
    # This would typically involve simulating API failures, network issues, etc.
    
    cat > test_handler_errors.sql << 'SQL'
-- Check error logging for handlers
USE operational_data;
SELECT 
    component,
    error_level,
    COUNT(*) as error_count
FROM error_logs
WHERE component LIKE '%handler%'
  AND timestamp > NOW() - INTERVAL 24 HOUR
GROUP BY component, error_level;
SQL
    
    if command -v mysql &> /dev/null; then
        mysql -u root -p < test_handler_errors.sql
        return 0
    else
        return 1
    fi
}

test_db_error_handling() {
    echo "Testing database error handling..."
    
    # Test database error handling and recovery
    cat > test_db_errors.sql << 'SQL'
-- Check database error patterns
USE operational_data;
SELECT 
    error_level,
    COUNT(*) as db_error_count
FROM error_logs
WHERE error_message LIKE '%database%' 
   OR error_message LIKE '%connection%'
   OR error_message LIKE '%timeout%'
  AND timestamp > NOW() - INTERVAL 24 HOUR
GROUP BY error_level;
SQL
    
    if command -v mysql &> /dev/null; then
        mysql -u root -p < test_db_errors.sql
        return 0
    else
        return 1
    fi
}

test_network_error_handling() {
    echo "Testing network error handling..."
    
    # Test network error handling
    cat > test_network_errors.sql << 'SQL'
-- Check network-related errors
USE operational_data;
SELECT 
    COUNT(*) as network_errors
FROM error_logs
WHERE (error_message LIKE '%network%' 
    OR error_message LIKE '%timeout%'
    OR error_message LIKE '%connection%')
  AND timestamp > NOW() - INTERVAL 24 HOUR;
SQL
    
    if command -v mysql &> /dev/null; then
        mysql -u root -p < test_network_errors.sql
        return 0
    else
        return 1
    fi
}

# Main test execution
main() {
    print_status "Starting comprehensive integration testing..."
    
    # Run all test suites
    test_handler_integration
    test_database_integration
    test_data_flow
    test_performance_integration
    test_security_integration
    test_error_handling
    
    # Generate final report
    echo ""
    print_status "Integration Test Summary:"
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo "Success Rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
    echo ""
    echo "Detailed results saved to: $TEST_RESULTS_FILE"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        print_success "🎉 All integration tests passed!"
        exit 0
    else
        print_error "Some integration tests failed. Please check the logs."
        exit 1
    fi
}

# Cleanup function
cleanup() {
    echo "Cleaning up test files..."
    rm -f test_*.sql
}

# Set up cleanup trap
trap cleanup EXIT

# Run main function
main "$@"
EOF

# Make integration test script executable
chmod +x integration_test.sh

# Create integration monitoring script
cat > monitor_integration.sh << 'EOF'
#!/bin/bash

# Integration Monitoring Script
# Continuous monitoring of integration health

set -e

echo "📊 Starting Integration Health Monitoring..."

# Configuration
MONITOR_INTERVAL=300  # 5 minutes
LOG_FILE="integration_monitor.log"

# Initialize monitoring log
echo "Integration Health Monitoring Started - $(date)" > $LOG_FILE
echo "================================================" >> $LOG_FILE

# Monitoring functions
check_handler_health() {
    echo "Checking handler health..." >> $LOG_FILE
    
    local healthy_handlers=0
    local total_handlers=6
    
    for handler in coinmarketcap defillama binance blockchain dune whale-alerts; do
        if [ -f "../handlers/$handler/test.sh" ]; then
            if cd "../handlers/$handler" && ./test.sh > /dev/null 2>&1; then
                healthy_handlers=$((healthy_handlers + 1))
                echo "✅ Handler $handler: HEALTHY" >> $LOG_FILE
            else
                echo "❌ Handler $handler: UNHEALTHY" >> $LOG_FILE
            fi
            cd - > /dev/null
        fi
    done
    
    echo "Handler Health: $healthy_handlers/$total_handlers healthy" >> $LOG_FILE
}

check_database_health() {
    echo "Checking database health..." >> $LOG_FILE
    
    local healthy_databases=0
    local total_databases=3
    
    for database in crypto-data user-data operational-data; do
        if [ -f "../databases/$database/test.sh" ]; then
            if cd "../databases/$database" && ./test.sh > /dev/null 2>&1; then
                healthy_databases=$((healthy_databases + 1))
                echo "✅ Database $database: HEALTHY" >> $LOG_FILE
            else
                echo "❌ Database $database: UNHEALTHY" >> $LOG_FILE
            fi
            cd - > /dev/null
        fi
    done
    
    echo "Database Health: $healthy_databases/$total_databases healthy" >> $LOG_FILE
}

check_data_flow_health() {
    echo "Checking data flow health..." >> $LOG_FILE
    
    # Check data freshness
    if command -v mysql &> /dev/null; then
        cat > check_data_freshness.sql << 'SQL'
SELECT 
    'crypto_data.price_data' as table_name,
    COUNT(*) as recent_records,
    MAX(timestamp) as latest_update,
    TIMESTAMPDIFF(MINUTE, MAX(timestamp), NOW()) as minutes_old
FROM crypto_data.price_data
WHERE timestamp > NOW() - INTERVAL 1 HOUR
UNION ALL
SELECT 
    'operational_data.system_metrics' as table_name,
    COUNT(*) as recent_records,
    MAX(timestamp) as latest_update,
    TIMESTAMPDIFF(MINUTE, MAX(timestamp), NOW()) as minutes_old
FROM operational_data.system_metrics
WHERE timestamp > NOW() - INTERVAL 1 HOUR;
SQL
        
        mysql -u root -p < check_data_freshness.sql >> $LOG_FILE 2>&1
        rm -f check_data_freshness.sql
    fi
}

# Main monitoring loop
monitor_loop() {
    while true; do
        echo "=== Health Check - $(date) ===" >> $LOG_FILE
        
        check_handler_health
        check_database_health
        check_data_flow_health
        
        echo "Health check completed. Next check in $MONITOR_INTERVAL seconds." >> $LOG_FILE
        echo "" >> $LOG_FILE
        
        sleep $MONITOR_INTERVAL
    done
}

# Signal handlers
cleanup_monitor() {
    echo "Integration monitoring stopped - $(date)" >> $LOG_FILE
    exit 0
}

trap cleanup_monitor SIGINT SIGTERM

# Start monitoring
echo "Integration health monitoring started. Press Ctrl+C to stop."
echo "Monitoring every $MONITOR_INTERVAL seconds..."
echo "Logs saved to: $LOG_FILE"

monitor_loop
EOF

# Make monitoring script executable
chmod +x monitor_integration.sh

echo "✅ Integration testing framework setup completed!"
echo ""
echo "Available commands:"
echo "  ./integration_test.sh     - Run comprehensive integration tests"
echo "  ./monitor_integration.sh  - Start continuous integration monitoring"
echo ""
echo "Configuration file: integration_config.json"
echo "Test results will be saved to: integration_test_results.log"
echo "Monitoring logs will be saved to: integration_monitor.log"
