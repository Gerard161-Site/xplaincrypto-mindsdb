
#!/bin/bash

# DefiLlama Handler Setup Script
# Sets up DefiLlama data source integration for DeFi protocols

set -e

echo "🦙 Setting up DefiLlama Handler..."

# Configuration
HANDLER_NAME="defillama_handler"
API_BASE_URL="https://api.llama.fi"

# Create handler SQL
cat > create_handler.sql << 'EOF'
-- Create DefiLlama Handler
CREATE OR REPLACE DATABASE defillama_db
WITH ENGINE = 'http',
PARAMETERS = {
    "base_url": "https://api.llama.fi",
    "headers": {
        "User-Agent": "XplainCrypto-MindsDB/1.0"
    },
    "timeout": 30
};
EOF

# Create tables SQL
cat > create_tables.sql << 'EOF'
-- DefiLlama Tables

-- Protocol TVL data
CREATE OR REPLACE VIEW defillama_db.protocols AS (
    SELECT * FROM defillama_db.protocols
);

-- TVL historical data
CREATE OR REPLACE VIEW defillama_db.tvl_historical AS (
    SELECT * FROM defillama_db.charts
);

-- Protocol yields
CREATE OR REPLACE VIEW defillama_db.yields AS (
    SELECT * FROM defillama_db.yields
);

-- Chain TVL data
CREATE OR REPLACE VIEW defillama_db.chains AS (
    SELECT * FROM defillama_db.chains
);
EOF

# Execute setup
execute_setup() {
    echo "Creating DefiLlama handler..."
    
    # Execute SQL commands
    if command -v mindsdb &> /dev/null; then
        mindsdb -f create_handler.sql
        mindsdb -f create_tables.sql
        echo "✅ DefiLlama handler created successfully"
    else
        echo "⚠️  MindsDB CLI not found. SQL files created for manual execution."
    fi
}

# Validation
validate_setup() {
    echo "Validating DefiLlama handler setup..."
    
    cat > validate.sql << 'EOF'
-- Validation queries
SHOW DATABASES;
DESCRIBE defillama_db;
SELECT * FROM defillama_db.protocols LIMIT 5;
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
    echo "🎉 DefiLlama handler setup completed!"
}

main "$@"
