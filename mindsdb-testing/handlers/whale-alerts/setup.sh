
#!/bin/bash

# Whale Alert Handler Setup Script
# Sets up Whale Alert data integration for large transaction monitoring

set -e

echo "🐋 Setting up Whale Alert Handler..."

# Configuration
HANDLER_NAME="whale_alert_handler"
API_BASE_URL="https://api.whale-alert.io"

# Create handler SQL
cat > create_handler.sql << 'EOF'
-- Create Whale Alert Handler
CREATE OR REPLACE DATABASE whale_alert_db
WITH ENGINE = 'http',
PARAMETERS = {
    "base_url": "https://api.whale-alert.io/v1",
    "headers": {
        "X-WA-API-KEY": "{{WHALE_ALERT_API_KEY}}",
        "Content-Type": "application/json"
    },
    "timeout": 30
};
EOF

# Create tables SQL
cat > create_tables.sql << 'EOF'
-- Whale Alert Tables

-- Large transactions
CREATE OR REPLACE VIEW whale_alert_db.transactions AS (
    SELECT * FROM whale_alert_db.transactions
);

-- Transaction status
CREATE OR REPLACE VIEW whale_alert_db.status AS (
    SELECT * FROM whale_alert_db.status
);

-- Supported blockchains
CREATE OR REPLACE VIEW whale_alert_db.blockchains AS (
    SELECT * FROM whale_alert_db.blockchains
);
EOF

# Execute setup
execute_setup() {
    echo "Creating Whale Alert handler..."
    
    # Check if API key is set
    if [ -z "$WHALE_ALERT_API_KEY" ]; then
        echo "⚠️  Warning: WHALE_ALERT_API_KEY environment variable not set"
        echo "Please set your Whale Alert API key:"
        echo "export WHALE_ALERT_API_KEY='your_api_key_here'"
    fi
    
    # Replace API key placeholder
    sed "s/{{WHALE_ALERT_API_KEY}}/$WHALE_ALERT_API_KEY/g" create_handler.sql > create_handler_final.sql
    
    # Execute SQL commands
    if command -v mindsdb &> /dev/null; then
        mindsdb -f create_handler_final.sql
        mindsdb -f create_tables.sql
        echo "✅ Whale Alert handler created successfully"
    else
        echo "⚠️  MindsDB CLI not found. SQL files created for manual execution."
    fi
}

# Validation
validate_setup() {
    echo "Validating Whale Alert handler setup..."
    
    cat > validate.sql << 'EOF'
-- Validation queries
SHOW DATABASES;
DESCRIBE whale_alert_db;
SELECT * FROM whale_alert_db.status LIMIT 1;
EOF
    
    if command -v mindsdb &> /dev/null; then
        mindsdb -f validate.sql
        echo "✅ Validation completed"
    else
        echo "⚠️  Manual validation required"
    fi
}

# Main execution
main() {
    execute_setup
    validate_setup
    echo "🎉 Whale Alert handler setup completed!"
}

main "$@"
