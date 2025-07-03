# XplainCrypto Platform - Multi-Handler MindsDB Dockerfile
FROM mindsdb/mindsdb:latest

WORKDIR /mindsdb

RUN apt-get update && apt-get install -y git curl wget gcc python3-dev && rm -rf /var/lib/apt/lists/*

# Install additional crypto dependencies
RUN pip install --no-cache-dir web3>=6.0.0 ccxt>=4.0.0 python-binance>=1.0.17 pandas>=2.0.0 requests>=2.31.0 psycopg2-binary>=2.9.0 redis>=4.5.0

# Clone and install each XplainCrypto handler following MindsDB's official pattern
RUN git clone https://github.com/Gerard161-Site/coinmarketcap_handler.git /mindsdb/mindsdb/integrations/handlers/coinmarketcap_handler
RUN pip install -e /mindsdb/mindsdb/integrations/handlers/coinmarketcap_handler
RUN pip install -r /mindsdb/mindsdb/integrations/handlers/coinmarketcap_handler/requirements.txt

RUN git clone https://github.com/Gerard161-Site/defillama_handler.git /mindsdb/mindsdb/integrations/handlers/defillama_handler
RUN pip install -e /mindsdb/mindsdb/integrations/handlers/defillama_handler
RUN pip install -r /mindsdb/mindsdb/integrations/handlers/defillama_handler/requirements.txt

RUN git clone https://github.com/Gerard161-Site/blockchain_handler.git /mindsdb/mindsdb/integrations/handlers/blockchain_handler
RUN pip install -e /mindsdb/mindsdb/integrations/handlers/blockchain_handler
RUN pip install -r /mindsdb/mindsdb/integrations/handlers/blockchain_handler/requirements.txt

RUN git clone https://github.com/Gerard161-Site/dune_handler.git /mindsdb/mindsdb/integrations/handlers/dune_handler
RUN pip install -e /mindsdb/mindsdb/integrations/handlers/dune_handler
RUN pip install -r /mindsdb/mindsdb/integrations/handlers/dune_handler/requirements.txt

RUN git clone https://github.com/Gerard161-Site/whale_alerts_handler.git /mindsdb/mindsdb/integrations/handlers/whale_alerts_handler
RUN pip install -e /mindsdb/mindsdb/integrations/handlers/whale_alerts_handler
RUN pip install -r /mindsdb/mindsdb/integrations/handlers/whale_alerts_handler/requirements.txt

CMD ["python", "-m", "mindsdb"]