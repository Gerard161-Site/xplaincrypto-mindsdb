-- DeFiLlama Database Connection Setup
-- This script creates a database connection to DeFiLlama API
-- Note: DeFiLlama uses public API endpoints, no API key required

CREATE DATABASE defillama_db
WITH ENGINE = 'defillama',
PARAMETERS = {
    'base_url': 'https://api.llama.fi'
}; 