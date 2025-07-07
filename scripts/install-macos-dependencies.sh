#!/bin/bash

# XplainCrypto MindsDB macOS Dependencies Installation
# Installs required tools for deployment on macOS

set -e

echo "🍎 Installing XplainCrypto MindsDB Dependencies for macOS"
echo "========================================================"

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "✅ Homebrew installed successfully!"
else
    echo "✅ Homebrew is already installed"
fi

# Update Homebrew
echo "🔄 Updating Homebrew..."
brew update

# Install MySQL client
if ! command -v mysql &> /dev/null; then
    echo "📦 Installing MySQL client..."
    brew install mysql-client
    
    # Add mysql to PATH if needed
    echo "🔧 Configuring MySQL client PATH..."
    echo 'export PATH="/opt/homebrew/bin/mysql:$PATH"' >> ~/.zshrc
    export PATH="/opt/homebrew/bin/mysql:$PATH"
    
    echo "✅ MySQL client installed successfully!"
else
    echo "✅ MySQL client is already installed"
fi

# Install curl (should be already installed but verify)
if ! command -v curl &> /dev/null; then
    echo "📦 Installing curl..."
    brew install curl
    echo "✅ curl installed successfully!"
else
    echo "✅ curl is already installed"
fi

# Install Python 3 if not available
if ! command -v python3 &> /dev/null; then
    echo "📦 Installing Python 3..."
    brew install python@3.12
    echo "✅ Python 3 installed successfully!"
else
    echo "✅ Python 3 is already installed"
fi

# Install jq for JSON processing
if ! command -v jq &> /dev/null; then
    echo "📦 Installing jq for JSON processing..."
    brew install jq
    echo "✅ jq installed successfully!"
else
    echo "✅ jq is already installed"
fi

# Make scripts executable
echo "🔧 Making scripts executable..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$SCRIPT_DIR"/*.sh
echo "✅ Scripts are now executable!"

echo ""
echo "🎉 All dependencies installed successfully!"
echo ""
echo "🔄 Please restart your terminal or run:"
echo "   source ~/.zshrc"
echo ""
echo "🚀 Then you can proceed with:"
echo "   ./scripts/create-secrets-directory.sh"
echo "   ./scripts/validate-deployment-readiness.sh" 