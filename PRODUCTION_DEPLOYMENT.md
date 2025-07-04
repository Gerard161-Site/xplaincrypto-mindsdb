# XplainCrypto MindsDB Production Deployment

## 🎯 Secure Deployment on Production Server (142.93.49.20)

### Step 1: Pull Latest Code
```bash
# SSH to production server
ssh root@142.93.49.20

# Navigate to MindsDB directory (or clone if first time)
cd /root/xplaincrypto-mindsdb
git pull origin main

# Or clone if first time:
# git clone https://github.com/Gerard161-Site/xplaincrypto-mindsdb.git
# cd xplaincrypto-mindsdb
```

### Step 2: Setup API Keys Securely
```bash
# Create secrets template
./scripts/deploy-secrets.sh --setup

# Edit with your real API keys
nano .env.secrets
```

#### Required API Keys:
- **OpenAI**: Your OpenAI API key
- **Anthropic**: Your Anthropic API key  
- **TimeGPT**: Your TimeGPT API key
- **CoinMarketCap**: Your CoinMarketCap API key
- **Dune**: Your Dune Analytics API key
- **CoinGecko**: Your CoinGecko API key
- **Tavily**: Your Tavily API key
- **HuggingFace**: Your HuggingFace API key

> **Note**: Contact the deployment team for the actual API key values. Never commit real keys to this repository.

### Step 3: Verify MindsDB Connection
```bash
# Check MindsDB is running
curl -s http://localhost:47334/api/status

# Expected: {"status": "ok"}
```

### Step 4: Deploy All Secrets and AI Agents
```bash
# Interactive deployment (recommended)
./scripts/deploy-secrets.sh --interactive

# Or use the prepared .env.secrets file
./scripts/deploy-secrets.sh
```

### Step 5: Verify Deployment
```bash
# Test comprehensive deployment
./scripts/test-mindsdb-setup.sh

# Check specific components
curl -s -X POST http://localhost:47334/api/sql/query \
  -H "Content-Type: application/json" \
  -d '{"query": "SHOW DATABASES;"}'
```

## 🔒 Security Features

✅ **No Secrets in Repository**: All API keys loaded at runtime  
✅ **Multiple Input Methods**: Interactive, environment vars, or .env file  
✅ **Automatic Cleanup**: Sensitive variables cleared after deployment  
✅ **Production Ready**: Designed for bank-grade security standards  

## 📊 Expected Results After Deployment

### Databases Connected:
- ✅ crypto_data (PostgreSQL)
- ✅ coinmarketcap_db
- ✅ dune_db  
- ✅ coingecko_db
- ✅ defillama_db
- ✅ blockchain_db

### AI Engines Active:
- ✅ TimeGPT (price forecasting)
- ✅ Claude (market analysis)
- ✅ GPT-4 (general AI tasks)

### AI Agents Responding:
1. **Prediction Agent**: Crypto price forecasting
2. **Analysis Agent**: Market insights and analysis
3. **Risk Assessment Agent**: Portfolio risk evaluation
4. **Anomaly Detection Agent**: Market anomaly detection  
5. **Sentiment Analysis Agent**: Social media sentiment

## 🚨 Troubleshooting

### Connection Issues:
```bash
# Check MindsDB logs
docker logs mindsdb-crypto-docker-mindsdb-1

# Restart if needed
docker-compose restart mindsdb
```

### API Key Issues:
```bash
# Test individual API keys
curl -H "Authorization: Bearer $OPENAI_API_KEY" \
  https://api.openai.com/v1/models
```

### Database Issues:
```bash
# Check PostgreSQL connection
psql -h localhost -p 5432 -U mindsdb -d crypto_data -c "SELECT 1;"
```

## 📞 Support

- **Production Server**: 142.93.49.20
- **MindsDB API**: http://142.93.49.20:47334
- **Repository**: https://github.com/Gerard161-Site/xplaincrypto-mindsdb

Ready for deployment! 🚀 