
#!/bin/bash

# Integration Test Execution Script
# Runs the comprehensive integration test suite

set -e

echo "🧪 Executing XplainCrypto Integration Tests..."

# Check if setup has been run
if [ ! -f "integration_test.sh" ]; then
    echo "❌ Integration test framework not set up. Running setup first..."
    ./setup.sh
fi

# Execute the integration tests
if [ -f "integration_test.sh" ]; then
    ./integration_test.sh
else
    echo "❌ Integration test script not found. Please run setup.sh first."
    exit 1
fi
