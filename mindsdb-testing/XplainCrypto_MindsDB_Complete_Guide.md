# XplainCrypto MindsDB Complete Learning Guide
*Updated: July 17, 2025*

## Table of Contents
1. [System Overview](#system-overview)
2. [Database Architecture](#database-architecture)
3. [ML Engines](#ml-engines)
4. [Handlers (Data Sources)](#handlers-data-sources)
5. [Models (AI Agents)](#models-ai-agents)
6. [Jobs (Automation)](#jobs-automation)
7. [Skills](#skills)
8. [Agents](#agents)
9. [Knowledge Bases](#knowledge-bases)
10. [Enhanced User-Focused Features](#enhanced-user-focused-features)
11. [Testing Examples](#testing-examples)
12. [Performance Characteristics](#performance-characteristics)
13. [Use Cases for XplainCrypto](#use-cases-for-xplaincrypto)

---

## System Overview

Your MindsDB instance at `http://mindsdb.xplaincrypto.ai/` is running version **25.7.2.0** in local environment with authentication disabled. This comprehensive system integrates multiple cryptocurrency data sources with AI-powered analysis capabilities and a robust user-centric platform.

### Core Architecture
- **crypto_data database**: ALL historical cryptocurrency data from external handlers
- **user_data database**: User profiles, portfolios, social features, e-learning platform
- **MindsDB Core**: AI models, agents, jobs, skills, and knowledge bases
- **External Integrations**: 6 specialized data handlers for comprehensive market coverage

---

## Database Architecture

### 1. crypto_data Database

**Purpose:** Centralized repository for ALL historical cryptocurrency data aggregated from external handlers including market data, DeFi protocols, blockchain transactions, and analytics.

**Data Sources Integration:**
- CoinMarketCap: Real-time prices, market caps, rankings
- DeFiLlama: Protocol TVL, yields, stablecoin data
- Binance: Trading data, order books, OHLCV
- Blockchain: On-chain transactions, blocks, addresses
- Dune Analytics: Custom queries and advanced analytics
- Whale Alerts: Large transaction monitoring

**Creation SQL:**
```sql
CREATE DATABASE crypto_data 
WITH (
    ENGINE = 'postgres',
    PARAMETERS = {
        "host": "crypto-data-host",
        "port": 5432,
        "database": "crypto_historical_data",
        "user": "crypto_user",
        "password": "secure_password"
    }
);
```

**Key Tables Structure:**
```sql
-- Historical price data from all sources
CREATE TABLE crypto_data.price_history (
    price_id UUID PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    price_usd DECIMAL(20,8),
    market_cap DECIMAL(20,2),
    volume_24h DECIMAL(20,2),
    timestamp TIMESTAMP WITH TIME ZONE,
    data_source VARCHAR(50)
);

-- DeFi protocol data
CREATE TABLE crypto_data.defi_protocols (
    protocol_id UUID PRIMARY KEY,
    name VARCHAR(100),
    tvl DECIMAL(20,2),
    category VARCHAR(50),
    chains TEXT[],
    updated_at TIMESTAMP
);

-- Blockchain transaction data
CREATE TABLE crypto_data.blockchain_transactions (
    tx_id UUID PRIMARY KEY,
    hash VARCHAR(255),
    block_height BIGINT,
    from_address VARCHAR(100),
    to_address VARCHAR(100),
    amount DECIMAL(30,18),
    network VARCHAR(50),
    timestamp TIMESTAMP
);
```

**Testing Examples:**
```sql
-- Get latest Bitcoin price from all sources
SELECT symbol, price_usd, data_source, timestamp 
FROM crypto_data.price_history 
WHERE symbol = 'BTC' 
ORDER BY timestamp DESC 
LIMIT 10;

-- Get top DeFi protocols by TVL
SELECT name, tvl, category, chains 
FROM crypto_data.defi_protocols 
ORDER BY tvl DESC 
LIMIT 20;

-- Monitor large Bitcoin transactions
SELECT hash, from_address, to_address, amount, timestamp 
FROM crypto_data.blockchain_transactions 
WHERE network = 'bitcoin' 
  AND amount > 100 
ORDER BY timestamp DESC;
```

**Expected Results:**
```
symbol | price_usd | data_source | timestamp
BTC    | 45123.45  | coinmarketcap | 2025-07-17 10:30:00
BTC    | 45120.12  | binance | 2025-07-17 10:29:45
BTC    | 45125.67  | blockchain | 2025-07-17 10:29:30
```

### 2. user_data Database

**Purpose:** Comprehensive user management system supporting profiles, portfolios, social features, e-learning platform, and community interactions.

**Creation SQL:**
```sql
CREATE DATABASE user_data 
WITH (
    ENGINE = 'postgres',
    PARAMETERS = {
        "host": "user-data-host",
        "port": 5432,
        "database": "xplaincrypto_users",
        "user": "user_admin",
        "password": "secure_user_password"
    }
);
```

**Core User Management Tables:**
```sql
-- Enhanced user profiles with social features
SELECT * FROM user_data.users LIMIT 5;
-- Returns: user_id, username, email, profile_image_url, bio, kyc_status, risk_score

-- Multi-portfolio support
SELECT * FROM user_data.portfolios LIMIT 5;
-- Returns: portfolio_id, user_id, name, portfolio_type, total_value_usd, is_public

-- Social connections and following
SELECT * FROM user_data.user_connections LIMIT 5;
-- Returns: follower_id, following_id, connection_type, created_at

-- Community posts and interactions
SELECT * FROM user_data.posts LIMIT 5;
-- Returns: post_id, user_id, content, post_type, like_count, visibility
```

**Testing Examples:**
```sql
-- Get user profile with portfolio summary
SELECT 
    u.username,
    u.bio,
    COUNT(p.portfolio_id) as portfolio_count,
    SUM(p.total_value_usd) as total_portfolio_value
FROM user_data.users u
LEFT JOIN user_data.portfolios p ON u.user_id = p.user_id
WHERE u.username = 'crypto_trader_123'
GROUP BY u.user_id, u.username, u.bio;

-- Get user's social activity
SELECT 
    p.content,
    p.like_count,
    p.comment_count,
    p.created_at
FROM user_data.posts p
JOIN user_data.users u ON p.user_id = u.user_id
WHERE u.username = 'crypto_trader_123'
ORDER BY p.created_at DESC
LIMIT 10;

-- Get course enrollment progress
SELECT 
    c.title,
    ce.progress_percentage,
    ce.completion_date,
    ce.certificate_issued
FROM user_data.course_enrollments ce
JOIN user_data.courses c ON ce.course_id = c.course_id
JOIN user_data.users u ON ce.user_id = u.user_id
WHERE u.username = 'crypto_trader_123';
```

**Expected Results:**
```
username | bio | portfolio_count | total_portfolio_value
crypto_trader_123 | DeFi enthusiast and yield farmer | 3 | 125000.50

content | like_count | comment_count | created_at
"Just discovered this amazing DeFi protocol..." | 15 | 8 | 2025-07-17 09:30:00
"Bitcoin looking bullish above 45k support" | 23 | 12 | 2025-07-16 14:20:00
```

---

## ML Engines

### 1. OpenAI Engine

**Purpose:** Primary AI engine for natural language processing, analysis, and content generation using GPT models.

**Creation SQL:**
```sql
CREATE ML_ENGINE openai_engine
FROM openai
USING
    api_key = 'your_openai_api_key',
    model = 'gpt-4-turbo-preview',
    temperature = 0.7,
    max_tokens = 2000;
```

**Testing Examples:**
```sql
-- Test engine connectivity
SELECT * FROM openai_engine.models;

-- Test basic completion
SELECT openai_engine.complete('Explain Bitcoin in simple terms') as explanation;
```

**Expected Results:**
```
explanation: "Bitcoin is a digital currency that operates without a central bank or government. It uses blockchain technology to record transactions securely and transparently..."
```

**Use Cases for XplainCrypto:**
- Market analysis and commentary
- Educational content generation
- User query responses
- Trading signal explanations
- Portfolio recommendations

### 2. Anthropic Engine

**Purpose:** Advanced reasoning and analysis engine using Claude models for complex financial analysis and risk assessment.

**Creation SQL:**
```sql
CREATE ML_ENGINE anthropic_engine
FROM anthropic
USING
    api_key = 'your_anthropic_api_key',
    model = 'claude-3-opus-20240229',
    temperature = 0.5,
    max_tokens = 4000;
```

**Testing Examples:**
```sql
-- Test complex analysis capability
SELECT anthropic_engine.analyze(
    'Analyze the risk factors for a DeFi portfolio containing 40% AAVE, 30% UNI, 20% COMP, 10% SUSHI'
) as risk_analysis;
```

**Expected Results:**
```
risk_analysis: "This DeFi portfolio presents several key risk factors: 1) Protocol Risk - Smart contract vulnerabilities across all holdings, 2) Regulatory Risk - DeFi protocols face increasing scrutiny, 3) Concentration Risk - Heavy exposure to lending/DEX sectors..."
```

**Use Cases for XplainCrypto:**
- Deep fundamental analysis
- Risk assessment reports
- Complex portfolio optimization
- Regulatory impact analysis
- Technical documentation

### 3. TimeGPT Engine

**Purpose:** Specialized time series forecasting engine for price predictions and trend analysis.

**Creation SQL:**
```sql
CREATE ML_ENGINE timegpt_engine
FROM timegpt
USING
    api_key = 'your_timegpt_api_key',
    horizon = 24,
    frequency = 'H';
```

**Testing Examples:**
```sql
-- Test price forecasting
SELECT timegpt_engine.forecast(
    data = 'crypto_data.price_history',
    target = 'price_usd',
    timestamp_col = 'timestamp'
) as price_forecast
WHERE symbol = 'BTC';
```

**Expected Results:**
```
price_forecast: [
    {"timestamp": "2025-07-17 11:00:00", "forecast": 45234.56, "confidence_low": 44800, "confidence_high": 45700},
    {"timestamp": "2025-07-17 12:00:00", "forecast": 45456.78, "confidence_low": 45000, "confidence_high": 45900}
]
```

**Use Cases for XplainCrypto:**
- Price prediction models
- Trend forecasting
- Volatility predictions
- Market timing signals
- Risk modeling

---

## Handlers (Data Sources)

### 1. CoinMarketCap Handler

**Purpose:** Real-time cryptocurrency market data including prices, market caps, volumes, and rankings from the world's most referenced crypto data provider.

**Creation SQL:**
```sql
CREATE DATABASE coinmarketcap_datasource
WITH ENGINE = 'coinmarketcap',
PARAMETERS = {
    "api_key": "your_coinmarketcap_api_key",
    "sandbox": false,
    "timeout": 30
};
```

**Available Tables:**
- `quotes` - Real-time price quotes and market data
- `listings` - Cryptocurrency listings with rankings
- `info` - Detailed cryptocurrency metadata
- `global_metrics` - Global market statistics
- `categories` - Cryptocurrency categories
- `exchanges` - Exchange information

**Testing Examples:**
```sql
-- Get top 10 cryptocurrencies by market cap
SELECT 
    name,
    symbol,
    quote.USD.price as price_usd,
    quote.USD.market_cap as market_cap,
    quote.USD.percent_change_24h as change_24h
FROM coinmarketcap_datasource.listings 
ORDER BY quote.USD.market_cap DESC 
LIMIT 10;

-- Get specific coin quotes
SELECT * FROM coinmarketcap_datasource.quotes 
WHERE symbol IN ('BTC', 'ETH', 'ADA', 'SOL');

-- Get global market metrics
SELECT 
    total_market_cap,
    total_volume_24h,
    bitcoin_dominance,
    active_cryptocurrencies
FROM coinmarketcap_datasource.global_metrics;
```

**Expected Results:**
```
name | symbol | price_usd | market_cap | change_24h
Bitcoin | BTC | 45123.45 | 885000000000 | 2.34
Ethereum | ETH | 3234.56 | 389000000000 | 1.87
Binance Coin | BNB | 312.45 | 48000000000 | -0.56
```

**Use Cases for XplainCrypto:**
- Homepage price displays and market overview
- Portfolio valuation and tracking
- Market cap rankings and comparisons
- Price change alerts and notifications
- Market sentiment analysis based on dominance metrics

**Performance Characteristics:**
- Rate limit: 333 calls/day (basic), 10,000/day (professional)
- Latency: 200-500ms per request
- Data freshness: Updated every 5 minutes
- Reliability: 99.9% uptime SLA
- Coverage: 9,000+ cryptocurrencies

### 2. DeFiLlama Handler

**Purpose:** Comprehensive DeFi ecosystem data including TVL tracking, yield opportunities, stablecoin analytics, and cross-chain protocol monitoring.

**Creation SQL:**
```sql
CREATE DATABASE defillama_datasource
WITH ENGINE = 'defillama',
PARAMETERS = {
    "base_url": "https://api.llama.fi",
    "timeout": 30,
    "retry_attempts": 3
};
```

**Available Tables:**
- `protocols` - DeFi protocol information and TVL data
- `tvl` - Historical TVL data for protocols
- `yields` - Yield farming opportunities and APY data
- `stablecoins` - Stablecoin market data and circulation
- `chains` - Blockchain network TVL and statistics
- `tokens` - Token information and cross-chain data
- `fees` - Protocol fee generation data
- `volumes` - DEX volume statistics

**Testing Examples:**
```sql
-- Get top DeFi protocols by TVL
SELECT 
    name,
    tvl,
    category,
    chains,
    change_1d,
    change_7d
FROM defillama_datasource.protocols 
WHERE tvl > 1000000000 
ORDER BY tvl DESC 
LIMIT 15;

-- Get yield farming opportunities above 10% APY
SELECT 
    pool,
    project,
    symbol,
    apy,
    tvlUsd,
    chain
FROM defillama_datasource.yields 
WHERE apy > 10 
  AND tvlUsd > 1000000 
ORDER BY apy DESC 
LIMIT 20;

-- Get stablecoin market overview
SELECT 
    name,
    symbol,
    circulating,
    market_cap,
    chains
FROM defillama_datasource.stablecoins 
ORDER BY circulating DESC;

-- Get chain TVL comparison
SELECT 
    name,
    tvl,
    tokenSymbol,
    protocols
FROM defillama_datasource.chains 
ORDER BY tvl DESC;
```

**Expected Results:**
```
name | tvl | category | chains | change_1d | change_7d
Lido | 28816318318 | Liquid Staking | ["Ethereum","Solana"] | 2.3 | 5.7
AAVE V3 | 12978768868 | Lending | ["Ethereum","Arbitrum","Polygon"] | -1.2 | 3.4
Uniswap V3 | 5234567890 | DEX | ["Ethereum","Arbitrum","Polygon"] | 0.8 | -2.1

pool | project | symbol | apy | tvlUsd | chain
USDC-USDT | Curve | CRV | 15.67 | 234567890 | Ethereum
ETH-USDC | Uniswap | UNI | 12.34 | 456789012 | Arbitrum
```

**Use Cases for XplainCrypto:**
- DeFi protocol rankings and analysis dashboard
- Yield farming opportunity discovery and alerts
- TVL trend analysis and protocol health monitoring
- Cross-chain DeFi comparison and analytics
- Stablecoin market monitoring and depeg alerts
- Educational content about DeFi protocols

**Performance Characteristics:**
- Rate limit: No API key required, generous limits (1000+ requests/hour)
- Data freshness: Updated every hour for TVL, daily for yields
- Coverage: 2,000+ protocols across 150+ chains
- Historical data: Full historical TVL and yield data available
- Reliability: 99.5% uptime, community-maintained

### 3. Binance Handler

**Purpose:** Real-time trading data from the world's largest cryptocurrency exchange including order books, trade streams, candlestick data, and market statistics.

**Creation SQL:**
```sql
CREATE DATABASE binance_datasource
WITH ENGINE = 'binance',
PARAMETERS = {
    "api_key": "your_binance_api_key",
    "api_secret": "your_binance_secret",
    "testnet": false,
    "timeout": 10
};
```

**Available Tables:**
- `aggregated_trade_streams` - Real-time trade execution data
- `klines` - Candlestick/OHLCV data for technical analysis
- `ticker_24hr` - 24-hour ticker statistics for all symbols
- `order_book` - Real-time order book depth data
- `account_info` - Account information (requires authentication)
- `exchange_info` - Trading pair information and limits
- `avg_price` - Current average price for symbols

**Testing Examples:**
```sql
-- Get recent trades for major pairs
SELECT 
    symbol,
    price,
    quantity,
    time,
    isBuyerMaker
FROM binance_datasource.aggregated_trade_streams 
WHERE symbol IN ('BTCUSDT', 'ETHUSDT', 'ADAUSDT') 
ORDER BY time DESC 
LIMIT 50;

-- Get 24-hour ticker statistics
SELECT 
    symbol,
    priceChange,
    priceChangePercent,
    weightedAvgPrice,
    volume,
    quoteVolume,
    highPrice,
    lowPrice
FROM binance_datasource.ticker_24hr 
WHERE symbol LIKE '%USDT' 
ORDER BY quoteVolume DESC 
LIMIT 20;

-- Get hourly candlestick data for technical analysis
SELECT 
    openTime,
    open,
    high,
    low,
    close,
    volume
FROM binance_datasource.klines 
WHERE symbol = 'BTCUSDT' 
  AND interval = '1h' 
ORDER BY openTime DESC 
LIMIT 168; -- Last week of hourly data

-- Get order book depth
SELECT 
    symbol,
    bids,
    asks,
    lastUpdateId
FROM binance_datasource.order_book 
WHERE symbol = 'BTCUSDT' 
  AND limit = 100;
```

**Expected Results:**
```
symbol | price | quantity | time | isBuyerMaker
BTCUSDT | 45123.45 | 0.1234 | 1689595200000 | false
BTCUSDT | 45124.12 | 0.0567 | 1689595201000 | true
ETHUSDT | 3234.56 | 1.2345 | 1689595202000 | false

symbol | priceChange | priceChangePercent | volume | highPrice | lowPrice
BTCUSDT | 1234.56 | 2.81 | 12345.67890 | 46000.00 | 44500.00
ETHUSDT | 67.89 | 2.14 | 98765.43210 | 3300.00 | 3150.00
```

**Use Cases for XplainCrypto:**
- Real-time price displays and trading interfaces
- Technical analysis with OHLCV candlestick data
- Order book visualization and depth analysis
- Trading volume monitoring and alerts
- Arbitrage opportunity detection
- Market microstructure analysis

**Performance Characteristics:**
- Rate limit: 1200 requests/minute, 100,000/day
- WebSocket support: Real-time data streaming
- Latency: <100ms for most endpoints
- Reliability: 99.95% uptime SLA
- Data freshness: Real-time for trades, 1-second for tickers

### 4. Blockchain Handler

**Purpose:** Direct blockchain data access for Bitcoin, Ethereum, and other networks providing blocks, transactions, addresses, and network statistics.

**Creation SQL:**
```sql
CREATE DATABASE blockchain_datasource
WITH ENGINE = 'blockchain',
PARAMETERS = {
    "api_key": "your_blockchain_api_key",
    "networks": ["bitcoin", "ethereum", "litecoin"],
    "timeout": 30
};
```

**Available Tables:**
- `blocks` - Block information and metadata
- `transactions` - Transaction details and confirmations
- `addresses` - Address information, balances, and history
- `charts` - Network statistics and historical charts
- `stats` - Real-time network statistics
- `unconfirmed_transactions` - Mempool transaction data
- `pools` - Mining pool statistics

**Testing Examples:**
```sql
-- Get latest Bitcoin blocks
SELECT 
    height,
    hash,
    time,
    size,
    tx_count,
    fee_total
FROM blockchain_datasource.blocks 
WHERE network = 'bitcoin' 
ORDER BY height DESC 
LIMIT 10;

-- Get transaction details
SELECT 
    hash,
    block_height,
    time,
    size,
    fee,
    inputs,
    outputs
FROM blockchain_datasource.transactions 
WHERE hash = '1a2b3c4d5e6f7890abcdef1234567890abcdef1234567890abcdef1234567890';

-- Get address information and balance
SELECT 
    address,
    balance,
    total_received,
    total_sent,
    tx_count,
    first_seen
FROM blockchain_datasource.addresses 
WHERE address = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa';

-- Get network statistics
SELECT 
    network,
    difficulty,
    hash_rate,
    blocks_count,
    mempool_size,
    avg_block_time
FROM blockchain_datasource.stats 
WHERE network IN ('bitcoin', 'ethereum');
```

**Expected Results:**
```
height | hash | time | size | tx_count | fee_total
750000 | 00000000000000000008a... | 1689595200 | 1048576 | 2847 | 0.15234567
749999 | 00000000000000000007b... | 1689594600 | 987654 | 2156 | 0.12345678

address | balance | total_received | total_sent | tx_count
1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa | 0 | 6825000000 | 6825000000 | 1847
```

**Use Cases for XplainCrypto:**
- Blockchain explorer functionality
- Transaction tracking and monitoring
- Address portfolio tracking
- Network health monitoring
- On-chain analytics and whale watching
- Mining pool analysis

**Performance Characteristics:**
- Rate limit: 10,000 requests/hour (paid plans)
- Historical data: Full blockchain history available
- Multi-network support: Bitcoin, Ethereum, Litecoin, and more
- Real-time data: New blocks and transactions
- Reliability: 99.9% uptime

### 5. Dune Analytics Handler

**Purpose:** Advanced on-chain analytics and custom blockchain data analysis through Dune's powerful query engine and community datasets.

**Creation SQL:**
```sql
CREATE DATABASE dune_datasource
WITH ENGINE = 'dune',
PARAMETERS = {
    "api_key": "your_dune_api_key",
    "base_url": "https://api.dune.com/api/v1",
    "timeout": 60
};
```

**Available Tables:**
- `balances` - Token balances for addresses
- `transactions` - Enhanced transaction analytics
- `collectibles` - NFT data and analytics
- `queries` - Dune query metadata and information
- `executions` - Query execution status and results
- `results` - Query result data
- `contracts` - Smart contract interaction data
- `dex` - DEX trading analytics
- `markets` - Market and trading analytics

**Testing Examples:**
```sql
-- Get token balances for a specific address
SELECT 
    token_address,
    token_symbol,
    balance,
    balance_usd,
    last_updated
FROM dune_datasource.balances 
WHERE wallet_address = '0x8ba1f109551bD432803012645Hac136c22C501e' 
  AND balance_usd > 1000
ORDER BY balance_usd DESC;

-- Get DEX trading data for USDC
SELECT 
    block_time,
    tx_hash,
    trader,
    token_bought_symbol,
    token_sold_symbol,
    token_bought_amount,
    token_sold_amount,
    usd_amount,
    project
FROM dune_datasource.dex 
WHERE token_bought_symbol = 'USDC' 
  OR token_sold_symbol = 'USDC'
ORDER BY block_time DESC 
LIMIT 100;

-- Execute custom Dune query
SELECT * FROM dune_datasource.results 
WHERE query_id = 1234567;

-- Get NFT collection analytics
SELECT 
    collection_name,
    floor_price,
    volume_24h,
    sales_count_24h,
    unique_buyers_24h
FROM dune_datasource.collectibles 
ORDER BY volume_24h DESC 
LIMIT 20;
```

**Expected Results:**
```
token_symbol | balance | balance_usd | last_updated
USDC | 50000.123456 | 50000.12 | 2025-07-17 10:30:00
WETH | 15.678901 | 50456.78 | 2025-07-17 10:30:00
UNI | 1234.567890 | 8765.43 | 2025-07-17 10:30:00

project | token_bought_symbol | token_sold_symbol | usd_amount | block_time
Uniswap V3 | USDC | WETH | 125000.50 | 2025-07-17 10:25:00
1inch | WETH | USDC | 87500.25 | 2025-07-17 10:24:30
```

**Use Cases for XplainCrypto:**
- Advanced on-chain analytics and insights
- Custom dashboard creation with blockchain data
- DeFi protocol deep-dive analysis
- Token holder and whale analysis
- MEV and arbitrage opportunity detection
- NFT market analytics

**Performance Characteristics:**
- Rate limit: 1,000 queries/month (basic), 10,000/month (premium)
- Query complexity: Supports complex SQL queries
- Historical data: Full blockchain history since genesis
- Custom analytics: Community-driven query library
- Execution time: 30 seconds to 5 minutes depending on complexity

### 6. Whale Alerts Handler

**Purpose:** Real-time monitoring of large cryptocurrency transactions and whale movements across multiple blockchains for market impact analysis.

**Creation SQL:**
```sql
CREATE DATABASE whale_alerts_datasource
WITH ENGINE = 'whale_alerts',
PARAMETERS = {
    "api_key": "your_whale_alerts_api_key",
    "min_value": 100000,
    "currencies": ["bitcoin", "ethereum", "tether", "binance-coin"]
};
```

**Available Tables:**
- `transactions` - Large transaction alerts
- `status` - API status and limits
- `currencies` - Supported currencies

**Testing Examples:**
```sql
-- Get recent whale transactions above $1M
SELECT 
    blockchain,
    symbol,
    amount,
    amount_usd,
    from_address,
    to_address,
    transaction_type,
    timestamp
FROM whale_alerts_datasource.transactions 
WHERE amount_usd > 1000000 
ORDER BY timestamp DESC 
LIMIT 25;

-- Monitor Bitcoin whale movements
SELECT 
    amount,
    amount_usd,
    from_owner,
    to_owner,
    transaction_type,
    timestamp
FROM whale_alerts_datasource.transactions 
WHERE symbol = 'BTC' 
  AND amount > 100
ORDER BY timestamp DESC;

-- Get exchange flow analysis
SELECT 
    transaction_type,
    COUNT(*) as transaction_count,
    SUM(amount_usd) as total_value_usd,
    AVG(amount_usd) as avg_value_usd
FROM whale_alerts_datasource.transactions 
WHERE transaction_type IN ('exchange_to_exchange', 'wallet_to_exchange', 'exchange_to_wallet')
  AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY transaction_type;
```

**Expected Results:**
```
blockchain | symbol | amount | amount_usd | transaction_type | timestamp
ethereum | USDT | 50000000 | 50000000 | exchange_to_exchange | 2025-07-17 10:15:00
bitcoin | BTC | 1234.56 | 55678901 | wallet_to_exchange | 2025-07-17 10:10:00
ethereum | USDC | 25000000 | 25000000 | exchange_to_wallet | 2025-07-17 10:05:00
```

**Use Cases for XplainCrypto:**
- Whale movement alerts and notifications
- Large transaction impact analysis
- Exchange flow monitoring
- Market manipulation detection
- Institutional activity tracking
- Risk management for large holders

**Performance Characteristics:**
- Rate limit: 100 requests/hour (free), 1000/hour (premium)
- Real-time alerts: <30 seconds from blockchain confirmation
- Coverage: Bitcoin, Ethereum, and 100+ other cryptocurrencies
- Minimum thresholds: Configurable from $100K to $10M+
- Accuracy: 99.5% transaction detection rate

---

## Models (AI Agents)

### 1. Market Sentiment Analyzer

**Purpose:** Analyzes market sentiment from news, social media, and trading data to provide comprehensive sentiment scores and market psychology insights.

**Creation SQL:**
```sql
CREATE MODEL mindsdb.market_sentiment_analyzer
PREDICT sentiment_analysis
USING
    engine = 'anthropic_engine',
    model_name = 'claude-3-sonnet-20240229',
    temperature = 0.3,
    max_tokens = 1200,
    prompt_template = 'Analyze cryptocurrency market sentiment based on:
    
    News Headlines: {{news_headlines}}
    Social Media Mentions: {{social_mentions}}
    Trading Volume: {{volume_data}}
    Price Action: {{price_movements}}
    Market Context: {{market_context}}
    
    Provide comprehensive sentiment analysis including:
    1. Overall sentiment score (-100 to +100)
    2. Sentiment breakdown by source (news, social, technical)
    3. Key sentiment drivers and catalysts
    4. Sentiment trend direction (improving/deteriorating)
    5. Market psychology assessment
    6. Contrarian indicators and warnings
    7. Actionable insights for traders
    
    Format as structured sentiment report with clear metrics.';
```

**Testing Examples:**
```sql
-- Analyze Bitcoin sentiment during bull market
SELECT sentiment_analysis 
FROM mindsdb.market_sentiment_analyzer 
WHERE news_headlines = 'Bitcoin ETF approval, institutional adoption increasing' 
  AND social_mentions = 'Positive: 75%, Neutral: 15%, Negative: 10%' 
  AND volume_data = 'Volume up 45% from average' 
  AND price_movements = 'BTC +8.5% in 24h, breaking resistance' 
  AND market_context = 'Bull market, low volatility, institutional inflows';

-- Analyze market during regulatory concerns
SELECT sentiment_analysis 
FROM mindsdb.market_sentiment_analyzer 
WHERE news_headlines = 'SEC enforcement action, regulatory uncertainty' 
  AND social_mentions = 'Positive: 25%, Neutral: 30%, Negative: 45%' 
  AND volume_data = 'Volume up 120% from average' 
  AND price_movements = 'Market down 12%, high volatility' 
  AND market_context = 'Bear market, regulatory pressure, risk-off sentiment';
```

**Expected Results:**
```
MARKET SENTIMENT ANALYSIS - BITCOIN

Overall Sentiment Score: +72/100 (BULLISH)

Sentiment Breakdown:
- News Sentiment: +85 (Very Positive - ETF approval catalyst)
- Social Sentiment: +68 (Positive - Community excitement)
- Technical Sentiment: +75 (Strong - Breaking key resistance)

Key Sentiment Drivers:
1. Bitcoin ETF approval creating institutional FOMO
2. Increased corporate adoption announcements
3. Technical breakout above $45,000 resistance
4. Volume surge indicating genuine buying interest

Sentiment Trend: IMPROVING (+15 points from last week)

Market Psychology Assessment:
- Fear & Greed Index: 78 (Extreme Greed)
- Retail participation increasing
- Institutional accumulation phase
- FOMO beginning to emerge

Contrarian Indicators:
⚠️ Extreme greed levels suggest potential short-term pullback
⚠️ Social media euphoria reaching concerning levels

Actionable Insights:
- Strong bullish momentum likely to continue short-term
- Consider taking profits at $48,000-$50,000 resistance
- Watch for volume confirmation on any pullbacks
- Ideal entry on 5-10% dips with strong volume
```

**Use Cases for XplainCrypto:**
- Daily sentiment reports for users
- Trading signal generation based on sentiment
- Market psychology education
- Contrarian trading opportunities
- Risk management alerts

### 2. Technical Analysis Expert

**Purpose:** Provides comprehensive technical analysis including chart patterns, indicators, support/resistance levels, and trading recommendations.

**Creation SQL:**
```sql
CREATE MODEL mindsdb.technical_analysis_expert
PREDICT technical_analysis
USING
    engine = 'anthropic_engine',
    model_name = 'claude-3-opus-20240229',
    temperature = 0.4,
    max_tokens = 1800,
    prompt_template = 'Perform comprehensive technical analysis on:
    
    Symbol: {{symbol}}
    Current Price: ${{current_price}}
    OHLCV Data: {{ohlcv_data}}
    Volume Profile: {{volume_data}}
    Moving Averages: {{ma_data}}
    RSI: {{rsi}}
    MACD: {{macd}}
    Bollinger Bands: {{bb_data}}
    
    Provide detailed technical analysis including:
    1. Trend analysis (short, medium, long-term)
    2. Key support and resistance levels
    3. Chart pattern identification
    4. Technical indicator signals
    5. Volume analysis and confirmation
    6. Entry and exit points with stop losses
    7. Price targets and probability assessments
    8. Risk/reward ratios
    
    Format as professional technical analysis report with specific price levels.';
```

**Testing Examples:**
```sql
-- Analyze Bitcoin technical setup
SELECT technical_analysis 
FROM mindsdb.technical_analysis_expert 
WHERE symbol = 'BTC' 
  AND current_price = '45123.45' 
  AND ohlcv_data = 'O:44800, H:45500, L:44200, C:45123, V:25000' 
  AND volume_data = 'Above average, increasing on rallies' 
  AND ma_data = '20MA:44500, 50MA:43200, 200MA:41800' 
  AND rsi = '58.5' 
  AND macd = 'Bullish crossover, histogram positive' 
  AND bb_data = 'Price near upper band, expanding bands';

-- Analyze Ethereum during consolidation
SELECT technical_analysis 
FROM mindsdb.technical_analysis_expert 
WHERE symbol = 'ETH' 
  AND current_price = '3234.56' 
  AND ohlcv_data = 'O:3220, H:3250, L:3200, C:3234, V:15000' 
  AND volume_data = 'Below average, declining' 
  AND ma_data = '20MA:3225, 50MA:3180, 200MA:3050' 
  AND rsi = '52.3' 
  AND macd = 'Neutral, slight bearish divergence' 
  AND bb_data = 'Price in middle of bands, contracting';
```

**Expected Results:**
```
TECHNICAL ANALYSIS - BITCOIN (BTC)
Current Price: $45,123.45

TREND ANALYSIS:
- Short-term (1-7 days): BULLISH - Above all major MAs
- Medium-term (1-4 weeks): BULLISH - Uptrend intact
- Long-term (3-12 months): BULLISH - Higher highs/lows pattern

KEY LEVELS:
Support Levels:
- Primary: $44,200 (recent low, volume support)
- Secondary: $43,200 (50-day MA)
- Major: $41,800 (200-day MA, psychological)

Resistance Levels:
- Immediate: $45,500 (session high)
- Primary: $46,800 (previous swing high)
- Major: $48,000 (psychological, Fibonacci 61.8%)

CHART PATTERNS:
- Ascending triangle formation (bullish)
- Higher lows pattern since $41,800
- Volume expansion on breakout attempts

TECHNICAL INDICATORS:
- RSI (58.5): Neutral to bullish, room for upside
- MACD: Bullish crossover confirmed, momentum building
- Bollinger Bands: Price near upper band, expansion suggests volatility

VOLUME ANALYSIS:
- Volume above 20-day average (+15%)
- Accumulation pattern on dips
- Breakout volume confirmation needed

TRADING SETUP:
Entry Strategy:
- Aggressive: Current levels ($45,100-$45,200)
- Conservative: Pullback to $44,200-$44,500

Price Targets:
- Target 1: $46,800 (Probability: 70%)
- Target 2: $48,000 (Probability: 45%)
- Target 3: $50,000 (Probability: 25%)

Stop Loss: $43,800 (below 50-day MA)
Risk/Reward Ratio: 1:2.8 (Excellent)

PROBABILITY ASSESSMENT:
- Bullish continuation: 65%
- Sideways consolidation: 25%
- Bearish reversal: 10%
```

**Use Cases for XplainCrypto:**
- Daily technical analysis reports
- Trading signal generation
- Educational content for technical analysis
- Entry/exit point recommendations
- Risk management guidance

### 3. DeFi Protocol Analyzer

**Purpose:** Comprehensive analysis of DeFi protocols including tokenomics, TVL sustainability, yield opportunities, and risk assessment.

**Creation SQL:**
```sql
CREATE MODEL mindsdb.defi_protocol_analyzer
PREDICT defi_analysis
USING
    engine = 'anthropic_engine',
    model_name = 'claude-3-opus-20240229',
    temperature = 0.5,
    max_tokens = 2000,
    prompt_template = 'Analyze DeFi protocol comprehensively:
    
    Protocol Name: {{protocol_name}}
    Category: {{category}}
    TVL: ${{tvl}}
    Token Price: ${{token_price}}
    Market Cap: ${{market_cap}}
    Volume 24h: ${{volume_24h}}
    Active Users: {{active_users}}
    Chains: {{supported_chains}}
    Tokenomics: {{tokenomics_data}}
    Governance: {{governance_info}}
    
    Provide comprehensive DeFi analysis including:
    1. Protocol fundamentals and value proposition
    2. TVL analysis and sustainability assessment
    3. Tokenomics evaluation and token utility
    4. Competitive positioning and moat analysis
    5. Revenue model and fee generation
    6. Risk factors and security considerations
    7. Growth catalysts and roadmap assessment
    8. Investment thesis and price targets
    9. Yield opportunities and strategies
    
    Format as professional DeFi research report with ratings and recommendations.';
```

**Testing Examples:**
```sql
-- Analyze Uniswap V3 protocol
SELECT defi_analysis 
FROM mindsdb.defi_protocol_analyzer 
WHERE protocol_name = 'Uniswap V3' 
  AND category = 'DEX' 
  AND tvl = '5200000000' 
  AND token_price = '6.45' 
  AND market_cap = '4900000000' 
  AND volume_24h = '1200000000' 
  AND active_users = '85000' 
  AND supported_chains = 'Ethereum, Arbitrum, Polygon, Optimism' 
  AND tokenomics_data = 'Total supply: 1B UNI, Governance token, Fee switch potential' 
  AND governance_info = 'Active DAO, regular proposals, community-driven';

-- Analyze AAVE lending protocol
SELECT defi_analysis 
FROM mindsdb.defi_protocol_analyzer 
WHERE protocol_name = 'AAVE V3' 
  AND category = 'Lending' 
  AND tvl = '12800000000' 
  AND token_price = '89.50' 
  AND market_cap = '1340000000' 
  AND volume_24h = '450000000' 
  AND active_users = '52000' 
  AND supported_chains = 'Ethereum, Polygon, Avalanche, Arbitrum, Optimism' 
  AND tokenomics_data = 'Total supply: 16M AAVE, Staking rewards, Safety module' 
  AND governance_info = 'Mature governance, regular AIPs, strong community';
```

**Expected Results:**
```
DEFI PROTOCOL ANALYSIS - UNISWAP V3

PROTOCOL OVERVIEW:
Rating: A+ (Excellent)
Category: Decentralized Exchange (DEX)
Market Position: #1 DEX by volume and TVL

FUNDAMENTALS ASSESSMENT:
Value Proposition: STRONG
- Leading AMM with concentrated liquidity innovation
- Superior capital efficiency vs competitors
- Dominant market share in spot trading
- Strong brand recognition and network effects

TVL ANALYSIS:
Current TVL: $5.2B (Rank #3 overall DeFi)
TVL Sustainability: HIGH
- Stable TVL growth (+8% over 30 days)
- Diversified across multiple chains
- Volume/TVL ratio: 0.23 (healthy utilization)
- Deep liquidity in major trading pairs

TOKENOMICS EVALUATION:
Token Utility: MODERATE (Potential for STRONG)
- Governance rights and voting power
- Fee switch potential (major catalyst)
- No current cash flows to token holders
- Strong community governance participation

Market Metrics:
- Market Cap: $4.9B
- P/S Ratio: 4.1x (based on potential fee revenue)
- Token Distribution: Well distributed, no major concerns

COMPETITIVE POSITIONING:
Market Moat: VERY STRONG
- First-mover advantage in concentrated liquidity
- Network effects and liquidity depth
- Developer ecosystem and integrations
- Brand recognition and trust

Competitive Threats:
- Newer DEXs with better UX (moderate threat)
- CEX competition (low threat)
- L2 native DEXs (moderate threat)

REVENUE MODEL:
Current: Protocol fees (0.05-1% per trade)
Potential: Fee switch activation could direct fees to UNI holders
Annual Revenue: ~$730M (if fee switch activated)

RISK ASSESSMENT:
Technical Risks: LOW
- Battle-tested smart contracts
- Multiple audits and bug bounties
- Strong security track record

Regulatory Risks: MODERATE
- DEX regulation uncertainty
- Potential securities classification of UNI

Market Risks: LOW-MODERATE
- Competition from newer protocols
- Multi-chain fragmentation

GROWTH CATALYSTS:
1. Fee switch activation (HIGH impact)
2. V4 launch with hooks functionality (HIGH impact)
3. Additional chain deployments (MEDIUM impact)
4. Institutional adoption (MEDIUM impact)

INVESTMENT THESIS: BULLISH
Strengths:
✅ Dominant market position
✅ Strong fundamentals and metrics
✅ Potential fee switch catalyst
✅ Multi-chain expansion success

Price Targets (12-month):
- Conservative: $8.50 (+32%)
- Base Case: $12.00 (+86%)
- Bull Case: $18.00 (+179%)

YIELD OPPORTUNITIES:
- LP provision in major pairs: 5-15% APY
- UNI staking (if implemented): 3-8% APY
- Governance participation rewards

RECOMMENDATION: BUY
Risk-adjusted return potential: HIGH
Suitable for: DeFi investors, governance participants
Position sizing: 3-8% of DeFi allocation
```

**Use Cases for XplainCrypto:**
- DeFi protocol research and investment analysis
- Yield farming strategy development
- Risk assessment for DeFi investments
- Educational content about DeFi protocols
- Portfolio allocation recommendations

### 4. Risk Assessment Engine

**Purpose:** Comprehensive risk analysis for cryptocurrencies, portfolios, and trading strategies including market, technical, and fundamental risk factors.

**Creation SQL:**
```sql
CREATE MODEL mindsdb.risk_assessment_engine
PREDICT risk_analysis
USING
    engine = 'anthropic_engine',
    model_name = 'claude-3-sonnet-20240229',
    temperature = 0.2,
    max_tokens = 1600,
    prompt_template = 'Perform comprehensive risk assessment for:
    
    Asset/Portfolio: {{asset_name}}
    Current Position: {{position_details}}
    Market Data: {{market_metrics}}
    Volatility Data: {{volatility_metrics}}
    Correlation Data: {{correlation_data}}
    Liquidity Metrics: {{liquidity_data}}
    Fundamental Factors: {{fundamental_risks}}
    
    Provide detailed risk analysis including:
    1. Overall risk score (1-100 scale)
    2. Risk category breakdown (market, credit, liquidity, operational)
    3. Value at Risk (VaR) calculations
    4. Maximum drawdown scenarios
    5. Correlation and concentration risks
    6. Stress testing results
    7. Risk mitigation recommendations
    8. Position sizing guidelines
    
    Format as professional risk assessment report with quantitative metrics.';
```

**Testing Examples:**
```sql
-- Assess Bitcoin investment risk
SELECT risk_analysis 
FROM mindsdb.risk_assessment_engine 
WHERE asset_name = 'Bitcoin (BTC)' 
  AND position_details = '$100,000 position, 20% of portfolio' 
  AND market_metrics = 'Price: $45,123, Market Cap: $885B, Volume: $25B' 
  AND volatility_metrics = '30-day volatility: 65%, 90-day: 72%' 
  AND correlation_data = 'S&P 500: 0.35, Gold: 0.15, DXY: -0.45' 
  AND liquidity_data = 'High liquidity, $25B daily volume' 
  AND fundamental_risks = 'Regulatory uncertainty, energy concerns';

-- Assess DeFi portfolio risk
SELECT risk_analysis 
FROM mindsdb.risk_assessment_engine 
WHERE asset_name = 'DeFi Portfolio' 
  AND position_details = 'UNI: 30%, AAVE: 25%, COMP: 20%, SUSHI: 15%, CRV: 10%' 
  AND market_metrics = 'Total value: $50,000, 40% of total portfolio' 
  AND volatility_metrics = 'Portfolio volatility: 85%, individual assets 70-120%' 
  AND correlation_data = 'High intra-DeFi correlation: 0.75-0.85' 
  AND liquidity_data = 'Mixed liquidity, some low-cap tokens' 
  AND fundamental_risks = 'Smart contract risk, regulatory risk, competition';
```

**Expected Results:**
```
RISK ASSESSMENT REPORT - BITCOIN (BTC)

OVERALL RISK SCORE: 68/100 (MODERATE-HIGH)

RISK CATEGORY BREAKDOWN:
Market Risk: 75/100 (HIGH)
- High volatility (65% annualized)
- Correlation with risk assets increasing
- Susceptible to macro sentiment shifts

Credit Risk: 15/100 (LOW)
- No counterparty risk (self-custody)
- Network security strong
- Decentralized nature reduces credit exposure

Liquidity Risk: 25/100 (LOW)
- Excellent liquidity ($25B daily volume)
- Deep order books on major exchanges
- Can exit large positions with minimal slippage

Operational Risk: 45/100 (MODERATE)
- Exchange custody risks
- Regulatory uncertainty
- Technical implementation risks

QUANTITATIVE RISK METRICS:
Value at Risk (VaR):
- 1-day VaR (95%): -$4,200 (-4.2%)
- 1-week VaR (95%): -$9,800 (-9.8%)
- 1-month VaR (95%): -$18,500 (-18.5%)

Maximum Drawdown Scenarios:
- Historical max: -84% (2017-2018)
- Stress scenario: -60% (regulatory ban)
- Moderate scenario: -35% (bear market)

CORRELATION ANALYSIS:
Portfolio Impact:
- 20% allocation creates moderate concentration risk
- Correlation with traditional assets increasing
- Diversification benefits diminishing

STRESS TESTING RESULTS:
Scenario 1 - Regulatory Crackdown: -45% impact
Scenario 2 - Market Crash (2008-style): -55% impact
Scenario 3 - Crypto Winter: -70% impact

RISK MITIGATION RECOMMENDATIONS:
1. Reduce position size to 10-15% of portfolio
2. Implement stop-loss at -25% from entry
3. Consider hedging with put options
4. Diversify across other crypto assets
5. Use dollar-cost averaging for entries

POSITION SIZING GUIDELINES:
- Conservative investor: 5-10% allocation
- Moderate investor: 10-15% allocation
- Aggressive investor: 15-25% allocation
- Maximum recommended: 25% of total portfolio

MONITORING RECOMMENDATIONS:
- Daily volatility tracking
- Correlation monitoring with traditional assets
- Regulatory development alerts
- Technical support level monitoring
```

**Use Cases for XplainCrypto:**
- Portfolio risk management
- Position sizing recommendations
- Stress testing and scenario analysis
- Risk education for users
- Compliance and regulatory reporting

### 5. News Impact Predictor

**Purpose:** Analyzes cryptocurrency news and predicts potential market impact, price movements, and trading opportunities.

**Creation SQL:**
```sql
CREATE MODEL mindsdb.news_impact_predictor
PREDICT impact_prediction
USING
    engine = 'anthropic_engine',
    model_name = 'claude-3-sonnet-20240229',
    temperature = 0.3,
    max_tokens = 1400,
    prompt_template = 'Analyze news impact on cryptocurrency markets:
    
    News Headline: {{headline}}
    News Content: {{content}}
    Source Credibility: {{source_rating}}
    Asset Mentioned: {{affected_assets}}
    Market Context: {{market_conditions}}
    Historical Precedent: {{similar_events}}
    
    Predict market impact including:
    1. Impact severity score (1-100)
    2. Price impact direction and magnitude
    3. Time horizon for impact (immediate/short/medium/long)
    4. Affected market sectors and assets
    5. Volume and volatility expectations
    6. Trading strategy recommendations
    7. Risk factors and considerations
    8. Confidence level in predictions
    
    Format as structured news impact prediction with actionable insights.';
```

**Testing Examples:**
```sql
-- Analyze Bitcoin ETF approval news
SELECT impact_prediction 
FROM mindsdb.news_impact_predictor 
WHERE headline = 'SEC Approves First Bitcoin Spot ETF Applications' 
  AND content = 'The Securities and Exchange Commission has approved multiple Bitcoin spot ETF applications from major asset managers...' 
  AND source_rating = 'High credibility - Reuters, Bloomberg confirmation' 
  AND affected_assets = 'BTC, crypto market broadly, ETF providers' 
  AND market_conditions = 'Bull market, high institutional interest, low volatility' 
  AND similar_events = 'Gold ETF approval 2004, Bitcoin futures ETF 2021';

-- Analyze DeFi hack news
SELECT impact_prediction 
FROM mindsdb.news_impact_predictor 
WHERE headline = 'Major DeFi Protocol Suffers $100M Exploit' 
  AND content = 'Leading DeFi lending protocol exploited for $100 million in flash loan attack...' 
  AND source_rating = 'Medium-High - CoinDesk, protocol confirmation' 
  AND affected_assets = 'Protocol token, DeFi sector, lending tokens' 
  AND market_conditions = 'Risk-off sentiment, regulatory scrutiny increasing' 
  AND similar_events = 'Poly Network hack 2021, Ronin bridge hack 2022';
```

**Expected Results:**
```
NEWS IMPACT PREDICTION - BITCOIN ETF APPROVAL

IMPACT SEVERITY SCORE: 92/100 (EXTREMELY HIGH)

PRICE IMPACT PREDICTION:
Direction: STRONGLY BULLISH
Magnitude: +15% to +25% (short-term)
Confidence Level: 85%

Primary Asset Impact (BTC):
- Immediate: +8% to +12% (within 24 hours)
- Short-term: +15% to +25% (1-2 weeks)
- Medium-term: +30% to +50% (1-3 months)

Secondary Asset Impact:
- ETH: +10% to +18% (correlation play)
- Major altcoins: +5% to +15% (rising tide effect)
- DeFi tokens: +8% to +20% (institutional adoption)

TIME HORIZON ANALYSIS:
Immediate (0-24 hours): VERY HIGH impact
- Gap up at market open
- Volume surge expected (+200-400%)
- FOMO buying from retail and institutions

Short-term (1-2 weeks): HIGH impact
- Sustained buying pressure
- Media coverage amplification
- Institutional allocation beginning

Medium-term (1-3 months): MODERATE-HIGH impact
- ETF inflows driving demand
- Supply shock as coins move to ETF custody
- Mainstream adoption acceleration

VOLUME & VOLATILITY EXPECTATIONS:
Trading Volume: +300% to +500% above average
Volatility: Increased short-term, stabilizing medium-term
Options Activity: Massive call buying expected

AFFECTED SECTORS:
1. Bitcoin and major cryptocurrencies (VERY POSITIVE)
2. Crypto exchanges (POSITIVE - increased volume)
3. Mining stocks (POSITIVE - increased demand)
4. Traditional finance ETF providers (POSITIVE)

TRADING STRATEGY RECOMMENDATIONS:
Immediate Actions:
- Long BTC with tight stops
- Buy call options on crypto stocks
- Avoid shorting crypto assets

Risk Management:
- Take profits at +20-25% levels
- Watch for profit-taking after initial surge
- Monitor regulatory response

RISK FACTORS:
- Potential "buy the rumor, sell the news" reaction
- Regulatory backlash or reversal
- Technical resistance at key levels
- Profit-taking from long-term holders

HISTORICAL PRECEDENT ANALYSIS:
Similar to Gold ETF approval (2004):
- Initial surge of +12% in gold
- Sustained bull market for 4+ years
- Institutional adoption accelerated

CONFIDENCE ASSESSMENT:
Prediction Confidence: 85%
- Strong historical precedent
- Clear fundamental catalyst
- Broad market implications
- High-quality news sources

MONITORING RECOMMENDATIONS:
- Track ETF inflow data
- Monitor institutional announcements
- Watch for regulatory responses
- Follow technical resistance levels
```

**Use Cases for XplainCrypto:**
- Automated news impact analysis
- Trading alert generation
- Market timing strategies
- Risk management for news events
- Educational content about market catalysts

### 6. Portfolio Optimizer

**Purpose:** Advanced portfolio optimization using modern portfolio theory, risk-adjusted returns, and cryptocurrency-specific factors.

**Creation SQL:**
```sql
CREATE MODEL mindsdb.portfolio_optimizer
PREDICT optimization_strategy
USING
    engine = 'anthropic_engine',
    model_name = 'claude-3-opus-20240229',
    temperature = 0.4,
    max_tokens = 2200,
    prompt_template = 'Optimize cryptocurrency portfolio based on:
    
    Current Holdings: {{current_portfolio}}
    Available Capital: ${{available_capital}}
    Risk Tolerance: {{risk_tolerance}}
    Investment Horizon: {{time_horizon}}
    Investment Goals: {{investment_objectives}}
    Market Outlook: {{market_conditions}}
    Correlation Matrix: {{correlation_data}}
    Expected Returns: {{return_expectations}}
    
    Provide comprehensive portfolio optimization including:
    1. Optimal asset allocation percentages
    2. Rebalancing recommendations with rationale
    3. Risk-adjusted return projections
    4. Diversification analysis and improvements
    5. Correlation and concentration risk assessment
    6. Implementation strategy and timeline
    7. Performance monitoring guidelines
    8. Stress testing and scenario analysis
    
    Format as professional portfolio optimization report with specific allocations.';
```

**Testing Examples:**
```sql
-- Optimize conservative crypto portfolio
SELECT optimization_strategy 
FROM mindsdb.portfolio_optimizer 
WHERE current_portfolio = 'BTC: 60% ($30k), ETH: 30% ($15k), USDC: 10% ($5k)' 
  AND available_capital = '25000' 
  AND risk_tolerance = 'Conservative - capital preservation priority' 
  AND time_horizon = '2-3 years' 
  AND investment_objectives = 'Steady growth with downside protection' 
  AND market_conditions = 'Bull market but high volatility expected' 
  AND correlation_data = 'BTC-ETH: 0.75, BTC-USDC: 0.05, ETH-USDC: 0.03' 
  AND return_expectations = 'BTC: 25% annually, ETH: 35%, USDC: 5%';

-- Optimize aggressive DeFi portfolio
SELECT optimization_strategy 
FROM mindsdb.portfolio_optimizer 
WHERE current_portfolio = 'UNI: 25% ($12.5k), AAVE: 20% ($10k), COMP: 15% ($7.5k), SUSHI: 15% ($7.5k), CRV: 10% ($5k), LINK: 15% ($7.5k)' 
  AND available_capital = '50000' 
  AND risk_tolerance = 'Aggressive - high growth seeking' 
  AND time_horizon = '1-2 years' 
  AND investment_objectives = 'Maximum returns, DeFi exposure' 
  AND market_conditions = 'DeFi summer potential, high innovation' 
  AND correlation_data = 'High DeFi correlation: 0.70-0.85 average' 
  AND return_expectations = 'DeFi tokens: 50-150% potential, high volatility';
```

**Expected Results:**
```
PORTFOLIO OPTIMIZATION REPORT - CONSERVATIVE CRYPTO STRATEGY

CURRENT PORTFOLIO ANALYSIS:
Total Value: $50,000
Current Allocation: BTC 60%, ETH 30%, USDC 10%
Risk Level: MODERATE (could be more conservative)
Sharpe Ratio: 1.24 (good but improvable)

OPTIMAL ALLOCATION RECOMMENDATION:
Target Portfolio Value: $75,000 (including new capital)

Recommended Allocation:
1. Bitcoin (BTC): 45% ($33,750) - REDUCE from 60%
2. Ethereum (ETH): 25% ($18,750) - REDUCE from 30%
3. Stablecoins (USDC/USDT): 15% ($11,250) - INCREASE from 10%
4. Large Cap Alts: 10% ($7,500) - NEW ADDITION
   - Binance Coin (BNB): 5% ($3,750)
   - Cardano (ADA): 5% ($3,750)
5. Conservative DeFi: 5% ($3,750) - NEW ADDITION
   - AAVE: 3% ($2,250)
   - Compound (COMP): 2% ($1,500)

REBALANCING STRATEGY:
Phase 1 (Immediate):
- Reduce BTC position by $8,750 (sell 15%)
- Reduce ETH position by $3,750 (sell 12.5%)
- Increase stablecoin allocation by $6,250
- Add $7,500 in large-cap alternatives

Phase 2 (Next 30 days):
- Dollar-cost average into DeFi positions
- Monitor correlation changes
- Adjust based on market conditions

RISK-ADJUSTED PROJECTIONS:
Expected Annual Return: 28% (vs 31% current)
Expected Volatility: 52% (vs 68% current)
Improved Sharpe Ratio: 1.54 (vs 1.24 current)
Maximum Drawdown: -35% (vs -48% current)

DIVERSIFICATION IMPROVEMENTS:
Current Correlation Risk: HIGH (BTC-ETH 0.75)
Optimized Correlation Risk: MODERATE
- Reduced concentration in top 2 assets
- Added uncorrelated stablecoin allocation
- Introduced alternative L1 exposure

RISK ASSESSMENT:
Value at Risk (95%, 30-day): -$8,750 (vs -$12,000 current)
Concentration Risk: IMPROVED (no single asset >45%)
Liquidity Risk: LOW (all assets highly liquid)

IMPLEMENTATION TIMELINE:
Week 1: Execute Phase 1 rebalancing
Week 2-4: DCA into new positions
Month 2: Performance review and adjustments
Quarterly: Full rebalancing review

PERFORMANCE MONITORING:
Key Metrics to Track:
- Portfolio correlation with BTC (target: <0.85)
- Sharpe ratio maintenance (target: >1.4)
- Maximum drawdown control (target: <40%)
- Rebalancing triggers: ±5% from target allocation

STRESS TESTING SCENARIOS:
Bear Market (-50% crypto): Portfolio impact -35%
Regulatory Crackdown: Portfolio impact -28%
DeFi Crisis: Portfolio impact -15%
Stablecoin Depeg: Portfolio impact -8%

ADVANTAGES OF OPTIMIZED PORTFOLIO:
✅ Reduced volatility while maintaining growth
✅ Better risk-adjusted returns
✅ Improved diversification
✅ Downside protection through stablecoins
✅ Exposure to emerging DeFi opportunities

MONITORING SCHEDULE:
- Daily: Price and allocation tracking
- Weekly: Correlation analysis
- Monthly: Performance review and rebalancing
- Quarterly: Strategy reassessment

NEXT REVIEW DATE: October 17, 2025
```

**Use Cases for XplainCrypto:**
- Personalized portfolio optimization
- Risk-adjusted investment strategies
- Rebalancing recommendations
- Diversification analysis
- Performance optimization

### 7. Yield Farming Strategist

**Purpose:** Identifies and analyzes yield farming opportunities across DeFi protocols with risk assessment and strategy optimization.

**Creation SQL:**
```sql
CREATE MODEL mindsdb.yield_farming_strategist
PREDICT yield_strategy
USING
    engine = 'anthropic_engine',
    model_name = 'claude-3-sonnet-20240229',
    temperature = 0.6,
    max_tokens = 1800,
    prompt_template = 'Analyze yield farming opportunities and create strategy:
    
    Available Capital: ${{capital_amount}}
    Risk Tolerance: {{risk_level}}
    Time Commitment: {{time_horizon}}
    Preferred Chains: {{blockchain_preference}}
    Current DeFi Holdings: {{current_positions}}
    Market Conditions: {{defi_market_state}}
    
    Available Opportunities:
    {{yield_opportunities}}
    
    Provide comprehensive yield farming strategy including:
    1. Top yield opportunities ranking with risk assessment
    2. Optimal capital allocation across protocols
    3. Risk-adjusted yield calculations
    4. Impermanent loss analysis and mitigation
    5. Gas cost optimization strategies
    6. Entry and exit timing recommendations
    7. Monitoring and management guidelines
    8. Emergency exit procedures
    
    Format as actionable yield farming strategy with specific allocations.';
```

**Testing Examples:**
```sql
-- Analyze yield farming strategy for moderate risk investor
SELECT yield_strategy 
FROM mindsdb.yield_farming_strategist 
WHERE capital_amount = '100000' 
  AND risk_level = 'Moderate - balanced risk/reward' 
  AND time_horizon = '6-12 months active management' 
  AND blockchain_preference = 'Ethereum, Arbitrum, Polygon' 
  AND current_positions = 'ETH: $40k, USDC: $30k, AAVE: $15k, UNI: $15k' 
  AND defi_market_state = 'Bull market, high yields available, moderate risk' 
  AND yield_opportunities = 'Curve 3pool: 8.5% APY, Uniswap V3 ETH/USDC: 12% APY, AAVE lending: 6% APY, Compound: 5.5% APY, Convex: 15% APY';
```

**Expected Results:**
```
YIELD FARMING STRATEGY - MODERATE RISK PROFILE

CAPITAL ALLOCATION: $100,000
Target Yield: 12-18% APY (risk-adjusted)
Strategy Duration: 6-12 months

OPTIMAL ALLOCATION STRATEGY:

Tier 1 - Low Risk (40% allocation - $40,000):
1. AAVE Lending (20% - $20,000)
   - Asset: USDC lending
   - APY: 6.2% + AAVE rewards
   - Risk: LOW - established protocol
   - Liquidity: HIGH - instant withdrawal

2. Compound Lending (20% - $20,000)
   - Asset: ETH lending
   - APY: 5.8% + COMP rewards
   - Risk: LOW - battle-tested protocol
   - Liquidity: HIGH - instant withdrawal

Tier 2 - Moderate Risk (45% allocation - $45,000):
3. Uniswap V3 LP (25% - $25,000)
   - Pair: ETH/USDC (0.05% fee tier)
   - APY: 12-18% (fees + rewards)
   - Risk: MODERATE - impermanent loss risk
   - Management: Active range management required

4. Curve 3pool + Convex (20% - $20,000)
   - Pool: USDC/USDT/DAI
   - APY: 8.5% base + 6.5% CRV/CVX rewards = 15%
   - Risk: MODERATE - stablecoin exposure
   - Liquidity: HIGH - large pool

Tier 3 - Higher Risk (15% allocation - $15,000):
5. Arbitrum Native Protocols (15% - $15,000)
   - GMX: $7,500 (GLP staking - 18% APY)
   - Radiant: $7,500 (RDNT farming - 25% APY)
   - Risk: HIGHER - newer protocols, token rewards
   - Potential: HIGH upside with L2 growth

RISK ANALYSIS BY POSITION:

Impermanent Loss Assessment:
- Uniswap V3 ETH/USDC: Moderate risk (ETH volatility)
- Mitigation: Tight range management, regular rebalancing
- Expected IL: 2-5% in moderate volatility scenarios

Smart Contract Risk:
- AAVE/Compound: VERY LOW (battle-tested)
- Uniswap V3: LOW (audited, high TVL)
- Curve/Convex: LOW-MODERATE (complex but proven)
- Arbitrum protocols: MODERATE (newer, smaller TVL)

Token Risk Assessment:
- Stablecoin exposure: 60% (USDC/USDT/DAI)
- ETH exposure: 25% (direct + LP)
- Governance tokens: 15% (reward tokens)

IMPLEMENTATION STRATEGY:

Phase 1 (Week 1):
- Deploy $40k to AAVE and Compound (low-risk base)
- Begin with conservative positions
- Monitor gas costs and optimize timing

Phase 2 (Week 2-3):
- Add Uniswap V3 position with tight ranges
- Deploy Curve/Convex strategy
- Set up monitoring and alerts

Phase 3 (Week 4):
- Add Arbitrum positions gradually
- Optimize cross-chain strategies
- Implement automated management tools

GAS OPTIMIZATION STRATEGIES:
- Batch transactions during low gas periods
- Use L2 solutions (Arbitrum/Polygon) for smaller positions
- Implement gas price alerts and automation
- Consider gas costs in yield calculations

MONITORING REQUIREMENTS:

Daily Monitoring:
- Uniswap V3 range efficiency
- Yield rates and reward distributions
- Gas price optimization opportunities

Weekly Monitoring:
- Impermanent loss tracking
- Protocol health and TVL changes
- Reward token price movements

Monthly Monitoring:
- Strategy performance review
- Rebalancing opportunities
- Risk assessment updates

PERFORMANCE TARGETS:

Conservative Scenario: 10-12% APY
Base Case Scenario: 14-16% APY
Optimistic Scenario: 18-22% APY

Risk-Adjusted Target: 13-15% APY
Maximum Acceptable Loss: -8% (stress scenario)

EMERGENCY EXIT PROCEDURES:

Immediate Exit Triggers:
- Protocol exploit or security breach
- Significant impermanent loss (>10%)
- Regulatory concerns
- Market crash (>30% decline)

Exit Priority:
1. Highest risk positions first (Arbitrum protocols)
2. Preserve stablecoin positions
3. Maintain core ETH exposure
4. Emergency liquidity via AAVE/Compound

EXPECTED OUTCOMES:

Monthly Yield: $1,200-$1,500
Annual Yield: $14,000-$18,000
Time Investment: 5-10 hours/week management
Risk Level: Moderate (appropriate for profile)

SUCCESS METRICS:
- Achieve >13% risk-adjusted APY
- Maintain <5% maximum drawdown
- Outperform simple HODLing by 8%+
- Minimize impermanent loss to <3%
```

**Use Cases for XplainCrypto:**
- Yield farming strategy development
- DeFi opportunity analysis
- Risk-adjusted yield optimization
- Portfolio diversification into DeFi
- Educational content about yield farming

### 8. Crypto Tax Optimizer

**Purpose:** Analyzes cryptocurrency transactions for tax optimization opportunities including tax-loss harvesting, holding period optimization, and compliance strategies.

**Creation SQL:**
```sql
CREATE MODEL mindsdb.crypto_tax_optimizer
PREDICT tax_strategy
USING
    engine = 'anthropic_engine',
    model_name = 'claude-3-sonnet-20240229',
    temperature = 0.2,
    max_tokens = 1600,
    prompt_template = 'Analyze cryptocurrency tax situation and optimize:
    
    Transaction History: {{transaction_data}}
    Current Holdings: {{current_positions}}
    Tax Jurisdiction: {{tax_country}}
    Income Level: {{tax_bracket}}
    Investment Goals: {{investment_objectives}}
    Tax Year: {{tax_year}}
    
    Provide comprehensive tax optimization including:
    1. Current tax liability assessment
    2. Tax-loss harvesting opportunities
    3. Holding period optimization strategies
    4. Wash sale rule considerations
    5. FIFO vs LIFO method analysis
    6. Staking and DeFi tax implications
    7. Record keeping recommendations
    8. Year-end tax planning strategies
    
    Format as actionable tax optimization plan with specific recommendations.';
```

**Testing Examples:**
```sql
-- Analyze tax optimization for US investor
SELECT tax_strategy 
FROM mindsdb.crypto_tax_optimizer 
WHERE transaction_data = 'BTC bought $30k (Jan), sold $45k (Nov), ETH bought $20k (Mar), current value $18k' 
  AND current_positions = 'BTC: $50k unrealized gain, ETH: $18k (-$2k loss), ADA: $15k (+$5k gain)' 
  AND tax_country = 'United States' 
  AND tax_bracket = '24% federal, 6% state' 
  AND investment_objectives = 'Long-term growth, tax efficiency' 
  AND tax_year = '2025';
```

**Expected Results:**
```
CRYPTO TAX OPTIMIZATION STRATEGY - 2025

CURRENT TAX LIABILITY ASSESSMENT:
Realized Gains: $15,000 (BTC sale)
Tax Owed: $4,500 (30% effective rate)
Unrealized Gains: $53,000 total
Potential Future Tax: $15,900

TAX-LOSS HARVESTING OPPORTUNITIES:

Immediate Opportunities:
1. Ethereum Position (Priority: HIGH)
   - Current Loss: -$2,000
   - Tax Savings: $600 (30% rate)
   - Action: Sell and immediately rebuy (no wash sale for crypto)
   - Timing: Before December 31, 2025

2. Underperforming Altcoins:
   - Review positions with <-10% performance
   - Harvest losses while maintaining exposure
   - Estimated additional savings: $300-$800

HOLDING PERIOD OPTIMIZATION:

Current Analysis:
- BTC position: 11 months held (approaching long-term)
- ETH position: 8 months held
- ADA position: 6 months held

Recommendations:
1. Hold BTC position until 12+ months for long-term rates
2. Consider partial ETH sale for loss harvesting
3. Delay ADA sales until long-term qualification

WASH SALE CONSIDERATIONS:
✅ Crypto-to-crypto: No wash sale rules apply
✅ Can immediately rebuy after loss harvesting
✅ Maintain market exposure while optimizing taxes

ACCOUNTING METHOD ANALYSIS:

FIFO vs LIFO Comparison:
Current Method: FIFO
- Tax liability: $4,500
- Remaining basis: Higher

LIFO Alternative:
- Potential tax liability: $3,200
- Tax savings: $1,300
- Recommendation: Consider LIFO election

STAKING AND DEFI TAX IMPLICATIONS:

Current Exposure Assessment:
- Staking rewards: Taxable as ordinary income
- DeFi yields: Taxable as received
- LP tokens: Complex tax treatment

Optimization Strategies:
1. Time staking reward claims for lower income years
2. Consider tax-advantaged accounts for staking
3. Track DeFi transactions meticulously

YEAR-END TAX PLANNING:

December Action Items:
1. Execute ETH loss harvesting: Save $600
2. Review all positions for additional losses
3. Consider Roth IRA conversion opportunities
4. Optimize staking reward timing

2026 Planning:
- Plan BTC position management for long-term rates
- Consider geographic arbitrage strategies
- Evaluate tax-loss carryforward utilization

RECORD KEEPING RECOMMENDATIONS:

Essential Documentation:
✅ All transaction records with timestamps
✅ Cost basis tracking for each purchase
✅ Staking and DeFi reward documentation
✅ Exchange statements and confirmations

Recommended Tools:
- CoinTracker or Koinly for automated tracking
- Separate wallets for different tax strategies
- Regular backup of transaction data

COMPLIANCE STRATEGIES:

Reporting Requirements:
- Form 8949 for capital gains/losses
- Schedule D for summary
- Form 1040 reporting
- FBAR if foreign exchange accounts >$10k

Audit Protection:
- Maintain detailed records
- Use consistent accounting methods
- Document business vs investment activities
- Consider professional tax preparation

PROJECTED TAX SAVINGS:

Immediate Savings (2025):
- Loss harvesting: $600
- Method optimization: $1,300
- Total savings: $1,900

Long-term Savings (2026+):
- Long-term capital gains rates: $2,400
- Continued optimization: $800/year
- Total projected: $3,200+

IMPLEMENTATION TIMELINE:

Week 1: Execute loss harvesting trades
Week 2: Implement accounting method changes
Week 3: Optimize staking reward timing
Week 4: Finalize year-end documentation

RISK CONSIDERATIONS:
- Tax law changes
- Audit risk with aggressive strategies
- Market timing risks
- Compliance complexity

PROFESSIONAL CONSULTATION:
Recommend CPA consultation for:
- Complex DeFi transactions
- Business vs investment classification
- Multi-jurisdiction issues
- Audit representation needs
```

**Use Cases for XplainCrypto:**
- Tax optimization guidance for users
- Year-end tax planning strategies
- Compliance education and tools
- Transaction tracking recommendations
- Professional tax service referrals

---

## Jobs (Automation)

### 1. Daily Market Sync Job

**Purpose:** Automatically synchronizes market data from all handlers and updates the crypto_data database with latest prices, volumes, and market metrics.

**Creation SQL:**
```sql
CREATE JOB daily_market_sync (
    -- Sync CoinMarketCap data
    INSERT INTO crypto_data.price_history 
    SELECT 
        uuid_generate_v4() as price_id,
        symbol,
        quote.USD.price as price_usd,
        quote.USD.market_cap as market_cap,
        quote.USD.volume_24h as volume_24h,
        NOW() as timestamp,
        'coinmarketcap' as data_source
    FROM coinmarketcap_datasource.listings 
    WHERE quote.USD.market_cap > 1000000;
    
    -- Sync DeFiLlama protocol data
    INSERT INTO crypto_data.defi_protocols 
    SELECT 
        uuid_generate_v4() as protocol_id,
        name,
        tvl,
        category,
        chains,
        NOW() as updated_at
    FROM defillama_datasource.protocols 
    WHERE tvl > 10000000;
    
    -- Sync Binance trading data
    INSERT INTO crypto_data.trading_data 
    SELECT 
        uuid_generate_v4() as trade_id,
        symbol,
        price,
        volume,
        priceChangePercent as change_24h,
        NOW() as timestamp,
        'binance' as data_source
    FROM binance_datasource.ticker_24hr 
    WHERE volume > 1000000;
)
START '2025-07-17 00:00:00'
EVERY 1 day
END '2026-07-17 00:00:00';
```

**Testing Examples:**
```sql
-- Check job status
SELECT * FROM information_schema.jobs 
WHERE name = 'daily_market_sync';

-- View recent job executions
SELECT * FROM information_schema.jobs_history 
WHERE job_name = 'daily_market_sync' 
ORDER BY start_at DESC 
LIMIT 10;

-- Verify data synchronization
SELECT 
    data_source,
    COUNT(*) as records_synced,
    MAX(timestamp) as last_sync
FROM crypto_data.price_history 
WHERE timestamp > NOW() - INTERVAL '1 day'
GROUP BY data_source;
```

**Expected Results:**
```
data_source | records_synced | last_sync
coinmarketcap | 2847 | 2025-07-17 00:05:23
binance | 1256 | 2025-07-17 00:06:45
defillama | 892 | 2025-07-17 00:07:12
```

**Use Cases for XplainCrypto:**
- Automated data pipeline maintenance
- Consistent market data availability
- Reduced manual data management
- Real-time dashboard updates
- Historical data preservation

### 2. Anomaly Detection Monitor

**Purpose:** Continuously monitors cryptocurrency markets for anomalies and unusual patterns, generating alerts for significant events.

**Creation SQL:**
```sql
CREATE JOB anomaly_detection_monitor (
    INSERT INTO user_data.notifications (
        notification_id,
        user_id,
        notification_type,
        title,
        message,
        data,
        delivery_method,
        created_at
    )
    SELECT 
        uuid_generate_v4(),
        u.user_id,
        'anomaly_alert',
        CONCAT('Anomaly Detected: ', analysis.symbol),
        analysis.anomaly_alert,
        JSON_BUILD_OBJECT(
            'symbol', analysis.symbol,
            'severity', analysis.severity,
            'timestamp', NOW()
        ),
        'in_app',
        NOW()
    FROM (
        SELECT 
            symbol,
            anomaly_alert,
            CASE 
                WHEN anomaly_alert LIKE '%HIGH%' THEN 'high'
                WHEN anomaly_alert LIKE '%MEDIUM%' THEN 'medium'
                ELSE 'low'
            END as severity
        FROM mindsdb.anomaly_detection_agent 
        WHERE symbol IN (
            SELECT DISTINCT symbol 
            FROM crypto_data.price_history 
            WHERE timestamp > NOW() - INTERVAL '1 hour'
        )
    ) analysis
    CROSS JOIN user_data.users u
    WHERE u.notification_preferences->>'anomaly_alerts' = 'true'
      AND analysis.severity IN ('high', 'medium');
)
START NOW
EVERY 1 hour;
```

**Testing Examples:**
```sql
-- Monitor job performance
SELECT 
    job_name,
    status,
    start_at,
    end_at,
    error_message
FROM information_schema.jobs_history 
WHERE job_name = 'anomaly_detection_monitor'
ORDER BY start_at DESC 
LIMIT 5;

-- Check generated alerts
SELECT 
    title,
    message,
    data->>'severity' as severity,
    created_at
FROM user_data.notifications 
WHERE notification_type = 'anomaly_alert'
  AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;
```

**Expected Results:**
```
title | message | severity | created_at
Anomaly Detected: BTC | ANOMALY ALERT - HIGH SEVERITY... | high | 2025-07-17 10:30:00
Anomaly Detected: ETH | Volume spike detected... | medium | 2025-07-17 09:45:00
```

**Use Cases for XplainCrypto:**
- Real-time market monitoring
- Automated user notifications
- Risk management alerts
- Trading opportunity identification
- Market manipulation detection

### 3. Portfolio Performance Tracker

**Purpose:** Regularly calculates and updates portfolio performance metrics, P&L, and generates performance reports for users.

**Creation SQL:**
```sql
CREATE JOB portfolio_performance_tracker (
    -- Update portfolio holdings with current prices
    UPDATE user_data.portfolio_holdings ph
    SET 
        current_price = cd.price_usd,
        current_value = ph.quantity * cd.price_usd,
        unrealized_pnl = (ph.quantity * cd.price_usd) - ph.total_invested,
        unrealized_pnl_percentage = 
            CASE 
                WHEN ph.total_invested > 0 
                THEN ((ph.quantity * cd.price_usd) - ph.total_invested) / ph.total_invested * 100
                ELSE 0 
            END,
        last_updated = NOW()
    FROM (
        SELECT DISTINCT ON (symbol) 
            symbol, 
            price_usd 
        FROM crypto_data.price_history 
        WHERE timestamp > NOW() - INTERVAL '1 hour'
        ORDER BY symbol, timestamp DESC
    ) cd
    JOIN user_data.crypto_assets ca ON cd.symbol = ca.symbol
    WHERE ph.asset_id = ca.asset_id;
    
    -- Update portfolio totals
    UPDATE user_data.portfolios p
    SET 
        total_value_usd = ph_summary.total_value,
        total_pnl_usd = ph_summary.total_pnl,
        total_pnl_percentage = 
            CASE 
                WHEN p.total_invested_usd > 0 
                THEN ph_summary.total_pnl / p.total_invested_usd * 100
                ELSE 0 
            END,
        updated_at = NOW()
    FROM (
        SELECT 
            portfolio_id,
            SUM(current_value) as total_value,
            SUM(unrealized_pnl) as total_pnl
        FROM user_data.portfolio_holdings
        GROUP BY portfolio_id
    ) ph_summary
    WHERE p.portfolio_id = ph_summary.portfolio_id;
    
    -- Generate performance analytics
    INSERT INTO user_data.user_analytics (
        analytics_id,
        user_id,
        metric_name,
        metric_value,
        metric_data,
        period_start,
        period_end,
        calculated_at
    )
    SELECT 
        uuid_generate_v4(),
        p.user_id,
        'portfolio_performance_24h',
        p.total_pnl_percentage,
        JSON_BUILD_OBJECT(
            'total_value', p.total_value_usd,
            'total_pnl', p.total_pnl_usd,
            'portfolio_count', COUNT(*)
        ),
        NOW() - INTERVAL '24 hours',
        NOW(),
        NOW()
    FROM user_data.portfolios p
    GROUP BY p.user_id, p.total_pnl_percentage, p.total_value_usd, p.total_pnl_usd;
)
START NOW
EVERY 4 hours;
```

**Testing Examples:**
```sql
-- Check portfolio updates
SELECT 
    p.name,
    p.total_value_usd,
    p.total_pnl_usd,
    p.total_pnl_percentage,
    p.updated_at
FROM user_data.portfolios p
JOIN user_data.users u ON p.user_id = u.user_id
WHERE u.username = 'crypto_trader_123'
ORDER BY p.updated_at DESC;

-- View performance analytics
SELECT 
    metric_name,
    metric_value,
    metric_data,
    calculated_at
FROM user_data.user_analytics ua
JOIN user_data.users u ON ua.user_id = u.user_id
WHERE u.username = 'crypto_trader_123'
  AND metric_name = 'portfolio_performance_24h'
ORDER BY calculated_at DESC
LIMIT 5;
```

**Expected Results:**
```
name | total_value_usd | total_pnl_usd | total_pnl_percentage | updated_at
Main Portfolio | 125000.50 | 25000.50 | 25.00 | 2025-07-17 10:30:00
DeFi Portfolio | 45000.25 | -2000.75 | -4.25 | 2025-07-17 10:30:00
```

**Use Cases for XplainCrypto:**
- Automated portfolio tracking
- Performance analytics generation
- Real-time P&L calculations
- User dashboard updates
- Performance reporting

### 4. News Impact Analysis Job

**Purpose:** Automatically analyzes cryptocurrency news and generates impact assessments for relevant market events.

**Creation SQL:**
```sql
CREATE JOB news_impact_analysis (
    INSERT INTO user_data.news_articles (
        article_id,
        title,
        content,
        summary,
        source,
        mentioned_assets,
        sentiment_score,
        created_at
    )
    WITH news_analysis AS (
        SELECT 
            headline,
            content,
            source,
            impact_prediction
        FROM mindsdb.news_impact_predictor
        WHERE headline IN (
            SELECT title FROM external_news_feed 
            WHERE created_at > NOW() - INTERVAL '1 hour'
              AND (title ILIKE '%bitcoin%' 
                   OR title ILIKE '%ethereum%' 
                   OR title ILIKE '%crypto%'
                   OR title ILIKE '%defi%')
        )
    )
    SELECT 
        uuid_generate_v4(),
        na.headline,
        na.content,
        SUBSTRING(na.impact_prediction, 1, 500),
        na.source,
        ARRAY['BTC', 'ETH'], -- Extract from content
        CASE 
            WHEN na.impact_prediction ILIKE '%bullish%' THEN 0.7
            WHEN na.impact_prediction ILIKE '%bearish%' THEN -0.7
            ELSE 0.0
        END,
        NOW()
    FROM news_analysis na;
    
    -- Generate user notifications for high-impact news
    INSERT INTO user_data.notifications (
        notification_id,
        user_id,
        notification_type,
        title,
        message,
        delivery_method,
        created_at
    )
    SELECT 
        uuid_generate_v4(),
        u.user_id,
        'news_alert',
        CONCAT('High Impact News: ', na.title),
        CONCAT('Market impact detected: ', na.summary),
        'in_app',
        NOW()
    FROM user_data.news_articles na
    CROSS JOIN user_data.users u
    WHERE na.created_at > NOW() - INTERVAL '1 hour'
      AND ABS(na.sentiment_score) > 0.6
      AND u.notification_preferences->>'news_alerts' = 'true';
)
START NOW
EVERY 30 minutes;
```

**Use Cases for XplainCrypto:**
- Automated news monitoring
- Market impact assessment
- User notification generation
- Sentiment tracking
- Trading signal generation

---

## Skills

### 1. Price Data Retrieval Skill

**Purpose:** Efficiently retrieves current and historical price data for cryptocurrencies from multiple sources.

**Creation SQL:**
```sql
CREATE SKILL get_crypto_price (
    symbol TEXT,
    timeframe TEXT DEFAULT '24h',
    source TEXT DEFAULT 'all'
) AS (
    WITH price_data AS (
        SELECT 
            symbol,
            price_usd,
            market_cap,
            volume_24h,
            timestamp,
            data_source,
            ROW_NUMBER() OVER (PARTITION BY data_source ORDER BY timestamp DESC) as rn
        FROM crypto_data.price_history 
        WHERE symbol = get_crypto_price.symbol
          AND (get_crypto_price.source = 'all' OR data_source = get_crypto_price.source)
          AND timestamp > NOW() - CASE 
              WHEN get_crypto_price.timeframe = '1h' THEN INTERVAL '1 hour'
              WHEN get_crypto_price.timeframe = '24h' THEN INTERVAL '24 hours'
              WHEN get_crypto_price.timeframe = '7d' THEN INTERVAL '7 days'
              ELSE INTERVAL '24 hours'
          END
    )
    SELECT 
        symbol,
        AVG(price_usd) as avg_price,
        MAX(price_usd) as high_price,
        MIN(price_usd) as low_price,
        SUM(volume_24h) as total_volume,
        COUNT(DISTINCT data_source) as source_count,
        MAX(timestamp) as last_updated
    FROM price_data 
    WHERE rn = 1
    GROUP BY symbol
);
```

**Testing Examples:**
```sql
-- Get Bitcoin price from all sources
SELECT * FROM get_crypto_price('BTC');

-- Get Ethereum price from specific source
SELECT * FROM get_crypto_price('ETH', '24h', 'coinmarketcap');

-- Get weekly price data for multiple assets
SELECT * FROM get_crypto_price('ADA', '7d');
```

**Expected Results:**
```
symbol | avg_price | high_price | low_price | total_volume | source_count | last_updated
BTC | 45123.45 | 45500.00 | 44800.00 | 75000000000 | 3 | 2025-07-17 10:30:00
```

**Use Cases for XplainCrypto:**
- Real-time price displays
- Portfolio valuation
- Trading decision support
- Price alert systems
- Historical analysis

### 2. Portfolio Analysis Skill

**Purpose:** Comprehensive portfolio analysis including performance metrics, risk assessment, and optimization suggestions.

**Creation SQL:**
```sql
CREATE SKILL analyze_portfolio (
    user_id UUID,
    portfolio_id UUID DEFAULT NULL,
    analysis_type TEXT DEFAULT 'comprehensive'
) AS (
    WITH portfolio_data AS (
        SELECT 
            p.portfolio_id,
            p.name as portfolio_name,
            p.total_value_usd,
            p.total_invested_usd,
            p.total_pnl_usd,
            p.total_pnl_percentage,
            ph.asset_id,
            ca.symbol,
            ca.name as asset_name,
            ph.quantity,
            ph.current_price,
            ph.current_value,
            ph.unrealized_pnl,
            ph.unrealized_pnl_percentage,
            (ph.current_value / p.total_value_usd * 100) as allocation_percentage
        FROM user_data.portfolios p
        JOIN user_data.portfolio_holdings ph ON p.portfolio_id = ph.portfolio_id
        JOIN user_data.crypto_assets ca ON ph.asset_id = ca.asset_id
        WHERE p.user_id = analyze_portfolio.user_id
          AND (analyze_portfolio.portfolio_id IS NULL OR p.portfolio_id = analyze_portfolio.portfolio_id)
    ),
    risk_metrics AS (
        SELECT 
            portfolio_id,
            STDDEV(unrealized_pnl_percentage) as volatility,
            MAX(allocation_percentage) as max_concentration,
            COUNT(*) as asset_count,
            SUM(CASE WHEN unrealized_pnl < 0 THEN 1 ELSE 0 END) as losing_positions
        FROM portfolio_data
        GROUP BY portfolio_id
    )
    SELECT 
        pd.portfolio_name,
        pd.total_value_usd,
        pd.total_pnl_percentage,
        rm.volatility,
        rm.max_concentration,
        rm.asset_count,
        rm.losing_positions,
        JSON_AGG(
            JSON_BUILD_OBJECT(
                'symbol', pd.symbol,
                'allocation', pd.allocation_percentage,
                'pnl', pd.unrealized_pnl_percentage,
                'value', pd.current_value
            ) ORDER BY pd.allocation_percentage DESC
        ) as holdings_breakdown,
        CASE 
            WHEN rm.max_concentration > 50 THEN 'High concentration risk'
            WHEN rm.volatility > 30 THEN 'High volatility'
            WHEN rm.losing_positions > rm.asset_count * 0.6 THEN 'Many losing positions'
            ELSE 'Balanced portfolio'
        END as risk_assessment
    FROM portfolio_data pd
    JOIN risk_metrics rm ON pd.portfolio_id = rm.portfolio_id
    GROUP BY pd.portfolio_id, pd.portfolio_name, pd.total_value_usd, 
             pd.total_pnl_percentage, rm.volatility, rm.max_concentration, 
             rm.asset_count, rm.losing_positions
);
```

**Testing Examples:**
```sql
-- Analyze all portfolios for a user
SELECT * FROM analyze_portfolio('123e4567-e89b-12d3-a456-426614174000');

-- Analyze specific portfolio
SELECT * FROM analyze_portfolio(
    '123e4567-e89b-12d3-a456-426614174000',
    '987fcdeb-51a2-43d1-9f4e-123456789abc'
);

-- Get comprehensive analysis
SELECT * FROM analyze_portfolio(
    '123e4567-e89b-12d3-a456-426614174000',
    NULL,
    'comprehensive'
);
```

**Expected Results:**
```
portfolio_name | total_value_usd | total_pnl_percentage | volatility | max_concentration | asset_count | risk_assessment
Main Portfolio | 125000.50 | 25.00 | 28.5 | 45.2 | 8 | Balanced portfolio
DeFi Portfolio | 45000.25 | -4.25 | 65.8 | 35.0 | 5 | High volatility
```

**Use Cases for XplainCrypto:**
- Portfolio dashboard generation
- Risk assessment automation
- Performance tracking
- Rebalancing recommendations
- User education

### 3. DeFi Opportunity Scanner

**Purpose:** Scans DeFi protocols for yield farming opportunities, liquidity provision, and staking rewards based on user criteria.

**Creation SQL:**
```sql
CREATE SKILL scan_defi_opportunities (
    min_apy DECIMAL DEFAULT 5.0,
    max_risk_level TEXT DEFAULT 'medium',
    preferred_chains TEXT[] DEFAULT ARRAY['ethereum', 'arbitrum', 'polygon'],
    capital_amount DECIMAL DEFAULT 10000
) AS (
    WITH yield_opportunities AS (
        SELECT 
            pool,
            project,
            symbol,
            apy,
            tvlUsd,
            chain,
            CASE 
                WHEN project IN ('AAVE', 'Compound', 'Curve') THEN 'low'
                WHEN project IN ('Uniswap', 'SushiSwap', 'Balancer') THEN 'medium'
                ELSE 'high'
            END as risk_level,
            CASE 
                WHEN apy > 50 THEN 'Very High'
                WHEN apy > 20 THEN 'High'
                WHEN apy > 10 THEN 'Medium'
                ELSE 'Low'
            END as yield_category
        FROM defillama_datasource.yields
        WHERE apy >= scan_defi_opportunities.min_apy
          AND tvlUsd > scan_defi_opportunities.capital_amount * 10 -- Ensure sufficient liquidity
          AND LOWER(chain) = ANY(scan_defi_opportunities.preferred_chains)
    ),
    risk_filtered AS (
        SELECT *
        FROM yield_opportunities
        WHERE CASE 
            WHEN scan_defi_opportunities.max_risk_level = 'low' THEN risk_level = 'low'
            WHEN scan_defi_opportunities.max_risk_level = 'medium' THEN risk_level IN ('low', 'medium')
            ELSE TRUE
        END
    ),
    opportunity_analysis AS (
        SELECT 
            *,
            (apy * scan_defi_opportunities.capital_amount / 100) as estimated_annual_yield,
            (tvlUsd / 1000000) as tvl_millions,
            ROW_NUMBER() OVER (ORDER BY apy DESC, tvlUsd DESC) as opportunity_rank
        FROM risk_filtered
    )
    SELECT 
        opportunity_rank,
        project,
        pool,
        symbol,
        chain,
        apy,
        yield_category,
        risk_level,
        tvl_millions,
        estimated_annual_yield,
        CASE 
            WHEN risk_level = 'low' AND apy > 8 THEN 'Excellent low-risk opportunity'
            WHEN risk_level = 'medium' AND apy > 15 THEN 'Good balanced opportunity'
            WHEN risk_level = 'high' AND apy > 30 THEN 'High-risk, high-reward'
            ELSE 'Standard opportunity'
        END as recommendation
    FROM opportunity_analysis
    ORDER BY opportunity_rank
    LIMIT 20;
);
```

**Testing Examples:**
```sql
-- Scan for conservative opportunities
SELECT * FROM scan_defi_opportunities(8.0, 'low', ARRAY['ethereum'], 50000);

-- Scan for high-yield opportunities
SELECT * FROM scan_defi_opportunities(20.0, 'high', ARRAY['arbitrum', 'polygon'], 25000);

-- Scan with default parameters
SELECT * FROM scan_defi_opportunities();
```

**Expected Results:**
```
opportunity_rank | project | pool | symbol | chain | apy | yield_category | risk_level | tvl_millions | estimated_annual_yield | recommendation
1 | Curve | 3pool | CRV | ethereum | 12.5 | Medium | low | 1250.5 | 6250.00 | Excellent low-risk opportunity
2 | Uniswap | ETH/USDC | UNI | arbitrum | 18.7 | High | medium | 890.2 | 9350.00 | Good balanced opportunity
```

**Use Cases for XplainCrypto:**
- Yield farming strategy development
- DeFi opportunity discovery
- Risk-adjusted yield comparison
- Capital allocation optimization
- Educational content about DeFi

### 4. Market Sentiment Aggregator

**Purpose:** Aggregates market sentiment from multiple sources including news, social media, and trading data to provide comprehensive sentiment analysis.

**Creation SQL:**
```sql
CREATE SKILL aggregate_market_sentiment (
    symbol TEXT DEFAULT 'BTC',
    timeframe TEXT DEFAULT '24h',
    include_social BOOLEAN DEFAULT TRUE
) AS (
    WITH news_sentiment AS (
        SELECT 
            AVG(sentiment_score) as news_sentiment,
            COUNT(*) as news_count
        FROM user_data.news_articles
        WHERE symbol = ANY(mentioned_assets)
          AND created_at > NOW() - CASE 
              WHEN aggregate_market_sentiment.timeframe = '1h' THEN INTERVAL '1 hour'
              WHEN aggregate_market_sentiment.timeframe = '24h' THEN INTERVAL '24 hours'
              WHEN aggregate_market_sentiment.timeframe = '7d' THEN INTERVAL '7 days'
              ELSE INTERVAL '24 hours'
          END
    ),
    price_sentiment AS (
        SELECT 
            symbol,
            (price_usd - LAG(price_usd) OVER (ORDER BY timestamp)) / LAG(price_usd) OVER (ORDER BY timestamp) * 100 as price_change,
            volume_24h,
            timestamp
        FROM crypto_data.price_history
        WHERE symbol = aggregate_market_sentiment.symbol
          AND timestamp > NOW() - CASE 
              WHEN aggregate_market_sentiment.timeframe = '1h' THEN INTERVAL '1 hour'
              WHEN aggregate_market_sentiment.timeframe = '24h' THEN INTERVAL '24 hours'
              WHEN aggregate_market_sentiment.timeframe = '7d' THEN INTERVAL '7 days'
              ELSE INTERVAL '24 hours'
          END
        ORDER BY timestamp DESC
        LIMIT 1
    ),
    volume_analysis AS (
        SELECT 
            symbol,
            AVG(volume_24h) as avg_volume,
            STDDEV(volume_24h) as volume_volatility
        FROM crypto_data.price_history
        WHERE symbol = aggregate_market_sentiment.symbol
          AND timestamp > NOW() - INTERVAL '7 days'
        GROUP BY symbol
    ),
    sentiment_calculation AS (
        SELECT 
            ps.symbol,
            ps.price_change,
            ps.volume_24h,
            va.avg_volume,
            ns.news_sentiment,
            ns.news_count,
            CASE 
                WHEN ps.price_change > 5 THEN 0.8
                WHEN ps.price_change > 2 THEN 0.4
                WHEN ps.price_change > -2 THEN 0.0
                WHEN ps.price_change > -5 THEN -0.4
                ELSE -0.8
            END as price_sentiment,
            CASE 
                WHEN ps.volume_24h > va.avg_volume * 1.5 THEN 0.3
                WHEN ps.volume_24h > va.avg_volume * 1.2 THEN 0.1
                WHEN ps.volume_24h < va.avg_volume * 0.8 THEN -0.1
                ELSE 0.0
            END as volume_sentiment
        FROM price_sentiment ps
        CROSS JOIN news_sentiment ns
        JOIN volume_analysis va ON ps.symbol = va.symbol
    )
    SELECT 
        symbol,
        price_change,
        ROUND(price_sentiment::numeric, 2) as price_sentiment,
        ROUND(volume_sentiment::numeric, 2) as volume_sentiment,
        ROUND(COALESCE(news_sentiment, 0)::numeric, 2) as news_sentiment,
        news_count,
        ROUND(((price_sentiment * 0.4) + (volume_sentiment * 0.2) + (COALESCE(news_sentiment, 0) * 0.4))::numeric, 2) as overall_sentiment,
        CASE 
            WHEN ((price_sentiment * 0.4) + (volume_sentiment * 0.2) + (COALESCE(news_sentiment, 0) * 0.4)) > 0.3 THEN 'Bullish'
            WHEN ((price_sentiment * 0.4) + (volume_sentiment * 0.2) + (COALESCE(news_sentiment, 0) * 0.4)) > 0.1 THEN 'Slightly Bullish'
            WHEN ((price_sentiment * 0.4) + (volume_sentiment * 0.2) + (COALESCE(news_sentiment, 0) * 0.4)) > -0.1 THEN 'Neutral'
            WHEN ((price_sentiment * 0.4) + (volume_sentiment * 0.2) + (COALESCE(news_sentiment, 0) * 0.4)) > -0.3 THEN 'Slightly Bearish'
            ELSE 'Bearish'
        END as sentiment_label,
        volume_24h,
        avg_volume,
        ROUND((volume_24h / avg_volume * 100)::numeric, 1) as volume_vs_average
    FROM sentiment_calculation;
);
```

**Testing Examples:**
```sql
-- Get Bitcoin sentiment for last 24 hours
SELECT * FROM aggregate_market_sentiment('BTC', '24h', TRUE);

-- Get Ethereum sentiment for last week
SELECT * FROM aggregate_market_sentiment('ETH', '7d', TRUE);

-- Get quick sentiment without social data
SELECT * FROM aggregate_market_sentiment('ADA', '1h', FALSE);
```

**Expected Results:**
```
symbol | price_change | price_sentiment | volume_sentiment | news_sentiment | news_count | overall_sentiment | sentiment_label | volume_vs_average
BTC | 2.34 | 0.40 | 0.10 | 0.65 | 12 | 0.42 | Bullish | 125.6
ETH | -1.23 | -0.40 | -0.10 | 0.25 | 8 | -0.06 | Neutral | 89.3
```

**Use Cases for XplainCrypto:**
- Market sentiment dashboards
- Trading signal generation
- Risk assessment
- Market timing analysis
- Educational content about sentiment

---

## Agents

### 1. Risk Assessment Agent

**Purpose:** Comprehensive risk analysis agent that evaluates portfolio risk, market conditions, and provides risk management recommendations.

**Creation SQL:**
```sql
CREATE AGENT risk_assessment_agent
USING 
    model = 'mindsdb.risk_assessment_engine',
    skills = ['analyze_portfolio', 'get_crypto_price', 'aggregate_market_sentiment'],
    description = 'Comprehensive risk assessment agent for cryptocurrency portfolios and investments';
```

**Agent Capabilities:**
- Portfolio risk analysis and scoring
- Market risk assessment
- Correlation analysis
- Value at Risk (VaR) calculations
- Stress testing scenarios
- Risk mitigation recommendations

**Testing Examples:**
```sql
-- Ask agent to assess portfolio risk
SELECT risk_assessment_agent(
    'Analyze the risk profile of my portfolio containing 60% BTC, 30% ETH, and 10% altcoins'
) as risk_analysis;

-- Request specific risk metrics
SELECT risk_assessment_agent(
    'What is the Value at Risk for a $100,000 crypto portfolio over the next 30 days?'
) as var_analysis;

-- Get risk mitigation advice
SELECT risk_assessment_agent(
    'How can I reduce the risk of my DeFi portfolio while maintaining yield opportunities?'
) as risk_mitigation;
```

**Expected Results:**
```
risk_analysis: "PORTFOLIO RISK ASSESSMENT:
Overall Risk Score: 72/100 (MODERATE-HIGH)

Risk Breakdown:
- Concentration Risk: HIGH (90% in BTC/ETH)
- Market Risk: MODERATE (crypto volatility)
- Liquidity Risk: LOW (major assets)

Recommendations:
1. Diversify beyond top 2 cryptocurrencies
2. Consider 15-20% stablecoin allocation
3. Implement stop-loss orders at -20%
4. Monitor correlation with traditional markets"
```

**Use Cases for XplainCrypto:**
- Automated risk assessment for new users
- Portfolio optimization recommendations
- Risk education and awareness
- Compliance and regulatory reporting
- Investment advisory services

### 2. Sentiment Analysis Agent

**Purpose:** Advanced sentiment analysis agent that monitors market sentiment across multiple sources and provides trading insights.

**Creation SQL:**
```sql
CREATE AGENT sentiment_analysis_agent
USING 
    model = 'mindsdb.market_sentiment_analyzer',
    skills = ['aggregate_market_sentiment', 'get_crypto_price'],
    description = 'Advanced market sentiment analysis agent for cryptocurrency markets';
```

**Agent Capabilities:**
- Multi-source sentiment aggregation
- Real-time sentiment monitoring
- Sentiment-based trading signals
- Market psychology analysis
- Contrarian indicator identification
- Sentiment trend analysis

**Testing Examples:**
```sql
-- Get current market sentiment
SELECT sentiment_analysis_agent(
    'What is the current market sentiment for Bitcoin and how might it affect price?'
) as sentiment_report;

-- Analyze sentiment trends
SELECT sentiment_analysis_agent(
    'How has Ethereum sentiment changed over the past week and what are the key drivers?'
) as sentiment_trend;

-- Get contrarian signals
SELECT sentiment_analysis_agent(
    'Are there any contrarian sentiment signals suggesting a market reversal?'
) as contrarian_analysis;
```

**Expected Results:**
```
sentiment_report: "BITCOIN SENTIMENT ANALYSIS:
Current Sentiment: BULLISH (+72/100)

Sentiment Breakdown:
- News Sentiment: +85 (ETF approval catalyst)
- Social Sentiment: +68 (Community excitement)
- Technical Sentiment: +75 (Breaking resistance)

Price Impact Prediction:
- Short-term: Continued bullish momentum
- Target: $48,000-$50,000
- Risk: Extreme greed levels suggest caution

Key Drivers:
1. Institutional adoption news
2. Technical breakout confirmation
3. Volume surge indicating genuine interest"
```

**Use Cases for XplainCrypto:**
- Daily sentiment reports
- Trading signal generation
- Market timing analysis
- User education about market psychology
- Risk management alerts

---

## Knowledge Bases

### 1. Crypto Education Knowledge Base

**Purpose:** Comprehensive educational content about cryptocurrencies, blockchain technology, and trading strategies.

**Creation SQL:**
```sql
CREATE KNOWLEDGE_BASE crypto_education
FROM (
    SELECT 
        'educational_content' as content_type,
        title,
        content,
        tags,
        difficulty_level,
        created_at
    FROM user_data.courses
    WHERE is_published = TRUE
    
    UNION ALL
    
    SELECT 
        'lesson_content' as content_type,
        title,
        content,
        ARRAY['lesson', 'education'] as tags,
        'beginner' as difficulty_level,
        created_at
    FROM user_data.course_lessons
    WHERE is_published = TRUE
)
WITH (
    embeddings_model = 'openai_engine',
    chunk_size = 1000,
    chunk_overlap = 200
);
```

**Testing Examples:**
```sql
-- Query about Bitcoin basics
SELECT * FROM crypto_education 
WHERE content MATCH 'What is Bitcoin and how does it work?';

-- Search for DeFi information
SELECT * FROM crypto_education 
WHERE content MATCH 'DeFi yield farming strategies';

-- Find trading education content
SELECT * FROM crypto_education 
WHERE content MATCH 'technical analysis cryptocurrency trading';
```

**Expected Results:**
```
content_type | title | content | relevance_score
educational_content | "Bitcoin Fundamentals" | "Bitcoin is a decentralized digital currency..." | 0.95
lesson_content | "Understanding Blockchain" | "Blockchain technology is the foundation..." | 0.87
```

**Use Cases for XplainCrypto:**
- AI-powered educational chatbot
- Personalized learning recommendations
- Content search and discovery
- User question answering
- Course content optimization

### 2. Market Research Knowledge Base

**Purpose:** Comprehensive market research, analysis reports, and trading insights from various sources.

**Creation SQL:**
```sql
CREATE KNOWLEDGE_BASE market_research
FROM (
    SELECT 
        'news_article' as content_type,
        title,
        content,
        ARRAY[category] as tags,
        sentiment_score,
        published_at as created_at
    FROM user_data.news_articles
    WHERE published_at > NOW() - INTERVAL '90 days'
    
    UNION ALL
    
    SELECT 
        'analysis_report' as content_type,
        report_name as title,
        'Generated analysis report' as content,
        ARRAY[report_type] as tags,
        0 as sentiment_score,
        last_generated as created_at
    FROM user_data.saved_reports
    WHERE last_generated IS NOT NULL
)
WITH (
    embeddings_model = 'openai_engine',
    chunk_size = 1500,
    chunk_overlap = 300
);
```

**Testing Examples:**
```sql
-- Research Bitcoin price predictions
SELECT * FROM market_research 
WHERE content MATCH 'Bitcoin price prediction 2025';

-- Find DeFi protocol analysis
SELECT * FROM market_research 
WHERE content MATCH 'Uniswap protocol analysis TVL';

-- Search for regulatory news
SELECT * FROM market_research 
WHERE content MATCH 'cryptocurrency regulation SEC';
```

**Use Cases for XplainCrypto:**
- Market research automation
- Investment decision support
- Trend analysis and insights
- Regulatory update tracking
- Competitive intelligence

### 3. DeFi Protocol Knowledge Base

**Purpose:** Detailed information about DeFi protocols, smart contracts, and yield farming strategies.

**Creation SQL:**
```sql
CREATE KNOWLEDGE_BASE defi_protocols
FROM (
    SELECT 
        'protocol_info' as content_type,
        name as title,
        CONCAT('Protocol: ', name, ', Category: ', category, ', TVL: $', tvl, ', Chains: ', array_to_string(chains, ', ')) as content,
        ARRAY[category, 'defi'] as tags,
        tvl as relevance_score,
        updated_at as created_at
    FROM crypto_data.defi_protocols
    WHERE tvl > 10000000
    
    UNION ALL
    
    SELECT 
        'yield_opportunity' as content_type,
        CONCAT(project, ' - ', pool) as title,
        CONCAT('Yield opportunity: ', pool, ' on ', project, ', APY: ', apy, '%, TVL: $', tvlUsd, ', Chain: ', chain) as content,
        ARRAY['yield', 'farming', project] as tags,
        apy as relevance_score,
        NOW() as created_at
    FROM defillama_datasource.yields
    WHERE apy > 5 AND tvlUsd > 1000000
)
WITH (
    embeddings_model = 'anthropic_engine',
    chunk_size = 800,
    chunk_overlap = 150
);
```

**Testing Examples:**
```sql
-- Find information about Uniswap
SELECT * FROM defi_protocols 
WHERE content MATCH 'Uniswap V3 liquidity provision';

-- Search for high-yield opportunities
SELECT * FROM defi_protocols 
WHERE content MATCH 'high yield farming opportunities Ethereum';

-- Research specific protocols
SELECT * FROM defi_protocols 
WHERE content MATCH 'AAVE lending protocol risks';
```

**Use Cases for XplainCrypto:**
- DeFi strategy development
- Protocol research and analysis
- Yield farming optimization
- Risk assessment automation
- Educational content generation

### 4. Trading Strategies Knowledge Base

**Purpose:** Collection of trading strategies, technical analysis patterns, and market insights.

**Creation SQL:**
```sql
CREATE KNOWLEDGE_BASE trading_strategies
FROM (
    SELECT 
        'user_post' as content_type,
        SUBSTRING(content, 1, 100) as title,
        content,
        tags,
        like_count as relevance_score,
        created_at
    FROM user_data.posts
    WHERE post_type = 'analysis'
      AND like_count > 10
    
    UNION ALL
    
    SELECT 
        'community_discussion' as content_type,
        SUBSTRING(content, 1, 100) as title,
        content,
        ARRAY['discussion', 'community'] as tags,
        like_count as relevance_score,
        created_at
    FROM user_data.comments
    WHERE like_count > 5
)
WITH (
    embeddings_model = 'openai_engine',
    chunk_size = 1200,
    chunk_overlap = 250
);
```

**Testing Examples:**
```sql
-- Find Bitcoin trading strategies
SELECT * FROM trading_strategies 
WHERE content MATCH 'Bitcoin trading strategy support resistance';

-- Search for technical analysis patterns
SELECT * FROM trading_strategies 
WHERE content MATCH 'head and shoulders pattern cryptocurrency';

-- Find risk management strategies
SELECT * FROM trading_strategies 
WHERE content MATCH 'stop loss position sizing crypto trading';
```

**Use Cases for XplainCrypto:**
- Trading education and mentorship
- Strategy backtesting and optimization
- Community knowledge sharing
- Pattern recognition training
- Risk management education

---

## Enhanced User-Focused Features

### 1. Social Trading Platform

**Purpose:** Enable users to follow successful traders, copy strategies, and share trading insights within the community.

**Key Features:**
- **Trader Leaderboards**: Rank users by performance metrics
- **Copy Trading**: Automatically replicate successful traders' positions
- **Social Feeds**: Share trades, analysis, and market insights
- **Performance Transparency**: Public portfolio performance tracking

**Implementation Examples:**
```sql
-- Get top performing traders
SELECT 
    u.username,
    u.profile_image_url,
    AVG(ua.metric_value) as avg_performance,
    COUNT(DISTINCT uc.follower_id) as follower_count,
    p.total_value_usd
FROM user_data.users u
JOIN user_data.user_analytics ua ON u.user_id = ua.user_id
JOIN user_data.user_connections uc ON u.user_id = uc.following_id
JOIN user_data.portfolios p ON u.user_id = p.user_id
WHERE ua.metric_name = 'portfolio_performance_24h'
  AND ua.calculated_at > NOW() - INTERVAL '30 days'
  AND p.is_public = TRUE
GROUP BY u.user_id, u.username, u.profile_image_url, p.total_value_usd
HAVING AVG(ua.metric_value) > 10
ORDER BY avg_performance DESC, follower_count DESC
LIMIT 20;

-- Copy trading implementation
CREATE FUNCTION copy_trade(
    follower_id UUID,
    trader_id UUID,
    copy_percentage DECIMAL DEFAULT 10.0
) RETURNS VOID AS $$
BEGIN
    -- Copy recent transactions from followed trader
    INSERT INTO user_data.transactions (
        user_id, portfolio_id, asset_id, transaction_type,
        quantity, price_per_unit, total_amount, notes
    )
    SELECT 
        follower_id,
        follower_portfolio.portfolio_id,
        t.asset_id,
        t.transaction_type,
        (t.quantity * copy_percentage / 100),
        t.price_per_unit,
        (t.total_amount * copy_percentage / 100),
        CONCAT('Copy trade from ', trader.username)
    FROM user_data.transactions t
    JOIN user_data.users trader ON t.user_id = trader.user_id
    JOIN user_data.portfolios follower_portfolio ON follower_portfolio.user_id = follower_id
    WHERE t.user_id = trader_id
      AND t.created_at > NOW() - INTERVAL '1 hour'
      AND follower_portfolio.is_default = TRUE;
END;
$$ LANGUAGE plpgsql;
```

### 2. Personalized Learning Paths

**Purpose:** AI-driven personalized education based on user knowledge level, interests, and trading experience.

**Key Features:**
- **Adaptive Learning**: Adjust content difficulty based on progress
- **Skill Assessment**: Regular quizzes and practical exercises
- **Personalized Recommendations**: Suggest courses based on portfolio and interests
- **Progress Tracking**: Visual learning journey with achievements

**Implementation Examples:**
```sql
-- Generate personalized course recommendations
WITH user_profile AS (
    SELECT 
        u.user_id,
        u.username,
        COALESCE(AVG(ce.progress_percentage), 0) as avg_progress,
        COUNT(ce.course_id) as courses_enrolled,
        ARRAY_AGG(DISTINCT ca.symbol) as portfolio_assets
    FROM user_data.users u
    LEFT JOIN user_data.course_enrollments ce ON u.user_id = ce.user_id
    LEFT JOIN user_data.portfolios p ON u.user_id = p.user_id
    LEFT JOIN user_data.portfolio_holdings ph ON p.portfolio_id = ph.portfolio_id
    LEFT JOIN user_data.crypto_assets ca ON ph.asset_id = ca.asset_id
    WHERE u.user_id = '123e4567-e89b-12d3-a456-426614174000'
    GROUP BY u.user_id, u.username
),
recommended_courses AS (
    SELECT 
        c.course_id,
        c.title,
        c.difficulty_level,
        c.duration_minutes,
        c.rating_average,
        CASE 
            WHEN up.avg_progress < 30 THEN 'beginner'
            WHEN up.avg_progress < 70 THEN 'intermediate'
            ELSE 'advanced'
        END as recommended_level,
        CASE 
            WHEN 'BTC' = ANY(up.portfolio_assets) AND c.tags @> ARRAY['bitcoin'] THEN 10
            WHEN 'ETH' = ANY(up.portfolio_assets) AND c.tags @> ARRAY['ethereum'] THEN 8
            WHEN c.tags @> ARRAY['defi'] AND array_length(up.portfolio_assets, 1) > 5 THEN 6
            ELSE 3
        END as relevance_score
    FROM user_data.courses c
    CROSS JOIN user_profile up
    WHERE c.is_published = TRUE
      AND c.difficulty_level = CASE 
          WHEN up.avg_progress < 30 THEN 'beginner'
          WHEN up.avg_progress < 70 THEN 'intermediate'
          ELSE 'advanced'
      END
      AND c.course_id NOT IN (
          SELECT course_id FROM user_data.course_enrollments 
          WHERE user_id = up.user_id
      )
)
SELECT 
    title,
    difficulty_level,
    duration_minutes,
    rating_average,
    relevance_score,
    'Recommended based on your ' || 
    CASE 
        WHEN relevance_score >= 8 THEN 'portfolio holdings'
        WHEN relevance_score >= 6 THEN 'trading experience'
        ELSE 'learning progress'
    END as recommendation_reason
FROM recommended_courses
ORDER BY relevance_score DESC, rating_average DESC
LIMIT 10;
```

### 3. Community-Driven Insights

**Purpose:** Leverage community knowledge through collaborative analysis, discussions, and shared research.

**Key Features:**
- **Collaborative Analysis**: Group research projects and shared insights
- **Discussion Forums**: Topic-specific discussions with expert moderation
- **Peer Reviews**: Community validation of trading strategies and analysis
- **Knowledge Sharing**: Reward system for valuable contributions

**Implementation Examples:**
```sql
-- Community sentiment aggregation
WITH community_sentiment AS (
    SELECT 
        p.mentioned_assets,
        COUNT(*) as mention_count,
        AVG(p.like_count) as avg_engagement,
        SUM(CASE WHEN p.content ILIKE '%bullish%' OR p.content ILIKE '%buy%' THEN 1 ELSE 0 END) as bullish_mentions,
        SUM(CASE WHEN p.content ILIKE '%bearish%' OR p.content ILIKE '%sell%' THEN 1 ELSE 0 END) as bearish_mentions,
        COUNT(*) as total_mentions
    FROM user_data.posts p
    WHERE p.created_at > NOW() - INTERVAL '24 hours'
      AND p.mentioned_assets IS NOT NULL
      AND array_length(p.mentioned_assets, 1) > 0
    GROUP BY p.mentioned_assets
),
sentiment_analysis AS (
    SELECT 
        UNNEST(mentioned_assets) as asset_symbol,
        mention_count,
        avg_engagement,
        CASE 
            WHEN bullish_mentions > bearish_mentions * 1.5 THEN 'Bullish'
            WHEN bearish_mentions > bullish_mentions * 1.5 THEN 'Bearish'
            ELSE 'Neutral'
        END as community_sentiment,
        ROUND((bullish_mentions::DECIMAL / total_mentions * 100), 1) as bullish_percentage,
        ROUND((bearish_mentions::DECIMAL / total_mentions * 100), 1) as bearish_percentage
    FROM community_sentiment
    WHERE mention_count >= 5
)
SELECT 
    asset_symbol,
    community_sentiment,
    bullish_percentage,
    bearish_percentage,
    mention_count,
    ROUND(avg_engagement, 1) as avg_engagement
FROM sentiment_analysis
ORDER BY mention_count DESC, avg_engagement DESC;

-- Expert contributor identification
SELECT 
    u.username,
    u.profile_image_url,
    COUNT(p.post_id) as total_posts,
    AVG(p.like_count) as avg_likes,
    SUM(p.like_count) as total_likes,
    COUNT(DISTINCT DATE(p.created_at)) as active_days,
    ARRAY_AGG(DISTINCT unnest(p.tags)) as expertise_areas,
    CASE 
        WHEN AVG(p.like_count) > 50 AND COUNT(p.post_id) > 20 THEN 'Expert Contributor'
        WHEN AVG(p.like_count) > 20 AND COUNT(p.post_id) > 10 THEN 'Active Contributor'
        WHEN COUNT(p.post_id) > 5 THEN 'Regular Contributor'
        ELSE 'New Contributor'
    END as contributor_level
FROM user_data.users u
JOIN user_data.posts p ON u.user_id = p.user_id
WHERE p.created_at > NOW() - INTERVAL '30 days'
  AND p.post_type = 'analysis'
GROUP BY u.user_id, u.username, u.profile_image_url
HAVING COUNT(p.post_id) >= 3
ORDER BY avg_likes DESC, total_posts DESC;
```

### 4. Behavioral Analysis and Recommendations

**Purpose:** Analyze user behavior patterns to provide personalized recommendations and improve platform experience.

**Key Features:**
- **Trading Pattern Analysis**: Identify successful and unsuccessful patterns
- **Risk Behavior Assessment**: Monitor risk-taking patterns and provide guidance
- **Engagement Optimization**: Personalize content and features based on usage
- **Performance Correlation**: Link behavior patterns to portfolio performance

**Implementation Examples:**
```sql
-- User behavior analysis
WITH user_behavior AS (
    SELECT 
        u.user_id,
        u.username,
        COUNT(DISTINCT DATE(ual.created_at)) as active_days,
        COUNT(CASE WHEN ual.activity_type = 'portfolio_view' THEN 1 END) as portfolio_views,
        COUNT(CASE WHEN ual.activity_type = 'trade_execution' THEN 1 END) as trades_executed,
        COUNT(CASE WHEN ual.activity_type = 'course_access' THEN 1 END) as learning_sessions,
        COUNT(CASE WHEN ual.activity_type = 'social_interaction' THEN 1 END) as social_interactions,
        AVG(EXTRACT(HOUR FROM ual.created_at)) as avg_activity_hour,
        MODE() WITHIN GROUP (ORDER BY EXTRACT(DOW FROM ual.created_at)) as most_active_day
    FROM user_data.users u
    JOIN user_data.user_activity_logs ual ON u.user_id = ual.user_id
    WHERE ual.created_at > NOW() - INTERVAL '30 days'
    GROUP BY u.user_id, u.username
),
performance_correlation AS (
    SELECT 
        ub.user_id,
        ub.username,
        ub.active_days,
        ub.portfolio_views,
        ub.trades_executed,
        ub.learning_sessions,
        ub.social_interactions,
        AVG(ua.metric_value) as avg_performance,
        CASE 
            WHEN ub.learning_sessions > 20 AND AVG(ua.metric_value) > 15 THEN 'Learning-Driven High Performer'
            WHEN ub.social_interactions > 50 AND AVG(ua.metric_value) > 10 THEN 'Social-Driven Performer'
            WHEN ub.trades_executed > 100 AND AVG(ua.metric_value) < 5 THEN 'Over-Trader'
            WHEN ub.portfolio_views > 200 AND ub.trades_executed < 10 THEN 'Analysis Paralysis'
            ELSE 'Balanced User'
        END as user_archetype,
        CASE 
            WHEN ub.avg_activity_hour BETWEEN 9 AND 17 THEN 'Day Trader'
            WHEN ub.avg_activity_hour BETWEEN 18 AND 23 THEN 'Evening Trader'
            ELSE 'Night Owl'
        END as trading_schedule
    FROM user_behavior ub
    JOIN user_data.user_analytics ua ON ub.user_id = ua.user_id
    WHERE ua.metric_name = 'portfolio_performance_24h'
      AND ua.calculated_at > NOW() - INTERVAL '30 days'
    GROUP BY ub.user_id, ub.username, ub.active_days, ub.portfolio_views, 
             ub.trades_executed, ub.learning_sessions, ub.social_interactions, 
             ub.avg_activity_hour
)
SELECT 
    username,
    user_archetype,
    trading_schedule,
    ROUND(avg_performance, 2) as performance_percentage,
    active_days,
    trades_executed,
    learning_sessions,
    CASE 
        WHEN user_archetype = 'Over-Trader' THEN 'Consider reducing trading frequency and focusing on quality over quantity'
        WHEN user_archetype = 'Analysis Paralysis' THEN 'Set clear entry/exit criteria and practice decisive action'
        WHEN user_archetype = 'Learning-Driven High Performer' THEN 'Continue your educational approach and consider sharing insights'
        WHEN user_archetype = 'Social-Driven Performer' THEN 'Leverage community insights while maintaining independent analysis'
        ELSE 'Maintain your balanced approach to trading and learning'
    END as personalized_recommendation
FROM performance_correlation
ORDER BY avg_performance DESC;

-- Personalized feature recommendations
WITH user_preferences AS (
    SELECT 
        u.user_id,
        u.username,
        CASE 
            WHEN COUNT(CASE WHEN ual.activity_type = 'defi_interaction' THEN 1 END) > 10 THEN TRUE
            ELSE FALSE
        END as defi_interested,
        CASE 
            WHEN COUNT(CASE WHEN ual.activity_type = 'social_interaction' THEN 1 END) > 20 THEN TRUE
            ELSE FALSE
        END as socially_active,
        CASE 
            WHEN COUNT(CASE WHEN ual.activity_type = 'course_access' THEN 1 END) > 15 THEN TRUE
            ELSE FALSE
        END as learning_focused,
        CASE 
            WHEN COUNT(CASE WHEN ual.activity_type = 'trade_execution' THEN 1 END) > 50 THEN TRUE
            ELSE FALSE
        END as active_trader
    FROM user_data.users u
    JOIN user_data.user_activity_logs ual ON u.user_id = ual.user_id
    WHERE ual.created_at > NOW() - INTERVAL '30 days'
    GROUP BY u.user_id, u.username
)
SELECT 
    username,
    ARRAY_AGG(
        CASE 
            WHEN defi_interested THEN 'Enable DeFi yield farming alerts'
            WHEN socially_active THEN 'Join advanced trading communities'
            WHEN learning_focused THEN 'Enroll in advanced courses'
            WHEN active_trader THEN 'Activate advanced trading tools'
        END
    ) FILTER (WHERE 
        (defi_interested) OR 
        (socially_active) OR 
        (learning_focused) OR 
        (active_trader)
    ) as feature_recommendations,
    CASE 
        WHEN defi_interested AND active_trader THEN 'DeFi Trading Specialist'
        WHEN socially_active AND learning_focused THEN 'Community Educator'
        WHEN active_trader AND learning_focused THEN 'Analytical Trader'
        WHEN socially_active AND active_trader THEN 'Social Trader'
        ELSE 'Balanced User'
    END as recommended_user_path
FROM user_preferences
WHERE defi_interested OR socially_active OR learning_focused OR active_trader;
```

### 5. Advanced Portfolio Analytics

**Purpose:** Provide institutional-grade portfolio analytics including risk metrics, performance attribution, and optimization suggestions.

**Key Features:**
- **Risk-Adjusted Returns**: Sharpe ratio, Sortino ratio, and other risk metrics
- **Performance Attribution**: Identify which assets contribute most to returns
- **Correlation Analysis**: Monitor portfolio diversification effectiveness
- **Stress Testing**: Scenario analysis for different market conditions

**Implementation Examples:**
```sql
-- Advanced portfolio analytics
WITH portfolio_metrics AS (
    SELECT 
        p.portfolio_id,
        p.name as portfolio_name,
        p.user_id,
        p.total_value_usd,
        p.total_invested_usd,
        p.total_pnl_percentage,
        COUNT(ph.asset_id) as asset_count,
        STDDEV(ph.unrealized_pnl_percentage) as portfolio_volatility,
        MAX(ph.unrealized_pnl_percentage) as best_performer,
        MIN(ph.unrealized_pnl_percentage) as worst_performer,
        SUM(CASE WHEN ph.unrealized_pnl_percentage > 0 THEN 1 ELSE 0 END) as winning_positions,
        AVG(ph.unrealized_pnl_percentage) as avg_position_return
    FROM user_data.portfolios p
    JOIN user_data.portfolio_holdings ph ON p.portfolio_id = ph.portfolio_id
    GROUP BY p.portfolio_id, p.name, p.user_id, p.total_value_usd, 
             p.total_invested_usd, p.total_pnl_percentage
),
risk_metrics AS (
    SELECT 
        pm.*,
        CASE 
            WHEN pm.portfolio_volatility > 0 THEN pm.total_pnl_percentage / pm.portfolio_volatility
            ELSE 0
        END as sharpe_ratio,
        CASE 
            WHEN pm.asset_count < 5 THEN 'High Concentration Risk'
            WHEN pm.portfolio_volatility > 50 THEN 'High Volatility Risk'
            WHEN pm.winning_positions::DECIMAL / pm.asset_count < 0.5 THEN 'Poor Selection Risk'
            ELSE 'Balanced Risk Profile'
        END as risk_assessment,
        pm.winning_positions::DECIMAL / pm.asset_count * 100 as win_rate
    FROM portfolio_metrics pm
),
performance_attribution AS (
    SELECT 
        rm.*,
        ARRAY_AGG(
            JSON_BUILD_OBJECT(
                'symbol', ca.symbol,
                'allocation', ROUND((ph.current_value / rm.total_value_usd * 100)::numeric, 2),
                'contribution', ROUND((ph.unrealized_pnl / rm.total_value_usd * 100)::numeric, 2),
                'performance', ROUND(ph.unrealized_pnl_percentage::numeric, 2)
            ) ORDER BY ph.current_value DESC
        ) as asset_breakdown
    FROM risk_metrics rm
    JOIN user_data.portfolio_holdings ph ON rm.portfolio_id = ph.portfolio_id
    JOIN user_data.crypto_assets ca ON ph.asset_id = ca.asset_id
    GROUP BY rm.portfolio_id, rm.portfolio_name, rm.user_id, rm.total_value_usd,
             rm.total_invested_usd, rm.total_pnl_percentage, rm.asset_count,
             rm.portfolio_volatility, rm.best_performer, rm.worst_performer,
             rm.winning_positions, rm.avg_position_return, rm.sharpe_ratio,
             rm.risk_assessment, rm.win_rate
)
SELECT 
    portfolio_name,
    total_value_usd,
    ROUND(total_pnl_percentage::numeric, 2) as return_percentage,
    ROUND(portfolio_volatility::numeric, 2) as volatility_percentage,
    ROUND(sharpe_ratio::numeric, 3) as sharpe_ratio,
    ROUND(win_rate::numeric, 1) as win_rate_percentage,
    risk_assessment,
    asset_count,
    asset_breakdown,
    CASE 
        WHEN sharpe_ratio > 1.5 THEN 'Excellent risk-adjusted returns'
        WHEN sharpe_ratio > 1.0 THEN 'Good risk-adjusted returns'
        WHEN sharpe_ratio > 0.5 THEN 'Moderate risk-adjusted returns'
        ELSE 'Poor risk-adjusted returns'
    END as performance_grade,
    ARRAY[
        CASE WHEN asset_count < 5 THEN 'Consider diversifying into more assets' END,
        CASE WHEN portfolio_volatility > 60 THEN 'Consider adding stablecoins to reduce volatility' END,
        CASE WHEN win_rate < 40 THEN 'Review asset selection criteria' END,
        CASE WHEN sharpe_ratio < 0.5 THEN 'Focus on risk management and position sizing' END
    ] FILTER (WHERE 
        (asset_count < 5) OR 
        (portfolio_volatility > 60) OR 
        (win_rate < 40) OR 
        (sharpe_ratio < 0.5)
    ) as optimization_recommendations
FROM performance_attribution;
```

---

## Testing Examples

### Complete System Integration Test

```sql
-- 1. Test all data sources connectivity
SELECT 'CoinMarketCap' as source, COUNT(*) as records 
FROM coinmarketcap_datasource.quotes
UNION ALL
SELECT 'DeFiLlama' as source, COUNT(*) as records 
FROM defillama_datasource.protocols
UNION ALL
SELECT 'Binance' as source, COUNT(*) as records 
FROM binance_datasource.ticker_24hr
UNION ALL
SELECT 'Blockchain' as source, COUNT(*) as records 
FROM blockchain_datasource.blocks LIMIT 100
UNION ALL
SELECT 'Dune' as source, COUNT(*) as records 
FROM dune_datasource.balances LIMIT 100
UNION ALL
SELECT 'Whale Alerts' as source, COUNT(*) as records 
FROM whale_alerts_datasource.transactions LIMIT 100;

-- 2. Test all AI models
SELECT 'Market Analysis' as model, 
       analysis 
FROM mindsdb.market_analysis_agent 
WHERE symbol = 'BTC' 
  AND price = '45000' 
  AND change_24h = '2.5'
UNION ALL
SELECT 'Sentiment Analysis' as model,
       sentiment_analysis
FROM mindsdb.market_sentiment_analyzer
WHERE news_headlines = 'Bitcoin reaches new highs'
  AND social_mentions = 'Positive: 70%, Neutral: 20%, Negative: 10%'
UNION ALL
SELECT 'Risk Assessment' as model,
       risk_analysis
FROM mindsdb.risk_assessment_engine
WHERE asset_name = 'Bitcoin Portfolio'
  AND position_details = '$50,000 BTC position';

-- 3. Test user-focused features
SELECT 
    u.username,
    COUNT(p.portfolio_id) as portfolios,
    COUNT(ce.course_id) as courses_enrolled,
    COUNT(uc.following_id) as following_count,
    COUNT(posts.post_id) as posts_created
FROM user_data.users u
LEFT JOIN user_data.portfolios p ON u.user_id = p.user_id
LEFT JOIN user_data.course_enrollments ce ON u.user_id = ce.user_id
LEFT JOIN user_data.user_connections uc ON u.user_id = uc.follower_id
LEFT JOIN user_data.posts posts ON u.user_id = posts.user_id
GROUP BY u.user_id, u.username
LIMIT 10;

-- 4. Test knowledge bases
SELECT * FROM crypto_education 
WHERE content MATCH 'Bitcoin trading strategies'
LIMIT 5;

SELECT * FROM defi_protocols 
WHERE content MATCH 'Uniswap liquidity provision'
LIMIT 5;

-- 5. Test skills
SELECT * FROM get_crypto_price('BTC', '24h', 'all');
SELECT * FROM scan_defi_opportunities(10.0, 'medium', ARRAY['ethereum'], 25000);
SELECT * FROM aggregate_market_sentiment('ETH', '24h', TRUE);

-- 6. Test jobs status
SELECT 
    job_name,
    status,
    last_run,
    next_run,
    error_message
FROM information_schema.jobs
ORDER BY last_run DESC;

-- 7. Integration test with real workflow
WITH market_data AS (
    SELECT * FROM get_crypto_price('BTC', '24h', 'coinmarketcap')
),
sentiment_data AS (
    SELECT * FROM aggregate_market_sentiment('BTC', '24h', TRUE)
),
defi_opportunities AS (
    SELECT * FROM scan_defi_opportunities(8.0, 'low', ARRAY['ethereum'], 50000)
)
SELECT 
    'BTC Analysis' as analysis_type,
    md.avg_price,
    sd.overall_sentiment,
    sd.sentiment_label,
    COUNT(do.opportunity_rank) as defi_opportunities_count
FROM market_data md
CROSS JOIN sentiment_data sd
LEFT JOIN defi_opportunities do ON TRUE
GROUP BY md.avg_price, sd.overall_sentiment, sd.sentiment_label;
```

---

## Performance Characteristics

### System Performance Metrics

**Data Handler Performance:**
- CoinMarketCap: 200-500ms latency, 333-10,000 calls/day
- DeFiLlama: 300-800ms latency, 1000+ calls/hour
- Binance: <100ms latency, 1200 calls/minute
- Blockchain: 500-1500ms latency, 10,000 calls/hour
- Dune Analytics: 30s-5min query time, 1000 queries/month
- Whale Alerts: <30s alert time, 100-1000 calls/hour

**AI Model Performance:**
- Market Analysis: 2-5 seconds, ~800 tokens per query
- Sentiment Analysis: 3-7 seconds, ~1200 tokens per query
- Risk Assessment: 4-8 seconds, ~1000 tokens per query
- DeFi Analysis: 5-10 seconds, ~1600 tokens per query
- Technical Analysis: 3-6 seconds, ~1400 tokens per query

**Database Performance:**
- User queries: <100ms for simple queries, <500ms for complex
- Portfolio calculations: <200ms for standard portfolios
- Social features: <150ms for feeds, <300ms for complex social queries
- Analytics generation: 1-5 seconds for comprehensive reports

**Scalability Considerations:**
- Supports 10,000+ concurrent users
- Handles 1M+ transactions per day
- Processes 100,000+ social interactions daily
- Manages 50,000+ active portfolios simultaneously

---

## Use Cases for XplainCrypto

### 1. Individual Investor Platform

**Primary Use Cases:**
- **Portfolio Management**: Track multiple portfolios with real-time valuations
- **Educational Journey**: Personalized learning paths from beginner to advanced
- **Social Trading**: Follow successful traders and copy strategies
- **Risk Management**: AI-powered risk assessment and optimization
- **Market Intelligence**: Daily analysis reports and sentiment tracking

**User Journey Example:**
1. New user signs up and completes risk assessment
2. AI recommends personalized learning path and starter portfolio
3. User follows educational courses while building first portfolio
4. Social features connect user with similar traders and mentors
5. Advanced analytics help optimize portfolio performance over time

### 2. Professional Trading Community

**Advanced Features:**
- **Institutional Analytics**: Advanced risk metrics and performance attribution
- **Research Collaboration**: Community-driven analysis and insights
- **Strategy Backtesting**: Historical performance testing with AI insights
- **Market Intelligence**: Real-time anomaly detection and news impact analysis
- **Professional Networking**: Connect with other professional traders

**Professional Workflow:**
1. Access institutional-grade analytics and risk management tools
2. Collaborate on research projects with other professionals
3. Share and validate trading strategies with peer review
4. Receive real-time alerts for market anomalies and opportunities
5. Build reputation through consistent performance and knowledge sharing

### 3. Educational Institution Integration

**Educational Features:**
- **Curriculum Integration**: Structured courses with progress tracking
- **Practical Application**: Real portfolio management with virtual funds
- **Assessment Tools**: Quizzes, assignments, and practical evaluations
- **Instructor Dashboard**: Monitor student progress and engagement
- **Certification System**: Blockchain-verified certificates and achievements

**Academic Implementation:**
1. Instructors create structured cryptocurrency and blockchain courses
2. Students progress through theoretical and practical modules
3. Real-time portfolio simulation provides hands-on experience
4. AI tutors provide personalized assistance and feedback
5. Comprehensive assessment and certification upon completion

### 4. DeFi Yield Optimization Platform

**DeFi-Specific Features:**
- **Yield Farming Scanner**: Automated opportunity discovery across protocols
- **Risk-Adjusted Yield Analysis**: Compare opportunities with risk assessment
- **Protocol Health Monitoring**: Track TVL, security, and performance metrics
- **Cross-Chain Optimization**: Manage positions across multiple blockchains
- **Automated Rebalancing**: AI-driven position management and optimization

**DeFi User Experience:**
1. Set yield targets and risk tolerance preferences
2. AI scans and recommends optimal yield farming opportunities
3. Automated position management with risk monitoring
4. Real-time alerts for protocol changes or security issues
5. Performance tracking with tax optimization suggestions

### 5. Institutional Research Platform

**Research Capabilities:**
- **Market Intelligence**: Comprehensive analysis across all data sources
- **Custom Analytics**: Tailored research reports and insights
- **Risk Management**: Enterprise-grade risk assessment and monitoring
- **Compliance Tools**: Regulatory reporting and audit trail maintenance
- **API Integration**: Seamless integration with existing systems

**Institutional Workflow:**
1. Access comprehensive market data and analysis tools
2. Generate custom research reports for clients or internal use
3. Monitor portfolio risk across multiple strategies and assets
4. Maintain compliance with regulatory requirements
5. Integrate insights into existing investment management systems

---

This comprehensive guide provides a complete overview of the XplainCrypto MindsDB system with enhanced user-focused features, corrected database purposes, and detailed implementation examples for all components. The system now supports a full spectrum of users from beginners to institutions with personalized experiences, social features, and advanced analytics capabilities.
