CREATE MODEL IF NOT EXISTS crypto_prediction_agent_v2
PREDICT price_forecast
USING
  engine = 'nixtla',
  model = 'timegpt-1',
  nixtla_api_key = '{{ TIMEGPT_API_KEY }}',
  horizon = 24,
  frequency = 'H',
  confidence_level = 0.95; 