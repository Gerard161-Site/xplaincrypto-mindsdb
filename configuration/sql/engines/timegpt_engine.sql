CREATE ML_ENGINE timegpt_engine
FROM nixtla
USING
  nixtla_api_key = '{{ TIMEGPT_API_KEY }}'; 