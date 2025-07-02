#!/bin/bash

# Quick deployment runner
echo "🚀 Running complete MindsDB deployment..."

cd "$(dirname "$0")/.."

# Run the full deployment
./scripts/deploy-mindsdb.sh

# If successful, initialize databases
if [ $? -eq 0 ]; then
    echo "✅ MindsDB deployed successfully!"
    echo "🗄️ Initializing databases..."
    ./scripts/initialize-databases.sh
else
    echo "❌ MindsDB deployment failed!"
    exit 1
fi

echo "🎉 Complete deployment finished!" 