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
    && rm -rf /var/lib/apt/lists/*

# Install crypto dependencies directly
RUN pip install --no-cache-dir \
    web3>=6.0.0 \
    ccxt>=4.0.0 \
    python-binance>=1.0.17 \
    pandas>=2.0.0 \
    requests>=2.31.0 \
    psycopg2-binary>=2.9.0 \
    redis>=4.5.0

# Copy SQL initialization files
COPY sql/ /opt/mindsdb/sql/

# Copy agent definitions
COPY agents/ /opt/mindsdb/agents/

# Expose port
EXPOSE 47334

# Start MindsDB
CMD ["python", "-m", "mindsdb", "--api", "http", "--verbose"]