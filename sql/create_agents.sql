CREATE MODEL crypto_analysis_agent
PREDICT response
USING
engine = 'anthropic',
model_name = 'claude-3-sonnet-20241022',
api_key = '{{ANTHROPIC_API_KEY}}',

CREATE MODEL crypto_prediction_agent
PREDICT prediction
USING
engine = 'openai',
model_name = 'gpt-4',
api_key = '{{OPENAI_API_KEY}}',

CREATE MODEL defi_optimization_agent
PREDICT response
USING
engine = 'anthropic',
model_name = 'claude-3-sonnet-20241022',
api_key = '{{ANTHROPIC_API_KEY}}',

CREATE MODEL risk_assessment_agent
PREDICT assessment
USING
engine = 'openai',
model_name = 'gpt-4',
api_key = '{{OPENAI_API_KEY}}',

CREATE MODEL sentiment_analysis_agent
PREDICT sentiment
USING
engine = 'openai',
model_name = 'gpt-4',
api_key = '{{OPENAI_API_KEY}}',

CREATE MODEL anomaly_detection_agent
PREDICT detection
USING
engine = 'anthropic',
model_name = 'claude-3-sonnet-20241022',
api_key = '{{ANTHROPIC_API_KEY}}', 