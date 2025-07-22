
#!/bin/bash

# XplainCrypto MindsDB Master Test Script
# Runs all component tests and integration tests

set -e

echo "🧪 Starting XplainCrypto MindsDB Master Test Suite..."

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

# Test component function
test_component() {
    local component_path=$1
    local component_name=$2
    
    print_status "Testing $component_name..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ -f "$component_path/test.sh" ]; then
        cd "$component_path"
        chmod +x test.sh
        if ./test.sh; then
            print_success "$component_name tests passed"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            print_error "$component_name tests failed"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
        cd - > /dev/null
    else
        print_warning "Test script not found for $component_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Integration tests
run_integration_tests() {
    print_status "Running integration tests..."
    
    if [ -f "./integration/test.sh" ]; then
        cd integration
        chmod +x test.sh
        if ./test.sh; then
            print_success "Integration tests passed"
        else
            print_error "Integration tests failed"
        fi
        cd - > /dev/null
    else
        print_warning "Integration tests not found"
    fi
}

# Main test sequence
main() {
    local repo_root=$(pwd)
    
    # Test all components in order
    print_status "Phase 1: Testing Data Handlers..."
    for handler in coinmarketcap defillama binance blockchain dune whale-alerts; do
        test_component "$repo_root/handlers/$handler" "Handler: $handler"
    done
    
    print_status "Phase 2: Testing Databases..."
    for db in crypto-data user-data operational-data; do
        test_component "$repo_root/databases/$db" "Database: $db"
    done
    
    print_status "Phase 3: Testing Jobs..."
    for job in sync-jobs automation; do
        test_component "$repo_root/jobs/$job" "Job: $job"
    done
    
    print_status "Phase 4: Testing Skills..."
    for skill in market-analysis risk-assessment portfolio-optimization sentiment-analysis; do
        test_component "$repo_root/skills/$skill" "Skill: $skill"
    done
    
    print_status "Phase 5: Testing ML Engines..."
    for engine in openai anthropic timegpt; do
        test_component "$repo_root/engines/$engine" "Engine: $engine"
    done
    
    print_status "Phase 6: Testing AI Models..."
    for model in price-predictor sentiment-analyzer risk-assessor portfolio-optimizer market-summarizer trend-detector anomaly-detector recommendation-engine; do
        test_component "$repo_root/models/$model" "Model: $model"
    done
    
    print_status "Phase 7: Testing AI Agents..."
    for agent in crypto-analyst portfolio-manager; do
        test_component "$repo_root/agents/$agent" "Agent: $agent"
    done
    
    print_status "Phase 8: Testing Knowledge Bases..."
    for kb in crypto-fundamentals market-data trading-strategies regulatory-info; do
        test_component "$repo_root/knowledge-bases/$kb" "Knowledge Base: $kb"
    done
    
    # Run integration tests
    run_integration_tests
    
    # Print summary
    echo ""
    print_status "Test Summary:"
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        print_success "🎉 All tests passed!"
        exit 0
    else
        print_error "Some tests failed. Please check the logs above."
        exit 1
    fi
}

main "$@"
