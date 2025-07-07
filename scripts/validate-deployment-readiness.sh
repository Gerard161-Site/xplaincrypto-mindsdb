#!/bin/bash

# XplainCrypto MindsDB Deployment Readiness Validation Script
# Validates all prerequisites before supercharged deployment

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SECRETS_DIR="$PROJECT_ROOT/secrets"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Validation results
validation_results=()
critical_issues=0
warnings=0

# Function to add validation result
add_result() {
    local status="$1"
    local component="$2"
    local message="$3"
    local details="$4"
    
    validation_results+=("$status|$component|$message|$details")
    
    if [[ "$status" == "FAIL" ]]; then
        ((critical_issues++))
        error "$component: $message"
        [[ -n "$details" ]] && echo "  Details: $details"
    elif [[ "$status" == "WARN" ]]; then
        ((warnings++))
        warning "$component: $message"
        [[ -n "$details" ]] && echo "  Details: $details"
    else
        success "$component: $message"
    fi
}

# Validate secrets
validate_secrets() {
    log "Validating API secrets..."
    
    required_secrets=(
        "openai_api_key.txt"
        "anthropic_api_key.txt"
        "timegpt_api_key.txt"
        "coinmarketcap_api_key.txt"
        "dune_api_key.txt"
        "coingecko_api_key.txt"
        "postgres_password.txt"
        "redis_password.txt"
    )
    
    if [[ ! -d "$SECRETS_DIR" ]]; then
        add_result "FAIL" "Secrets Directory" "Secrets directory does not exist" "Expected: $SECRETS_DIR"
        return
    fi
    
    missing_secrets=()
    invalid_secrets=()
    
    for secret in "${required_secrets[@]}"; do
        secret_file="$SECRETS_DIR/$secret"
        
        if [[ ! -f "$secret_file" ]]; then
            missing_secrets+=("$secret")
        else
            # Check if secret file is not empty and has reasonable length
            secret_content=$(cat "$secret_file" 2>/dev/null | tr -d '\n\r' | tr -d ' ')
            if [[ ${#secret_content} -lt 10 ]]; then
                invalid_secrets+=("$secret (too short: ${#secret_content} chars)")
            elif [[ "$secret_content" == *"REPLACE_ME"* ]] || [[ "$secret_content" == *"YOUR_KEY"* ]]; then
                invalid_secrets+=("$secret (placeholder value)")
            fi
        fi
    done
    
    if [[ ${#missing_secrets[@]} -gt 0 ]]; then
        add_result "FAIL" "Missing Secrets" "Required secrets not found" "${missing_secrets[*]}"
    fi
    
    if [[ ${#invalid_secrets[@]} -gt 0 ]]; then
        add_result "FAIL" "Invalid Secrets" "Secrets contain invalid values" "${invalid_secrets[*]}"
    fi
    
    if [[ ${#missing_secrets[@]} -eq 0 ]] && [[ ${#invalid_secrets[@]} -eq 0 ]]; then
        add_result "PASS" "Secrets Validation" "All ${#required_secrets[@]} secrets are valid"
    fi
}

# Validate network connectivity
validate_connectivity() {
    log "Validating network connectivity..."
    
    # Test MindsDB connectivity (macOS compatible)
    if curl -s --connect-timeout 10 --max-time 10 http://mindsdb.xplaincrypto.ai:47334 > /dev/null 2>&1; then
        add_result "PASS" "MindsDB Connection" "MindsDB accessible at mindsdb.xplaincrypto.ai:47334"
    else
        add_result "FAIL" "MindsDB Connection" "Cannot connect to MindsDB" "Check network and firewall settings"
    fi
    
    # Test API endpoints
    api_endpoints=(
        "api.coinmarketcap.com"
        "api.anthropic.com"
        "api.openai.com"
    )
    
    failed_apis=()
    for endpoint in "${api_endpoints[@]}"; do
        if curl -s --connect-timeout 5 --max-time 5 "https://$endpoint" > /dev/null 2>&1; then
            # API accessible
            :
        else
            failed_apis+=("$endpoint")
        fi
    done
    
    if [[ ${#failed_apis[@]} -eq 0 ]]; then
        add_result "PASS" "API Connectivity" "All external APIs accessible"
    else
        add_result "WARN" "API Connectivity" "Some APIs not accessible" "${failed_apis[*]}"
    fi
}

# Validate SQL syntax
validate_sql_syntax() {
    log "Validating SQL file syntax..."
    
    sql_directories=(
        "$PROJECT_ROOT/configuration/sql/datasources"
        "$PROJECT_ROOT/configuration/sql/engines"
        "$PROJECT_ROOT/configuration/sql/knowledge_bases"
        "$PROJECT_ROOT/configuration/sql/skills"
        "$PROJECT_ROOT/configuration/sql/agents"
        "$PROJECT_ROOT/configuration/sql/jobs"
    )
    
    syntax_errors=0
    total_files=0
    
    for sql_dir in "${sql_directories[@]}"; do
        if [[ -d "$sql_dir" ]]; then
            for sql_file in "$sql_dir"/*.sql; do
                if [[ -f "$sql_file" ]]; then
                    ((total_files++))
                    
                    # Basic syntax check - look for common issues
                    if grep -q "CREATE\|SELECT\|INSERT\|UPDATE\|DELETE" "$sql_file"; then
                        # File contains SQL commands
                        if grep -q "\${[A-Z_]*}" "$sql_file"; then
                            # Contains variable placeholders - good
                            :
                        fi
                    else
                        ((syntax_errors++))
                        add_result "WARN" "SQL Syntax" "File may be empty or invalid" "$(basename "$sql_file")"
                    fi
                fi
            done
        fi
    done
    
    if [[ $syntax_errors -eq 0 ]]; then
        add_result "PASS" "SQL Validation" "$total_files SQL files passed basic validation"
    else
        add_result "WARN" "SQL Validation" "$syntax_errors/$total_files files have potential issues"
    fi
}

# Validate project structure
validate_project_structure() {
    log "Validating project structure..."
    
    required_dirs=(
        "configuration/sql/datasources"
        "configuration/sql/engines"
        "configuration/sql/knowledge_bases"
        "configuration/sql/skills"
        "configuration/sql/agents"
        "configuration/sql/jobs"
        "configuration/tests"
        "configuration/workflows"
        "scripts"
    )
    
    missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$PROJECT_ROOT/$dir" ]]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -eq 0 ]]; then
        add_result "PASS" "Project Structure" "All required directories present"
    else
        add_result "WARN" "Project Structure" "Some directories missing" "${missing_dirs[*]}"
    fi
    
    # Check for key files
    key_files=(
        "configuration/tests/run_comprehensive_tests.py"
        "scripts/deploy-supercharged-mindsdb.sh"
        "docker-compose.yml"
    )
    
    missing_files=()
    
    for file in "${key_files[@]}"; do
        if [[ ! -f "$PROJECT_ROOT/$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        add_result "PASS" "Key Files" "All deployment files present"
    else
        add_result "WARN" "Key Files" "Some files missing" "${missing_files[*]}"
    fi
}

# Validate system resources
validate_system_resources() {
    log "Validating system resources..."
    
    # Check disk space (macOS compatible)
    if command -v df >/dev/null 2>&1; then
        # macOS df doesn't support -BG, use different approach
        available_space_kb=$(df "$PROJECT_ROOT" | awk 'NR==2 {print $4}')
        available_space_gb=$((available_space_kb / 1024 / 1024))
        
        if [[ $available_space_gb -gt 5 ]]; then
            add_result "PASS" "Disk Space" "${available_space_gb}GB available"
        else
            add_result "WARN" "Disk Space" "Low disk space: ${available_space_gb}GB" "Minimum 5GB recommended"
        fi
    else
        add_result "WARN" "Disk Space" "Cannot check disk space" "df command not available"
    fi
    
    # Check if Python 3 is available
    if command -v python3 &> /dev/null; then
        python_version=$(python3 --version 2>&1)
        add_result "PASS" "Python 3" "$python_version available"
    else
        add_result "WARN" "Python 3" "Python 3 not found" "Required for test framework"
    fi
    
    # Check if mysql client is available
    if command -v mysql &> /dev/null; then
        mysql_version=$(mysql --version 2>&1)
        add_result "PASS" "MySQL Client" "MySQL client available"
    else
        add_result "WARN" "MySQL Client" "MySQL client not found" "Required for deployment"
    fi
}

# Validate configuration files
validate_configuration() {
    log "Validating configuration files..."
    
    # Check test config
    test_config="$PROJECT_ROOT/configuration/tests/test_config.yaml"
    if [[ -f "$test_config" ]]; then
        add_result "PASS" "Test Configuration" "Test config file present"
    else
        add_result "WARN" "Test Configuration" "Test config missing" "May affect comprehensive testing"
    fi
    
    # Check Docker Compose
    docker_compose="$PROJECT_ROOT/docker-compose.yml"
    if [[ -f "$docker_compose" ]]; then
        if grep -q "mindsdb" "$docker_compose"; then
            add_result "PASS" "Docker Configuration" "Docker Compose configured for MindsDB"
        else
            add_result "WARN" "Docker Configuration" "Docker Compose may not include MindsDB"
        fi
    else
        add_result "WARN" "Docker Configuration" "Docker Compose file missing"
    fi
}

# Generate deployment readiness report
generate_report() {
    log "Generating deployment readiness report..."
    
    echo ""
    echo "======================================"
    echo "🚀 DEPLOYMENT READINESS REPORT"
    echo "======================================"
    echo ""
    
    # Summary
    total_checks=${#validation_results[@]}
    passed_checks=$((total_checks - critical_issues - warnings))
    
    echo "📊 SUMMARY:"
    echo "  Total Checks: $total_checks"
    echo "  ✅ Passed: $passed_checks"
    echo "  ⚠️  Warnings: $warnings"
    echo "  ❌ Critical Issues: $critical_issues"
    echo ""
    
    # Detailed results
    echo "📋 DETAILED RESULTS:"
    echo ""
    for result in "${validation_results[@]}"; do
        IFS='|' read -r status component message details <<< "$result"
        
        case $status in
            "PASS")
                echo "✅ $component: $message"
                ;;
            "WARN")
                echo "⚠️  $component: $message"
                [[ -n "$details" ]] && echo "   └─ $details"
                ;;
            "FAIL")
                echo "❌ $component: $message"
                [[ -n "$details" ]] && echo "   └─ $details"
                ;;
        esac
    done
    
    echo ""
    echo "======================================"
    
    # Deployment recommendation
    if [[ $critical_issues -eq 0 ]]; then
        echo "🟢 DEPLOYMENT STATUS: READY"
        echo ""
        echo "✅ No critical issues found. Deployment can proceed."
        if [[ $warnings -gt 0 ]]; then
            echo "⚠️  Note: $warnings warnings should be reviewed but don't block deployment."
        fi
        echo ""
        echo "🚀 To start deployment:"
        echo "   ./scripts/deploy-supercharged-mindsdb.sh"
        echo ""
        return 0
    else
        echo "🔴 DEPLOYMENT STATUS: NOT READY"
        echo ""
        echo "❌ $critical_issues critical issues must be resolved before deployment."
        echo ""
        echo "🔧 Required actions:"
        for result in "${validation_results[@]}"; do
            IFS='|' read -r status component message details <<< "$result"
            if [[ "$status" == "FAIL" ]]; then
                echo "   • Fix $component: $message"
            fi
        done
        echo ""
        echo "📖 For help, see: ./configuration/troubleshooting/"
        echo ""
        return 1
    fi
}

# Main execution
main() {
    echo "🔍 XplainCrypto MindsDB Deployment Readiness Validation"
    echo "======================================================="
    echo ""
    
    # Run all validations
    validate_secrets
    validate_connectivity
    validate_sql_syntax
    validate_project_structure
    validate_system_resources
    validate_configuration
    
    # Generate report
    generate_report
}

# Execute main function
main "$@" 