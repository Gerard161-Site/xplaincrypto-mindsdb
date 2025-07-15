CREATE ML_ENGINE openai_engine
FROM openai
USING
  openai_api_key = '{{ OPENAI_API_KEY }}'; 