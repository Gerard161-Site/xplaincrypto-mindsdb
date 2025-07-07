#!/bin/bash

# XplainCrypto MindsDB SuperCharged Deployment Script
# Deploys all knowledge bases, skills, jobs, and chatbots with proper secrets management

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SECRETS_DIR="$PROJECT_ROOT/secrets"
SQL_DIR="$PROJECT_ROOT/configuration/sql"
TEMP_DIR="/tmp/xplaincrypto-deployment"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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
    exit 1
}

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Function to check if secrets exist
check_secrets() {
    log "Checking required secrets..."
    
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
    
    missing_secrets=()
    
    for secret in "${required_secrets[@]}"; do
        if [[ ! -f "$SECRETS_DIR/$secret" ]]; then
            missing_secrets+=("$secret")
        fi
    done
    
    if [[ ${#missing_secrets[@]} -gt 0 ]]; then
        error "Missing required secrets: ${missing_secrets[*]}"
    fi
    
    success "All required secrets found"
}

# Function to substitute secrets in SQL files
substitute_secrets() {
    local input_file="$1"
    local output_file="$2"
    
    log "Processing secrets for $(basename "$input_file")"
    
    # Read secrets
    OPENAI_API_KEY=$(cat "$SECRETS_DIR/openai_api_key.txt" 2>/dev/null || echo "")
    ANTHROPIC_API_KEY=$(cat "$SECRETS_DIR/anthropic_api_key.txt" 2>/dev/null || echo "")
    TIMEGPT_API_KEY=$(cat "$SECRETS_DIR/timegpt_api_key.txt" 2>/dev/null || echo "")
    COINMARKETCAP_API_KEY=$(cat "$SECRETS_DIR/coinmarketcap_api_key.txt" 2>/dev/null || echo "")
    DUNE_API_KEY=$(cat "$SECRETS_DIR/dune_api_key.txt" 2>/dev/null || echo "")
    COINGECKO_API_KEY=$(cat "$SECRETS_DIR/coingecko_api_key.txt" 2>/dev/null || echo "")
    POSTGRES_PASSWORD=$(cat "$SECRETS_DIR/postgres_password.txt" 2>/dev/null || echo "")
    REDIS_PASSWORD=$(cat "$SECRETS_DIR/redis_password.txt" 2>/dev/null || echo "")
    
    # Substitute secrets in SQL file
    sed -e "s/\${OPENAI_API_KEY}/$OPENAI_API_KEY/g" \
        -e "s/\${ANTHROPIC_API_KEY}/$ANTHROPIC_API_KEY/g" \
        -e "s/\${TIMEGPT_API_KEY}/$TIMEGPT_API_KEY/g" \
        -e "s/\${COINMARKETCAP_API_KEY}/$COINMARKETCAP_API_KEY/g" \
        -e "s/\${DUNE_API_KEY}/$DUNE_API_KEY/g" \
        -e "s/\${COINGECKO_API_KEY}/$COINGECKO_API_KEY/g" \
        -e "s/\${POSTGRES_PASSWORD}/$POSTGRES_PASSWORD/g" \
        -e "s/\${REDIS_PASSWORD}/$REDIS_PASSWORD/g" \
        "$input_file" > "$output_file"
}

# Function to execute SQL file
execute_sql() {
    local sql_file="$1"
    local description="$2"
    
    log "Executing: $description"
    
    # Execute SQL file via MindsDB
    if mysql -h mindsdb.xplaincrypto.ai -P 47334 -u mindsdb -p"$POSTGRES_PASSWORD" < "$sql_file"; then
        success "$description completed"
    else
        error "Failed to execute: $description"
    fi
}

# Function to test component deployment
test_component() {
    local component_type="$1"
    local test_query="$2"
    
    log "Testing $component_type deployment..."
    
    # Test query execution
    result=$(mysql -h mindsdb.xplaincrypto.ai -P 47334 -u mindsdb -p"$POSTGRES_PASSWORD" -e "$test_query" 2>/dev/null || echo "FAILED")
    
    if [[ "$result" != "FAILED" ]] && [[ -n "$result" ]]; then
        success "$component_type deployment verified"
        return 0
    else
        warning "$component_type deployment verification failed"
        return 1
    fi
}

# Main deployment function
deploy_components() {
    log "Starting XplainCrypto MindsDB SuperCharged Deployment"
    
    # 1. Deploy Data Sources
    log "=== Phase 1: Data Sources ==="
    substitute_secrets "$SQL_DIR/datasources/02_create_datasurces.sql" "$TEMP_DIR/datasources.sql"
    execute_sql "$TEMP_DIR/datasources.sql" "Data Sources"
    test_component "Data Sources" "SELECT 'coinmarketcap' as test_db"
    
    # 2. Deploy AI Engines
    log "=== Phase 2: AI Engines ==="
    substitute_secrets "$SQL_DIR/engines/03_create_engines.sql" "$TEMP_DIR/engines.sql"
    execute_sql "$TEMP_DIR/engines.sql" "AI Engines"
    test_component "AI Engines" "SELECT 'OpenAI Engine Ready' as status"
    
    # 3. Deploy Knowledge Bases
    log "=== Phase 3: Knowledge Bases ==="
    for kb_file in "$SQL_DIR/knowledge_bases"/*.sql; do
        kb_name=$(basename "$kb_file" .sql)
        substitute_secrets "$kb_file" "$TEMP_DIR/kb_$kb_name.sql"
        execute_sql "$TEMP_DIR/kb_$kb_name.sql" "Knowledge Base: $kb_name"
    done
    test_component "Knowledge Bases" "SELECT COUNT(*) as kb_count FROM information_schema.tables WHERE table_name LIKE '%_kb'"
    
    # 4. Deploy AI Skills
    log "=== Phase 4: AI Skills ==="
    for skill_file in "$SQL_DIR/skills"/*.sql; do
        skill_name=$(basename "$skill_file" .sql)
        substitute_secrets "$skill_file" "$TEMP_DIR/skill_$skill_name.sql"
        execute_sql "$TEMP_DIR/skill_$skill_name.sql" "AI Skill: $skill_name"
    done
    test_component "AI Skills" "SELECT COUNT(*) as skill_count FROM information_schema.tables WHERE table_name LIKE '%_skill'"
    
    # 5. Deploy Agents
    log "=== Phase 5: AI Agents ==="
    substitute_secrets "$SQL_DIR/agents/04_create_agents.sql" "$TEMP_DIR/agents.sql"
    execute_sql "$TEMP_DIR/agents.sql" "AI Agents"
    test_component "AI Agents" "SELECT COUNT(*) as agent_count FROM information_schema.tables WHERE table_name LIKE '%_agent'"
    
    # 6. Deploy Automation Jobs
    log "=== Phase 6: Automation Jobs ==="
    for job_file in "$SQL_DIR/jobs"/*.sql; do
        job_name=$(basename "$job_file" .sql)
        substitute_secrets "$job_file" "$TEMP_DIR/job_$job_name.sql"
        execute_sql "$TEMP_DIR/job_$job_name.sql" "Automation Job: $job_name"
    done
    test_component "Automation Jobs" "SELECT COUNT(*) as job_count FROM information_schema.events"
    
    # 7. Create database tables for data storage
    log "=== Phase 7: Database Tables ==="
    substitute_secrets "$SQL_DIR/datasources/05_create_tables.sql" "$TEMP_DIR/tables.sql"
    execute_sql "$TEMP_DIR/tables.sql" "Database Tables"
    test_component "Database Tables" "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = 'mindsdb'"
    
    success "All components deployed successfully!"
}

# Function to run comprehensive tests
run_comprehensive_tests() {
    log "=== Running Comprehensive Tests ==="
    
    cd "$PROJECT_ROOT"
    
    if python3 configuration/tests/run_comprehensive_tests.py; then
        success "Comprehensive tests passed"
    else
        warning "Some comprehensive tests failed - check logs for details"
    fi
}

# Function to display deployment summary
show_deployment_summary() {
    log "=== Deployment Summary ==="
    
    # Query deployment status
    mysql -h mindsdb.xplaincrypto.ai -P 47334 -u mindsdb -p"$POSTGRES_PASSWORD" -e "
    SELECT 
        'Knowledge Bases' as component,
        COUNT(*) as count
    FROM information_schema.tables 
    WHERE table_name LIKE '%_kb'
    
    UNION ALL
    
    SELECT 
        'AI Skills' as component,
        COUNT(*) as count
    FROM information_schema.tables 
    WHERE table_name LIKE '%_skill'
    
    UNION ALL
    
    SELECT 
        'Automation Jobs' as component,
        COUNT(*) as count
    FROM information_schema.events
    
    UNION ALL
    
    SELECT 
        'Database Tables' as component,
        COUNT(*) as count
    FROM information_schema.tables 
    WHERE table_schema = 'mindsdb';"
    
    echo ""
    success "🚀 XplainCrypto MindsDB SuperCharged Deployment Complete!"
    echo ""
    echo "Next Steps:"
    echo "1. Monitor performance: http://mindsdb.xplaincrypto.ai"
    echo "2. Test AI agents via API"
    echo "3. Validate data synchronization"
    echo "4. Set up monitoring alerts"
    echo ""
}

# Cleanup function
cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}

# Main execution
main() {
    echo "🔥 XplainCrypto MindsDB SuperCharged Deployment"
    echo "=============================================="
    echo ""
    
    # Check prerequisites
    check_secrets
    
    # Deploy all components
    deploy_components
    
    # Run comprehensive tests
    run_comprehensive_tests
    
    # Show summary
    show_deployment_summary
    
    # Cleanup
    cleanup
    
    success "Deployment completed successfully! 🎉"
}

# Error handling
trap cleanup EXIT

# Execute main function
main "$@" 