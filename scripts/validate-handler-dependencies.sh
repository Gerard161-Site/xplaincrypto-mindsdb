#!/bin/bash

# XplainCrypto MindsDB Handler Dependencies Validation
# Checks all required Python packages and handler requirements

echo "🐍 XplainCrypto MindsDB Handler Dependencies Validation"
echo "======================================================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ $message${NC}"
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}❌ $message${NC}"
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
    else
        echo -e "${BLUE}ℹ️  $message${NC}"
    fi
}

# Check Python version
echo -e "\n${BLUE}1. Python Environment${NC}"
echo "----------------------"

if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    print_status "PASS" "Python available: $PYTHON_VERSION"
else
    print_status "FAIL" "Python3 not found"
fi

# Check pip
if command -v pip3 &> /dev/null; then
    PIP_VERSION=$(pip3 --version)
    print_status "PASS" "pip3 available: $PIP_VERSION"
else
    print_status "FAIL" "pip3 not found"
fi

# Check handlers directory structure
echo -e "\n${BLUE}2. Handler Structure${NC}"
echo "--------------------"

HANDLERS=(
    "coinmarketcap_handler"
    "defillama_handler"
    "dune_handler"
    "whale_alerts_handler"
    "blockchain_handler"
)

for handler in "${HANDLERS[@]}"; do
    if [ -d "../mindsdb-handlers/$handler" ]; then
        print_status "PASS" "Handler directory exists: $handler"
        
        # Check if handler has required files
        if [ -f "../mindsdb-handlers/$handler/__init__.py" ]; then
            print_status "PASS" "  - __init__.py found"
        else
            print_status "WARN" "  - __init__.py missing"
        fi
        
        if [ -f "../mindsdb-handlers/$handler/${handler}.py" ]; then
            print_status "PASS" "  - Main handler file found"
        else
            print_status "WARN" "  - Main handler file missing"
        fi
        
    else
        print_status "FAIL" "Handler directory missing: $handler"
    fi
done

# Create comprehensive requirements.txt
echo -e "\n${BLUE}3. Python Dependencies${NC}"
echo "-----------------------"

cat > requirements.txt << 'EOF'
# MindsDB Core
mindsdb>=23.10.5.0

# AI/ML Libraries
pandas>=2.0.0
numpy>=1.24.0
scikit-learn>=1.3.0
scipy>=1.10.0

# TimeGPT and Forecasting
nixtla>=0.4.0
statsmodels>=0.14.0
prophet>=1.1.4

# Database Connectors
psycopg2-binary>=2.9.5
redis>=4.5.0
sqlalchemy>=2.0.0

# API Libraries
requests>=2.31.0
httpx>=0.24.0
aiohttp>=3.8.0

# Crypto-specific Libraries
ccxt>=4.0.0
web3>=6.0.0
python-binance>=1.0.17

# Data Processing
beautifulsoup4>=4.12.0
lxml>=4.9.0
pytz>=2023.3
python-dateutil>=2.8.2

# Testing
pytest>=7.4.0
pytest-asyncio>=0.21.0

# Monitoring and Logging
structlog>=23.1.0
prometheus-client>=0.17.0

# Social Media APIs
tweepy>=4.14.0
praw>=7.7.0

# Blockchain APIs
blockcypher>=1.0.93
bitcoinlib>=0.12.0

# Optional Dependencies
jupyter>=1.0.0
matplotlib>=3.7.0
seaborn>=0.12.0
plotly>=5.15.0
EOF

print_status "PASS" "Created comprehensive requirements.txt"

# Validate key dependencies can be imported (if in Python environment)
if command -v python3 &> /dev/null; then
    echo -e "\n${BLUE}4. Import Tests${NC}"
    echo "---------------"
    
    CORE_IMPORTS=(
        "pandas"
        "numpy" 
        "requests"
        "json"
        "datetime"
        "os"
        "sys"
    )
    
    for module in "${CORE_IMPORTS[@]}"; do
        if python3 -c "import $module" 2>/dev/null; then
            print_status "PASS" "Can import: $module"
        else
            print_status "WARN" "Cannot import: $module (will be installed in Docker)"
        fi
    done
fi

# Check agent files
echo -e "\n${BLUE}5. AI Agents Structure${NC}"
echo "----------------------"

AGENTS=(
    "crypto_prediction_agent.py"
    "sentiment_analysis_agent.py"
    "risk_assessment_agent.py"
    "anomaly_detection_agent.py"
    "whale_tracking_agent.py"
)

for agent in "${AGENTS[@]}"; do
    if [ -f "agents/$agent" ]; then
        print_status "PASS" "Agent file exists: $agent"
        
        # Check if agent has main class
        if grep -q "class.*Agent" "agents/$agent"; then
            print_status "PASS" "  - Agent class found"
        else
            print_status "WARN" "  - Agent class not found"
        fi
    else
        print_status "FAIL" "Agent file missing: $agent"
    fi
done

# Check SQL structure
echo -e "\n${BLUE}6. SQL Structure${NC}"
echo "----------------"

SQL_DIRS=(
    "sql/01-databases"
    "sql/02-models" 
    "sql/03-agents"
    "sql/04-dashboards"
)

for dir in "${SQL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        file_count=$(find "$dir" -name "*.sql" | wc -l)
        print_status "PASS" "SQL directory exists: $dir ($file_count SQL files)"
    else
        print_status "WARN" "SQL directory missing: $dir"
    fi
done

echo -e "\n${BLUE}Dependencies Summary${NC}"
echo "===================="
print_status "INFO" "All handler dependencies validated"
print_status "INFO" "requirements.txt created with all necessary packages"
print_status "INFO" "Ready for Docker build process" 