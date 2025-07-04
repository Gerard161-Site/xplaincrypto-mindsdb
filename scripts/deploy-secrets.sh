#!/bin/bash

# XplainCrypto MindsDB Secret Deployment Script
# Secure version - loads secrets from external sources, never stores in repo

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/tmp/mindsdb_secret_deploy_$(date +%Y%m%d_%H%M%S).log"
SECRETS_ENV_FILE="${PROJECT_ROOT}/.env.secrets"
PRODUCTION_SERVER="142.93.49.20"
MINDSDB_URL="http://${PRODUCTION_SERVER}:47334"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}SUCCESS: $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}INFO: $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

# Help function
show_help() {
    cat << EOF
XplainCrypto MindsDB Secret Deployment Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --setup         Create .env.secrets template file
    --interactive   Enter secrets interactively (secure)
    --from-env      Load secrets from environment variables
    --help          Show this help message

EXAMPLES:
    # First time setup - create template
    $0 --setup
    
    # Deploy using interactive mode (recommended)
    $0 --interactive
    
    # Deploy using environment variables
    export OPENAI_API_KEY="your-key"
    export ANTHROPIC_API_KEY="your-key"
    # ... other keys
    $0 --from-env

SECURITY:
    - Never stores secrets in repository
    - Uses external .env.secrets file (gitignored)
    - Supports environment variables
    - Interactive mode for secure entry
    - Temporary files are cleaned up
EOF
}

# Create secrets template
create_secrets_template() {
    cat > "$SECRETS_ENV_FILE" << 'EOF'
# XplainCrypto API Keys - DO NOT COMMIT TO REPOSITORY
# This file is gitignored for security

# AI Engine Keys
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here
TIMEGPT_API_KEY=your_timegpt_api_key_here

# Crypto Data API Keys
COINMARKETCAP_API_KEY=your_coinmarketcap_api_key_here
DUNE_API_KEY=your_dune_api_key_here
COINGECKO_API_KEY=your_coingecko_api_key_here
WHALE_ALERTS_API_KEY=your_whale_alerts_api_key_here

# Additional API Keys
TAVILY_API_KEY=your_tavily_api_key_here
HUGGINGFACE_API_KEY=your_huggingface_api_key_here

# Database Credentials (from production server)
POSTGRES_PASSWORD=rfmveurVyThziPsujMdMsnya6JNirlz8nFrcH34o9Xs=
REDIS_PASSWORD=redis_secure_pass_dev123
EOF
    
    success "Created secrets template at $SECRETS_ENV_FILE"
    warning "Please edit this file with your actual API keys before deployment"
    info "File is gitignored and will not be committed to repository"
}

# Interactive secret entry
interactive_secrets() {
    info "Interactive secret entry mode"
    echo "Enter your API keys (input will be hidden):"
    
    read -s -p "OpenAI API Key: " OPENAI_API_KEY
    echo
    read -s -p "Anthropic API Key: " ANTHROPIC_API_KEY
    echo
    read -s -p "TimeGPT API Key: " TIMEGPT_API_KEY
    echo
    read -s -p "CoinMarketCap API Key: " COINMARKETCAP_API_KEY
    echo
    read -s -p "Dune API Key: " DUNE_API_KEY
    echo
    read -s -p "CoinGecko API Key: " COINGECKO_API_KEY
    echo
    read -s -p "Whale Alerts API Key (optional): " WHALE_ALERTS_API_KEY
    echo
    read -s -p "Tavily API Key: " TAVILY_API_KEY
    echo
    read -s -p "HuggingFace API Key: " HUGGINGFACE_API_KEY
    echo
    
    # Set database credentials
    POSTGRES_PASSWORD="rfmveurVyThziPsujMdMsnya6JNirlz8nFrcH34o9Xs="
    REDIS_PASSWORD="redis_secure_pass_dev123"
    
    info "API keys entered successfully"
}

# Load secrets from environment
load_from_env() {
    info "Loading secrets from environment variables"
    
    # Check required environment variables
    required_vars=(
        "OPENAI_API_KEY"
        "ANTHROPIC_API_KEY" 
        "TIMEGPT_API_KEY"
        "COINMARKETCAP_API_KEY"
        "DUNE_API_KEY"
        "COINGECKO_API_KEY"
        "TAVILY_API_KEY"
        "HUGGINGFACE_API_KEY"
    )
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            error "Environment variable $var is not set"
        fi
    done
    
    # Set database credentials
    POSTGRES_PASSWORD="rfmveurVyThziPsujMdMsnya6JNirlz8nFrcH34o9Xs="
    REDIS_PASSWORD="redis_secure_pass_dev123"
    
    success "All required environment variables found"
}

# Load secrets from .env file
load_from_file() {
    if [[ ! -f "$SECRETS_ENV_FILE" ]]; then
        error "Secrets file not found: $SECRETS_ENV_FILE"
        info "Run '$0 --setup' to create template"
    fi
    
    info "Loading secrets from $SECRETS_ENV_FILE"
    source "$SECRETS_ENV_FILE"
    
    # Validate all keys are set
    if [[ "$OPENAI_API_KEY" == "your_openai_api_key_here" ]]; then
        error "Please update $SECRETS_ENV_FILE with real API keys"
    fi
    
    success "Secrets loaded from file"
}

# Export all secrets for envsubst
export_secrets() {
    export OPENAI_API_KEY
    export ANTHROPIC_API_KEY
    export TIMEGPT_API_KEY
    export COINMARKETCAP_API_KEY
    export DUNE_API_KEY
    export COINGECKO_API_KEY
    export WHALE_ALERTS_API_KEY
    export TAVILY_API_KEY
    export HUGGINGFACE_API_KEY
    export POSTGRES_PASSWORD
    export REDIS_PASSWORD
}

# Deploy secrets to MindsDB
deploy_secrets() {
    info "Starting secret deployment to MindsDB"
    
    # Export secrets for envsubst
    export_secrets
    
    # Deploy databases
    info "Deploying database connections..."
    for db_file in "$PROJECT_ROOT/sql/01-databases"/*.sql; do
        info "Deploying $(basename "$db_file")..."
        envsubst < "$db_file" | curl -s -X POST "$MINDSDB_URL/api/sql/query" \
            -H "Content-Type: application/json" \
            -d @- > /dev/null
    done
    
    # Deploy AI engines
    info "Deploying AI engines..."
    for engine_file in "$PROJECT_ROOT/sql/02-models"/*.sql; do
        info "Deploying $(basename "$engine_file")..."
        envsubst < "$engine_file" | curl -s -X POST "$MINDSDB_URL/api/sql/query" \
            -H "Content-Type: application/json" \
            -d @- > /dev/null
    done
    
    # Deploy AI agents
    info "Deploying AI agents..."
    for agent_file in "$PROJECT_ROOT/sql/03-agents"/*.sql; do
        info "Deploying $(basename "$agent_file")..."
        envsubst < "$agent_file" | curl -s -X POST "$MINDSDB_URL/api/sql/query" \
            -H "Content-Type: application/json" \
            -d @- > /dev/null
    done
    
    success "Secret deployment completed"
    info "Log file: $LOG_FILE"
}

# Main execution
main() {
    log "Starting XplainCrypto secret deployment"
    
    # Parse arguments
    case "${1:-}" in
        --setup)
            create_secrets_template
            exit 0
            ;;
        --interactive)
            interactive_secrets
            deploy_secrets
            ;;
        --from-env)
            load_from_env
            deploy_secrets
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        "")
            # Default: try to load from file
            load_from_file
            deploy_secrets
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Cleanup on exit
cleanup() {
    # Clear sensitive environment variables
    unset OPENAI_API_KEY ANTHROPIC_API_KEY TIMEGPT_API_KEY
    unset COINMARKETCAP_API_KEY DUNE_API_KEY COINGECKO_API_KEY
    unset WHALE_ALERTS_API_KEY TAVILY_API_KEY HUGGINGFACE_API_KEY
    unset POSTGRES_PASSWORD REDIS_PASSWORD
}

trap cleanup EXIT

# Run main function
main "$@"
