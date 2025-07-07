
# XplainCrypto MindsDB Troubleshooting Guide

## 🔧 Common Issues and Solutions

### 1. Database Connection Issues

#### Issue: PostgreSQL Connection Failed
**Error**: `Connection to crypto_data_db failed`
**Symptoms**: 
- Database not appearing in `SHOW DATABASES`
- Connection timeout errors
- Authentication failures

**Solutions**:
```sql
-- Test PostgreSQL connectivity
SELECT * FROM information_schema.databases WHERE name = 'crypto_data_db';

-- If missing, recreate connection:
DROP DATABASE IF EXISTS crypto_data_db;
CREATE DATABASE crypto_data_db
WITH ENGINE = 'postgres',
PARAMETERS = {
    "host": "localhost",
    "port": 5432,
    "database": "crypto_data",
    "user": "mindsdb",
    "password": "your_actual_password"
};
```

**Checklist**:
- [ ] PostgreSQL service is running
- [ ] Database `crypto_data` exists
- [ ] User `mindsdb` has proper permissions
- [ ] Password is correct
- [ ] Network connectivity to PostgreSQL

#### Issue: API Connection Failed (CoinMarketCap, Dune, etc.)
**Error**: `API authentication failed` or `Invalid API key`
**Symptoms**:
- API databases not created
- Authentication errors in logs
- Rate limit exceeded messages

**Solutions**:
```sql
-- Test API key validity by recreating connection
DROP DATABASE IF EXISTS coinmarketcap_db;
CREATE DATABASE coinmarketcap_db
WITH ENGINE = 'coinmarketcap',
PARAMETERS = {
    "api_key": "your_verified_api_key"
};

-- Test connection
SELECT * FROM information_schema.databases WHERE name = 'coinmarketcap_db';
```

**Checklist**:
- [ ] API key is active and valid
- [ ] Billing is set up (for paid APIs)
- [ ] Rate limits not exceeded
- [ ] Service is not experiencing outages
- [ ] Key has required permissions

### 2. AI Engine Issues

#### Issue: OpenAI Engine Creation Failed
**Error**: `OpenAI authentication failed` or `Insufficient credits`
**Symptoms**:
- Engine not appearing in ML engines list
- API key errors
- Credit/billing issues

**Solutions**:
```sql
-- Check if engine exists
SELECT * FROM information_schema.ml_engines WHERE name = 'openai_engine';

-- Recreate engine with verified key
DROP ML_ENGINE IF EXISTS openai_engine;
CREATE ML_ENGINE openai_engine
FROM openai
USING
    api_key = 'sk-your_verified_openai_key';

-- Test engine
CREATE MODEL test_openai
PREDICT response
USING
    engine = 'openai_engine',
    model_name = 'gpt-3.5-turbo',
    prompt_template = 'Say hello';

SELECT response FROM test_openai WHERE text = 'test';
DROP MODEL test_openai;
```

**Checklist**:
- [ ] API key starts with `sk-` and is complete
- [ ] OpenAI account has sufficient credits
- [ ] Billing method is active
- [ ] API key has not expired
- [ ] Rate limits not exceeded

#### Issue: Anthropic Engine Creation Failed
**Error**: `Anthropic authentication failed`
**Symptoms**:
- Engine creation fails
- Invalid API key messages
- Model access denied

**Solutions**:
```sql
-- Recreate Anthropic engine
DROP ML_ENGINE IF EXISTS anthropic_engine;
CREATE ML_ENGINE anthropic_engine
FROM anthropic
USING
    api_key = 'sk-ant-your_verified_anthropic_key';
```

**Checklist**:
- [ ] API key starts with `sk-ant-` and is complete
- [ ] Anthropic account has Claude access
- [ ] Billing is properly configured
- [ ] API key permissions are correct

#### Issue: TimeGPT Engine Creation Failed
**Error**: `TimeGPT authentication failed` or `Subscription required`
**Symptoms**:
- TimeGPT engine not created
- Subscription errors
- API access denied

**Solutions**:
```sql
-- Recreate TimeGPT engine
DROP ML_ENGINE IF EXISTS timegpt_engine;
CREATE ML_ENGINE timegpt_engine
FROM timegpt
USING
    api_key = 'your_verified_timegpt_key';
```

**Checklist**:
- [ ] TimeGPT account is active
- [ ] API key is valid
- [ ] Subscription plan allows API access
- [ ] Rate limits not exceeded

### 3. AI Agent Issues

#### Issue: Agent Stuck in 'Training' Status
**Error**: Agent shows `status = 'training'` for extended periods
**Symptoms**:
- Agents not completing training
- Long wait times
- No progress updates

**Solutions**:
```sql
-- Check agent status
SELECT name, status, training_log FROM information_schema.models 
WHERE name LIKE '%_agent';

-- If stuck for >5 minutes, recreate agent
DROP MODEL IF EXISTS stuck_agent_name;
-- Then re-run the agent creation script
```

**Checklist**:
- [ ] Wait at least 3-5 minutes for complex agents
- [ ] Check if underlying AI engine is working
- [ ] Verify sufficient API credits
- [ ] Monitor MindsDB system resources

#### Issue: Agent Creation Failed with Errors
**Error**: Agent shows `status = 'error'`
**Symptoms**:
- Agent creation fails immediately
- Error messages in training_log
- Engine dependency issues

**Solutions**:
```sql
-- Check error details
SELECT name, status, training_log FROM information_schema.models 
WHERE name = 'failing_agent_name';

-- Check engine dependency
SELECT m.name, m.engine, 
       CASE WHEN e.name IS NOT NULL THEN 'Available' ELSE 'Missing' END as engine_status
FROM information_schema.models m
LEFT JOIN information_schema.ml_engines e ON m.engine = e.name
WHERE m.name = 'failing_agent_name';

-- Recreate with verified engine
DROP MODEL IF EXISTS failing_agent_name;
-- Re-run agent creation script
```

**Checklist**:
- [ ] Required AI engine exists and works
- [ ] Prompt template is properly formatted
- [ ] Model parameters are valid
- [ ] Sufficient API credits available

### 4. Performance Issues

#### Issue: Slow Query Performance
**Error**: Queries taking too long to execute
**Symptoms**:
- Timeouts on agent queries
- Slow database connections
- High resource usage

**Solutions**:
```sql
-- Check active connections
SHOW PROCESSLIST;

-- Optimize queries by limiting results
SELECT analysis FROM market_analysis_agent 
WHERE symbol = 'BTC' 
LIMIT 1;

-- Check system resources
SELECT * FROM information_schema.jobs;
```

**Checklist**:
- [ ] Limit query result sets
- [ ] Check MindsDB system resources
- [ ] Monitor API rate limits
- [ ] Optimize database indexes

#### Issue: Memory or Resource Errors
**Error**: `Out of memory` or `Resource exhausted`
**Symptoms**:
- System crashes
- Failed model creation
- Connection timeouts

**Solutions**:
- Restart MindsDB service
- Reduce concurrent operations
- Increase system resources
- Optimize model parameters

### 5. Network and Connectivity Issues

#### Issue: External API Timeouts
**Error**: `Connection timeout` or `Network unreachable`
**Symptoms**:
- API connections fail intermittently
- Slow response times
- Service unavailable errors

**Solutions**:
```sql
-- Test basic connectivity
SELECT version();

-- Check handler availability
SELECT name, import_success FROM information_schema.handlers 
WHERE type = 'data';

-- Retry connection creation
-- (Re-run database connection scripts)
```

**Checklist**:
- [ ] Internet connectivity is stable
- [ ] Firewall allows outbound connections
- [ ] External services are operational
- [ ] DNS resolution is working

### 6. Data and Schema Issues

#### Issue: PostgreSQL Schema Not Created
**Error**: Tables don't exist in crypto_data database
**Symptoms**:
- Schema queries fail
- Missing tables
- Permission errors

**Solutions**:
```sql
-- Check if schema exists
SELECT schema_name FROM information_schema.schemata 
WHERE schema_name = 'crypto_data';

-- Create schema if missing
CREATE SCHEMA IF NOT EXISTS crypto_data;

-- Re-run table creation script
```

**Checklist**:
- [ ] PostgreSQL connection is working
- [ ] User has CREATE privileges
- [ ] Database has sufficient space
- [ ] Schema permissions are correct

## 🚨 Emergency Recovery Procedures

### Complete System Reset
If multiple components are failing:

```sql
-- 1. Drop all custom databases
DROP DATABASE IF EXISTS crypto_data_db;
DROP DATABASE IF EXISTS coinmarketcap_db;
DROP DATABASE IF EXISTS defillama_db;
DROP DATABASE IF EXISTS blockchain_db;
DROP DATABASE IF EXISTS dune_db;

-- 2. Drop all ML engines
DROP ML_ENGINE IF EXISTS openai_engine;
DROP ML_ENGINE IF EXISTS anthropic_engine;
DROP ML_ENGINE IF EXISTS timegpt_engine;

-- 3. Drop all agents
DROP MODEL IF EXISTS crypto_prediction_agent;
DROP MODEL IF EXISTS market_analysis_agent;
DROP MODEL IF EXISTS risk_assessment_agent;
DROP MODEL IF EXISTS sentiment_analysis_agent;
DROP MODEL IF EXISTS anomaly_detection_agent;
DROP MODEL IF EXISTS master_intelligence_agent;

-- 4. Restart deployment from step 1
```

### Partial Component Reset
For specific component issues:

```sql
-- Reset specific database connection
DROP DATABASE IF EXISTS problematic_db;
-- Re-run specific database creation script

-- Reset specific AI engine
DROP ML_ENGINE IF EXISTS problematic_engine;
-- Re-run specific engine creation script

-- Reset specific agent
DROP MODEL IF EXISTS problematic_agent;
-- Re-run specific agent creation script
```

## 📞 Getting Help

### MindsDB Resources
- Documentation: https://docs.mindsdb.com/
- Community: https://mindsdb.com/community
- GitHub Issues: https://github.com/mindsdb/mindsdb/issues

### Service-Specific Support
- OpenAI: https://help.openai.com/
- Anthropic: https://support.anthropic.com/
- CoinMarketCap: https://coinmarketcap.com/api/support/

### Diagnostic Information to Collect
When seeking help, provide:
- MindsDB version: `SELECT version();`
- Error messages from logs
- System configuration details
- Steps to reproduce the issue
- API service status and limits

## ✅ Prevention Best Practices

### Regular Maintenance
- Monitor API usage and costs
- Check system resource usage
- Verify all connections weekly
- Update API keys before expiration
- Monitor external service status

### Monitoring Setup
```sql
-- Create monitoring queries
SELECT 'System Health' as check_type,
       COUNT(*) as total_databases
FROM information_schema.databases;

SELECT 'Engine Health' as check_type,
       COUNT(*) as total_engines
FROM information_schema.ml_engines;

SELECT 'Agent Health' as check_type,
       COUNT(*) as total_agents,
       COUNT(CASE WHEN status = 'complete' THEN 1 END) as ready_agents
FROM information_schema.models
WHERE name LIKE '%_agent';
```

Remember: Most issues are related to API keys, network connectivity, or resource constraints. Always verify these basics first!
