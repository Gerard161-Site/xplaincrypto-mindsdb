
#!/bin/bash

# XplainCrypto MindsDB Master Setup Script
# Executes all component setups in logical order

set -e

echo "🚀 Starting XplainCrypto MindsDB Master Setup..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v mindsdb &> /dev/null; then
        print_error "MindsDB not found. Please install MindsDB first."
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 not found. Please install Python3."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Setup components in logical order
setup_component() {
    local component_path=$1
    local component_name=$2
    
    print_status "Setting up $component_name..."
    
    if [ -f "$component_path/setup.sh" ]; then
        cd "$component_path"
        chmod +x setup.sh
        ./setup.sh
        cd - > /dev/null
        print_success "$component_name setup completed"
    else
        print_warning "Setup script not found for $component_name"
    fi
}

# Main setup sequence
main() {
    local repo_root=$(pwd)
    
    check_prerequisites
    
    # 1. Handlers (Data Sources)
    print_status "Phase 1: Setting up Data Handlers..."
    for handler in coinmarketcap defillama binance blockchain dune whale-alerts; do
        setup_component "$repo_root/handlers/$handler" "Handler: $handler"
    done
    
    # 2. Databases
    print_status "Phase 2: Setting up Databases..."
    for db in crypto-data user-data operational-data; do
        setup_component "$repo_root/databases/$db" "Database: $db"
    done
    
    # 3. Jobs
    print_status "Phase 3: Setting up Jobs..."
    for job in sync-jobs automation; do
        setup_component "$repo_root/jobs/$job" "Job: $job"
    done
    
    # 4. Skills
    print_status "Phase 4: Setting up Skills..."
    for skill in market-analysis risk-assessment portfolio-optimization sentiment-analysis; do
        setup_component "$repo_root/skills/$skill" "Skill: $skill"
    done
    
    # 5. Engines
    print_status "Phase 5: Setting up ML Engines..."
    for engine in openai anthropic timegpt; do
        setup_component "$repo_root/engines/$engine" "Engine: $engine"
    done
    
    # 6. Models
    print_status "Phase 6: Setting up AI Models..."
    for model in price-predictor sentiment-analyzer risk-assessor portfolio-optimizer market-summarizer trend-detector anomaly-detector recommendation-engine; do
        setup_component "$repo_root/models/$model" "Model: $model"
    done
    
    # 7. Agents
    print_status "Phase 7: Setting up AI Agents..."
    for agent in crypto-analyst portfolio-manager; do
        setup_component "$repo_root/agents/$agent" "Agent: $agent"
    done
    
    # 8. Knowledge Bases
    print_status "Phase 8: Setting up Knowledge Bases..."
    for kb in crypto-fundamentals market-data trading-strategies regulatory-info; do
        setup_component "$repo_root/knowledge-bases/$kb" "Knowledge Base: $kb"
    done
    
    print_success "🎉 XplainCrypto MindsDB setup completed successfully!"
    print_status "Run './scripts/master-test.sh' to validate the installation"
}

main "$@"
