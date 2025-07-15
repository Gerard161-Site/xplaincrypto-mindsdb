CREATE ML_ENGINE anthropic_engine
FROM anthropic
USING
  anthropic_api_key = '{{ ANTHROPIC_API_KEY }}'; 