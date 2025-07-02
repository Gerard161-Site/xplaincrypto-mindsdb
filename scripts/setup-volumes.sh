#!/bin/bash

# XplainCrypto MindsDB Volume Setup
# Creates required directories for persistent data

echo "📁 Setting up MindsDB volumes..."

# Create base directory
sudo mkdir -p /var/lib/xplaincrypto/mindsdb
sudo mkdir -p /var/lib/xplaincrypto/mindsdb/var
sudo mkdir -p /var/lib/xplaincrypto/mindsdb/logs
sudo mkdir -p /var/lib/xplaincrypto/mindsdb/data

# Set permissions for MindsDB process
sudo chown -R 1000:1000 /var/lib/xplaincrypto/mindsdb
sudo chmod -R 755 /var/lib/xplaincrypto/mindsdb

# Create logs directory locally
mkdir -p logs
chmod 755 logs

echo "✅ Volume directories created:"
echo "   - /var/lib/xplaincrypto/mindsdb (persistent MindsDB data)"
echo "   - ./logs (local logs directory)" 