CREATE DATABASE crypto_knowledge_base
WITH ENGINE = 'chromadb',
PARAMETERS = {
  "persist_directory": "/opt/xplaincrypto/knowledge_bases/crypto_data",
  "collection_name": "crypto_market_intelligence"
}; 