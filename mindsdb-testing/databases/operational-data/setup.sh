
#!/bin/bash

# Operational Data Database Setup Script
# Sets up the operational data database for system monitoring and analytics

set -e

echo "⚙️ Setting up Operational Data Database..."

# Configuration
DATABASE_NAME="operational_data"

# Create database SQL
cat > create_database.sql << 'EOF'
-- Create Operational Data Database
CREATE DATABASE IF NOT EXISTS operational_data;
USE operational_data;

-- System metrics table
CREATE TABLE IF NOT EXISTS system_metrics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(20,4) NOT NULL,
    metric_unit VARCHAR(20),
    component VARCHAR(50) NOT NULL,
    hostname VARCHAR(100),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_metric_name (metric_name),
    INDEX idx_component (component),
    INDEX idx_timestamp (timestamp),
    INDEX idx_component_timestamp (component, timestamp)
);

-- API usage tracking
CREATE TABLE IF NOT EXISTS api_usage (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    endpoint VARCHAR(200) NOT NULL,
    method VARCHAR(10) NOT NULL,
    user_id BIGINT,
    ip_address VARCHAR(45),
    response_code INT NOT NULL,
    response_time_ms INT NOT NULL,
    request_size_bytes INT,
    response_size_bytes INT,
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_endpoint (endpoint),
    INDEX idx_user_id (user_id),
    INDEX idx_response_code (response_code),
    INDEX idx_timestamp (timestamp)
);

-- Error logs
CREATE TABLE IF NOT EXISTS error_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    error_level ENUM('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL') NOT NULL,
    component VARCHAR(50) NOT NULL,
    error_message TEXT NOT NULL,
    error_code VARCHAR(50),
    stack_trace TEXT,
    user_id BIGINT,
    session_id VARCHAR(255),
    request_id VARCHAR(255),
    hostname VARCHAR(100),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_error_level (error_level),
    INDEX idx_component (component),
    INDEX idx_timestamp (timestamp),
    INDEX idx_error_code (error_code)
);

-- Data pipeline status
CREATE TABLE IF NOT EXISTS pipeline_status (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    pipeline_name VARCHAR(100) NOT NULL,
    pipeline_type ENUM('data_ingestion', 'data_processing', 'data_export', 'maintenance') NOT NULL,
    status ENUM('running', 'completed', 'failed', 'paused') NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NULL,
    records_processed BIGINT DEFAULT 0,
    records_failed BIGINT DEFAULT 0,
    error_message TEXT,
    configuration JSON,
    INDEX idx_pipeline_name (pipeline_name),
    INDEX idx_pipeline_type (pipeline_type),
    INDEX idx_status (status),
    INDEX idx_start_time (start_time)
);

-- Handler performance metrics
CREATE TABLE IF NOT EXISTS handler_metrics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    handler_name VARCHAR(50) NOT NULL,
    operation_type VARCHAR(50) NOT NULL,
    execution_time_ms INT NOT NULL,
    records_processed INT DEFAULT 0,
    success BOOLEAN NOT NULL,
    error_message TEXT,
    memory_usage_mb DECIMAL(10,2),
    cpu_usage_percent DECIMAL(5,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_handler_name (handler_name),
    INDEX idx_operation_type (operation_type),
    INDEX idx_success (success),
    INDEX idx_timestamp (timestamp)
);

-- Alert history
CREATE TABLE IF NOT EXISTS alert_history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    alert_type VARCHAR(50) NOT NULL,
    alert_level ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    component VARCHAR(50),
    metric_name VARCHAR(100),
    threshold_value DECIMAL(20,4),
    actual_value DECIMAL(20,4),
    status ENUM('active', 'acknowledged', 'resolved') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    acknowledged_at TIMESTAMP NULL,
    resolved_at TIMESTAMP NULL,
    acknowledged_by VARCHAR(100),
    resolved_by VARCHAR(100),
    INDEX idx_alert_type (alert_type),
    INDEX idx_alert_level (alert_level),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- Job scheduler
CREATE TABLE IF NOT EXISTS scheduled_jobs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    job_name VARCHAR(100) NOT NULL UNIQUE,
    job_type VARCHAR(50) NOT NULL,
    schedule_expression VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_run TIMESTAMP NULL,
    next_run TIMESTAMP NULL,
    last_status ENUM('success', 'failed', 'running') NULL,
    last_duration_ms INT NULL,
    failure_count INT DEFAULT 0,
    max_failures INT DEFAULT 3,
    configuration JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_job_name (job_name),
    INDEX idx_job_type (job_type),
    INDEX idx_is_active (is_active),
    INDEX idx_next_run (next_run)
);
EOF

# Create views SQL
cat > create_views.sql << 'EOF'
-- Operational Data Views
USE operational_data;

-- System health overview
CREATE OR REPLACE VIEW system_health AS
SELECT 
    component,
    COUNT(CASE WHEN metric_name = 'cpu_usage' AND metric_value > 80 THEN 1 END) as high_cpu_alerts,
    COUNT(CASE WHEN metric_name = 'memory_usage' AND metric_value > 85 THEN 1 END) as high_memory_alerts,
    COUNT(CASE WHEN metric_name = 'disk_usage' AND metric_value > 90 THEN 1 END) as high_disk_alerts,
    AVG(CASE WHEN metric_name = 'response_time' THEN metric_value END) as avg_response_time,
    MAX(timestamp) as last_updated
FROM system_metrics
WHERE timestamp > NOW() - INTERVAL 1 HOUR
GROUP BY component;

-- API performance summary
CREATE OR REPLACE VIEW api_performance AS
SELECT 
    endpoint,
    method,
    COUNT(*) as total_requests,
    COUNT(CASE WHEN response_code >= 200 AND response_code < 300 THEN 1 END) as successful_requests,
    COUNT(CASE WHEN response_code >= 400 THEN 1 END) as error_requests,
    AVG(response_time_ms) as avg_response_time,
    MAX(response_time_ms) as max_response_time,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time_ms) as p95_response_time
FROM api_usage
WHERE timestamp > NOW() - INTERVAL 24 HOUR
GROUP BY endpoint, method
ORDER BY total_requests DESC;

-- Error summary
CREATE OR REPLACE VIEW error_summary AS
SELECT 
    component,
    error_level,
    COUNT(*) as error_count,
    COUNT(DISTINCT error_code) as unique_error_codes,
    MAX(timestamp) as last_occurrence,
    GROUP_CONCAT(DISTINCT error_code ORDER BY error_code SEPARATOR ', ') as error_codes
FROM error_logs
WHERE timestamp > NOW() - INTERVAL 24 HOUR
GROUP BY component, error_level
ORDER BY error_count DESC;

-- Pipeline health
CREATE OR REPLACE VIEW pipeline_health AS
SELECT 
    pipeline_name,
    pipeline_type,
    COUNT(*) as total_runs,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as successful_runs,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_runs,
    AVG(TIMESTAMPDIFF(SECOND, start_time, end_time)) as avg_duration_seconds,
    MAX(start_time) as last_run,
    SUM(records_processed) as total_records_processed,
    SUM(records_failed) as total_records_failed
FROM pipeline_status
WHERE start_time > NOW() - INTERVAL 7 DAY
GROUP BY pipeline_name, pipeline_type
ORDER BY failed_runs DESC, total_runs DESC;

-- Handler performance overview
CREATE OR REPLACE VIEW handler_performance AS
SELECT 
    handler_name,
    operation_type,
    COUNT(*) as total_operations,
    COUNT(CASE WHEN success = TRUE THEN 1 END) as successful_operations,
    AVG(execution_time_ms) as avg_execution_time,
    AVG(memory_usage_mb) as avg_memory_usage,
    AVG(cpu_usage_percent) as avg_cpu_usage,
    MAX(timestamp) as last_operation
FROM handler_metrics
WHERE timestamp > NOW() - INTERVAL 24 HOUR
GROUP BY handler_name, operation_type
ORDER BY total_operations DESC;

-- Active alerts
CREATE OR REPLACE VIEW active_alerts AS
SELECT 
    alert_type,
    alert_level,
    title,
    description,
    component,
    actual_value,
    threshold_value,
    created_at,
    TIMESTAMPDIFF(MINUTE, created_at, NOW()) as minutes_active
FROM alert_history
WHERE status = 'active'
ORDER BY alert_level DESC, created_at ASC;

-- Job scheduler status
CREATE OR REPLACE VIEW job_status AS
SELECT 
    job_name,
    job_type,
    is_active,
    schedule_expression,
    last_run,
    next_run,
    last_status,
    last_duration_ms,
    failure_count,
    CASE 
        WHEN failure_count >= max_failures THEN 'DISABLED'
        WHEN last_status = 'failed' THEN 'FAILING'
        WHEN last_status = 'running' THEN 'RUNNING'
        WHEN is_active = TRUE THEN 'HEALTHY'
        ELSE 'INACTIVE'
    END as health_status
FROM scheduled_jobs
ORDER BY failure_count DESC, next_run ASC;
EOF

# Execute setup
execute_setup() {
    echo "Creating operational data database and tables..."
    
    # Execute SQL commands
    if command -v mysql &> /dev/null; then
        mysql -u root -p < create_database.sql
        mysql -u root -p < create_views.sql
        echo "✅ Operational data database created successfully"
    elif command -v mindsdb &> /dev/null; then
        mindsdb -f create_database.sql
        mindsdb -f create_views.sql
        echo "✅ Operational data database created via MindsDB"
    else
        echo "⚠️  Neither MySQL nor MindsDB CLI found. SQL files created for manual execution."
    fi
}

# Validation
validate_setup() {
    echo "Validating operational data database setup..."
    
    cat > validate.sql << 'EOF'
-- Validation queries
USE operational_data;
SHOW TABLES;
DESCRIBE system_metrics;
DESCRIBE api_usage;
DESCRIBE error_logs;
SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = 'operational_data';
EOF
    
    if command -v mysql &> /dev/null; then
        mysql -u root -p < validate.sql
        echo "✅ Validation completed"
    elif command -v mindsdb &> /dev/null; then
        mindsdb -f validate.sql
        echo "✅ Validation completed via MindsDB"
    else
        echo "⚠️  Manual validation required"
    fi
}

# Main execution
main() {
    execute_setup
    validate_setup
    echo "🎉 Operational data database setup completed!"
}

main "$@"
