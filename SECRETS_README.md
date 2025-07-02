# Manual Secrets Setup

After git pull, create secrets manually:

```bash
mkdir -p secrets && chmod 700 secrets

# Add your API keys manually to these files:
# secrets/openai_api_key.txt
# secrets/anthropic_api_key.txt  
# secrets/timegpt_api_key.txt
# secrets/coinmarketcap_api_key.txt
# secrets/dune_api_key.txt
# secrets/coingecko_api_key.txt
# secrets/postgres_password.txt
# secrets/redis_password.txt

chmod 600 secrets/*.txt
```
