#!/bin/bash

# XplainCrypto MindsDB Secrets Setup Script
# Creates secrets directory and template files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SECRETS_DIR="$PROJECT_DIR/secrets"

echo "🔐 Setting up XplainCrypto MindsDB Secrets Directory"
echo "=================================================="

# Create secrets directory
echo "📁 Creating secrets directory..."
mkdir -p "$SECRETS_DIR"

# Create template files for all required secrets
echo "📝 Creating secret template files..."

# OpenAI API Key
cat > "$SECRETS_DIR/openai_api_key.txt" << 'EOF'
sk-your-openai-api-key-here
EOF

# Anthropic API Key  
cat > "$SECRETS_DIR/anthropic_api_key.txt" << 'EOF'
sk-ant-your-anthropic-api-key-here
EOF

# TimeGPT API Key
cat > "$SECRETS_DIR/timegpt_api_key.txt" << 'EOF'
your-timegpt-api-key-here
EOF

# CoinMarketCap API Key
cat > "$SECRETS_DIR/coinmarketcap_api_key.txt" << 'EOF'
your-coinmarketcap-api-key-here
EOF

# Dune API Key
cat > "$SECRETS_DIR/dune_api_key.txt" << 'EOF'
your-dune-api-key-here
EOF

# CoinGecko API Key
cat > "$SECRETS_DIR/coingecko_api_key.txt" << 'EOF'
your-coingecko-api-key-here
EOF

# PostgreSQL Password
cat > "$SECRETS_DIR/postgres_password.txt" << 'EOF'
rfmveurVyThziPsujMdMsnya6JNirlz8nFrcH34o9Xs=
EOF

# Redis Password
cat > "$SECRETS_DIR/redis_password.txt" << 'EOF'
your-redis-password-here
EOF

# Set proper permissions
echo "🔒 Setting secure permissions..."
chmod 700 "$SECRETS_DIR"
chmod 600 "$SECRETS_DIR"/*.txt

# Create secrets instructions
cat > "$SECRETS_DIR/README.md" << 'EOF'
# XplainCrypto MindsDB Secrets

## 🔐 Required API Keys

Before deployment, you must update these files with your actual API keys:

### AI/ML Services
- `openai_api_key.txt` - OpenAI GPT-4 API key
- `anthropic_api_key.txt` - Anthropic Claude API key  
- `timegpt_api_key.txt` - Nixtla TimeGPT API key

### Crypto Data Services
- `coinmarketcap_api_key.txt` - CoinMarketCap Pro API key
- `dune_api_key.txt` - Dune Analytics API key
- `coingecko_api_key.txt` - CoinGecko Pro API key

### Infrastructure
- `postgres_password.txt` - PostgreSQL database password
- `redis_password.txt` - Redis cache password

## 🔑 How to Get API Keys

### OpenAI (GPT-4)
1. Visit: https://platform.openai.com/api-keys
2. Create new secret key
3. Copy key starting with "sk-"

### Anthropic (Claude)
1. Visit: https://console.anthropic.com/
2. Go to API Keys section
3. Create new key starting with "sk-ant-"

### TimeGPT (Nixtla)
1. Visit: https://dashboard.nixtla.io/
2. Sign up for TimeGPT access
3. Get API key from dashboard

### CoinMarketCap
1. Visit: https://pro.coinmarketcap.com/account
2. Create free or pro account
3. Get API key from dashboard

### Dune Analytics
1. Visit: https://dune.com/settings/api
2. Create account and get API key
3. Free tier available

### CoinGecko
1. Visit: https://www.coingecko.com/en/api/pricing
2. Create account for Pro API
3. Get API key from dashboard

## ⚠️ Security Notes

- Never commit these files to version control
- Keep API keys secure and rotate regularly
- Use environment variables in production
- Monitor API usage and costs

## 🚀 Ready to Deploy?

Once all API keys are added, run:
```bash
./scripts/validate-deployment-readiness.sh
```
EOF

echo ""
echo "✅ Secrets directory created successfully!"
echo ""
echo "📍 Location: $SECRETS_DIR"
echo ""
echo "🔑 Next steps:"
echo "   1. Edit each .txt file with your actual API keys"
echo "   2. See README.md for instructions on getting API keys"
echo "   3. Run validation script again: ./scripts/validate-deployment-readiness.sh"
echo ""
echo "⚠️  Important: Never commit secrets to version control!" 