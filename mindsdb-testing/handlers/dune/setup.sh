
#!/bin/bash

# Dune Analytics Handler Setup Script
# Sets up Dune Analytics data integration

set -e

echo "🔮 Setting up Dune Analytics Handler..."

# Configuration
HANDLER_NAME="dune_handler"
API_BASE_URL="https://api.dune.com"

# Create handler SQL
cat > create_handler.sql << 'EOF'
-- Create Dune Analytics Handler
CREATE OR REPLACE DATABASE dune_db
WITH ENGINE = 'http',
PARAMETERS = {
    "base_url": "https://api.dune.com/api/v1",
    "headers": {
        "X-Dune-API-Key": "{{DUNE_API_KEY}}",
        "Content-Type": "application/json"
    },
    "timeout": 60
};
EOF

# Create tables SQL
cat > create_tables.sql << 'EOF'
-- Dune Analytics Tables

-- Query results
CREATE OR REPLACE VIEW dune_db.query_results AS (
    SELECT * FROM dune_db.query_results
);

-- Query execution status
CREATE OR REPLACE VIEW dune_db.executions AS (
    SELECT * FROM dune_db.executions
);

-- Query metadata
CREATE OR REPLACE VIEW dune_db.queries AS (
    SELECT * FROM dune_db.queries
);
EOF

# Execute setup
execute_setup() {
    echo "Creating Dune Analytics handler..."
    
    # Check if API key is set
    if [ -z "$DUNE_API_KEY" ]; then
        echo "⚠️  Warning: DUNE_API_KEY environment variable not set"
        echo "Please set your Dune Analytics API key:"
        echo "export DUNE_API_KEY='your_api_key_here'"
    fi
    
    # Replace API key placeholder
    sed "s/{{DUNE_API_KEY}}/$DUNE_API_KEY/g" create_handler.sql > create_handler_final.sql
    
    # Execute SQL commands
    if command -v mindsdb &> /dev/null; then
        mindsdb -f create_handler_final.sql
        mindsdb -f create_tables.sql
        echo "✅ Dune Analytics handler created successfully"
    else
        echo "⚠️  MindsDB CLI not found. SQL files created for manual execution."
    fi
}

# Validation
validate_setup() {
    echo "Validating Dune Analytics handler setup..."
    
    cat > validate.sql << 'EOF'
-- Validation queries
SHOW DATABASES;
DESCRIBE dune_db;
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
    echo "🎉 Dune Analytics handler setup completed!"
}

main "$@"
