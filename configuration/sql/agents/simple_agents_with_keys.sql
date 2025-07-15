CREATE MODEL IF NOT EXISTS crypto_analysis_agent
PREDICT analysis
USING
  engine = 'anthropic',
  model_name = 'claude-3-sonnet-20240229',
  anthropic_api_key = '{{ ANTHROPIC_API_KEY }}',
  prompt_template = 'Analyze the following cryptocurrency data: Symbol: {{symbol}} Current Price: ${{price}} 24h Change: {{change_24h}}% Volume: ${{volume}} Market Cap: {{market_cap}} Additional Context: {{context}} Provide a comprehensive analysis including: 1. Technical analysis with support/resistance levels 2. Market sentiment assessment 3. Key price levels to watch 4. Short-term outlook (24-48 hours) 5. Risk factors and considerations Be specific with price levels and percentages.',
  temperature = 0.7,
  max_tokens = 1500; 