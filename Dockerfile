# XplainCrypto Platform - Multi-Handler MindsDB Dockerfile
FROM mindsdb/mindsdb:latest

# Set working directory
WORKDIR /opt/mindsdb

# Install system dependencies
USER root
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    gcc \
    python3-dev \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Install crypto dependencies
RUN pip install --no-cache-dir \
    web3>=6.0.0 \
    ccxt>=4.0.0 \
    python-binance>=1.0.17 \
    pandas>=2.0.0 \
    requests>=2.31.0 \
    psycopg2-binary>=2.9.0 \
    redis>=4.5.0

# Setup SSH for private repos
RUN mkdir -p /root/.ssh && ssh-keyscan github.com >> /root/.ssh/known_hosts

# Install XplainCrypto handlers properly
RUN --mount=type=ssh git clone git@github.com:Gerard161-Site/coinmarketcap_handler.git /tmp/coinmarketcap_handler && \
    cp -r /tmp/coinmarketcap_handler /mindsdb/mindsdb/integrations/handlers/ && \
    pip install -e /mindsdb/mindsdb/integrations/handlers/coinmarketcap_handler

RUN --mount=type=ssh git clone git@github.com:Gerard161-Site/defillama_handler.git /tmp/defillama_handler && \
    cp -r /tmp/defillama_handler /mindsdb/mindsdb/integrations/handlers/ && \
    pip install -e /mindsdb/mindsdb/integrations/handlers/defillama_handler

RUN --mount=type=ssh git clone git@github.com:Gerard161-Site/blockchain_handler.git /tmp/blockchain_handler && \
    cp -r /tmp/blockchain_handler /mindsdb/mindsdb/integrations/handlers/ && \
    pip install -e /mindsdb/mindsdb/integrations/handlers/blockchain_handler

RUN --mount=type=ssh git clone git@github.com:Gerard161-Site/dune_handler.git /tmp/dune_handler && \
    cp -r /tmp/dune_handler /mindsdb/mindsdb/integrations/handlers/ && \
    pip install -e /mindsdb/mindsdb/integrations/handlers/dune_handler

RUN --mount=type=ssh git clone git@github.com:Gerard161-Site/whale_alerts_handler.git /tmp/whale_alerts_handler && \
    cp -r /tmp/whale_alerts_handler /mindsdb/mindsdb/integrations/handlers/ && \
    pip install -e /mindsdb/mindsdb/integrations/handlers/whale_alerts_handler

# Expose port
EXPOSE 47334

# Start MindsDB
CMD ["python", "-m", "mindsdb", "--api", "http", "--verbose"]