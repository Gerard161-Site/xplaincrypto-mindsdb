-- Whale Alerts Database Connection Setup
-- This script creates a database connection to Whale Alerts API

CREATE DATABASE whale_alerts_db
WITH ENGINE = 'whale_alerts',
PARAMETERS = {
    'api_key': '${WHALE_ALERTS_API_KEY}'
}; 