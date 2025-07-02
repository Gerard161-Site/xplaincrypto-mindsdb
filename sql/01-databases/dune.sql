-- Dune Analytics Database Connection Setup
-- This script creates a database connection to Dune Analytics API

CREATE DATABASE dune_db
WITH ENGINE = 'dune',
PARAMETERS = {
    'api_key': '${DUNE_API_KEY}',
    'base_url': 'https://api.dune.com/api/v1'
}; 