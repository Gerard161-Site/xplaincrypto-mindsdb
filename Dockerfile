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

# Copy requirements and install Python dependencies
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Install additional dependencies for crypto handlers
RUN pip install --no-cache-dir \
    web3>=6.0.0 \
    ccxt>=4.0.0 \
    python-binance>=1.0.17 \
    blockcypher>=1.0.93 \
    tweepy>=4.14.0 \
    praw>=7.7.0

# Copy custom handlers
COPY --chown=mindsdb:mindsdb ../mindsdb-handlers/ /opt/mindsdb/handlers/custom/

# Copy agents
COPY --chown=mindsdb:mindsdb agents/ /opt/mindsdb/agents/

# Copy SQL scripts
COPY --chown=mindsdb:mindsdb sql/ /opt/mindsdb/sql/

# Create logs directory
RUN mkdir -p /opt/mindsdb/logs && chown mindsdb:mindsdb /opt/mindsdb/logs

# Copy startup script
COPY scripts/start-mindsdb.sh /opt/mindsdb/start-mindsdb.sh
RUN chmod +x /opt/mindsdb/start-mindsdb.sh

# Switch back to mindsdb user
USER mindsdb

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:47334/api/status || exit 1

# Expose ports
EXPOSE 47334 47335

# Use custom startup script
CMD ["/opt/mindsdb/start-mindsdb.sh"]