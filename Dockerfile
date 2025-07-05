# XplainCrypto Platform - Multi-Handler MindsDB Dockerfile
FROM mindsdb/mindsdb:latest

# Clone all 5 crypto handlers from GitHub
WORKDIR /mindsdb/mindsdb/integrations/handlers

RUN apt-get update && apt-get install -y git curl wget gcc python3-dev && rm -rf /var/lib/apt/lists/*

# Install additional crypto dependencies
RUN pip install --no-cache-dir \
    pycoingecko \
    coinmarketcapapi \
    dune-client \
    web3>=6.0.0 ccxt>=4.0.0 python-binance>=1.0.17 pandas>=2.0.0 requests>=2.31.0 psycopg2-binary>=2.9.0 redis>=4.5.0 nixtla==0.6.6

# 1. CoinMarketCap Handler
RUN git clone https://github.com/Gerard161-Site/coinmarketcap_handler.git && \
    cd coinmarketcap_handler && \
    if [ -f requirements.txt ]; then pip install -r requirements.txt; fi && \
    cd ..

# 2. DeFiLlama Handler  
RUN git clone https://github.com/Gerard161-Site/defillama_handler.git && \
    cd defillama_handler && \
    if [ -f requirements.txt ]; then pip install -r requirements.txt; fi && \
    cd ..

# 3. Blockchain Handler
RUN git clone https://github.com/Gerard161-Site/blockchain_handler.git && \
    cd blockchain_handler && \
    if [ -f requirements.txt ]; then pip install -r requirements.txt; fi && \
    cd ..

# 4. Dune Handler
RUN git clone https://github.com/Gerard161-Site/dune_handler.git && \
    cd dune_handler && \
    if [ -f requirements.txt ]; then pip install -r requirements.txt; fi && \
    cd ..

# 5. Whale Alerts Handler
RUN git clone https://github.com/Gerard161-Site/whale_alerts_handler.git && \
    cd whale_alerts_handler && \
    if [ -f requirements.txt ]; then pip install -r requirements.txt; fi && \
    cd ..

# Verify handlers were cloned
RUN ls -la /mindsdb/mindsdb/integrations/handlers/

# Set working directory back to MindsDB root
WORKDIR /mindsdb

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:47334/api/status || exit 1

# Expose ports
EXPOSE 47334 47335 47336 47337
CMD ["python", "-m", "mindsdb", "--api", "http", "--config", "/opt/mindsdb"]