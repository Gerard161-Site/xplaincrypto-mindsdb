
#!/bin/bash

# XplainCrypto MindsDB Prerequisites Setup Script
# This script sets up all necessary prerequisites for the MindsDB implementation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root for security reasons"
        exit 1
    fi
}

# Check system requirements
check_system_requirements() {
    log "Checking system requirements..."
    
    # Check OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        success "Linux OS detected"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        success "macOS detected"
    else
        error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    # Check available memory
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    else
        MEMORY_GB=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    fi
    
    if [[ $MEMORY_GB -lt 4 ]]; then
        warning "System has less than 4GB RAM. MindsDB may run slowly."
    else
        success "Memory check passed: ${MEMORY_GB}GB available"
    fi
    
    # Check available disk space
    DISK_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ ${DISK_SPACE%.*} -lt 10 ]]; then
        warning "Less than 10GB disk space available. Consider freeing up space."
    else
        success "Disk space check passed: ${DISK_SPACE} available"
    fi
}

# Install system dependencies
install_system_dependencies() {
    log "Installing system dependencies..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Update package list
        sudo apt-get update
        
        # Install essential packages
        sudo apt-get install -y \
            curl \
            wget \
            git \
            python3 \
            python3-pip \
            python3-venv \
            nodejs \
            npm \
            mysql-client \
            docker.io \
            docker-compose \
            jq \
            unzip \
            build-essential
            
        # Add user to docker group
        sudo usermod -aG docker $USER
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            log "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        # Install packages via Homebrew
        brew install \
            curl \
            wget \
            git \
            python3 \
            node \
            mysql-client \
            docker \
            docker-compose \
            jq
    fi
    
    success "System dependencies installed"
}

# Setup Python environment
setup_python_environment() {
    log "Setting up Python environment..."
    
    # Create virtual environment
    python3 -m venv venv
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install Python dependencies
    cat > requirements.txt << EOF
mysql-connector-python==8.2.0
pandas==2.1.4
numpy==1.24.3
aiohttp==3.9.1
asyncio==3.4.3
pyyaml==6.0.1
requests==2.31.0
python-dotenv==1.0.0
sqlalchemy==2.0.23
pymongo==4.6.0
redis==5.0.1
celery==5.3.4
fastapi==0.104.1
uvicorn==0.24.0
pytest==7.4.3
pytest-asyncio==0.21.1
plotly==5.17.0
jupyter==1.0.0
scikit-learn==1.3.2
EOF
    
    pip install -r requirements.txt
    
    success "Python environment setup complete"
}

# Setup Node.js environment
setup_nodejs_environment() {
    log "Setting up Node.js environment..."
    
    # Install n8n globally
    npm install -g n8n
    
    # Create package.json for local dependencies
    cat > package.json << EOF
{
  "name": "xplaincrypto-mindsdb",
  "version": "1.0.0",
  "description": "XplainCrypto MindsDB Implementation",
  "scripts": {
    "start": "n8n start",
    "dev": "n8n start --tunnel"
  },
  "dependencies": {
    "n8n": "^1.19.0"
  }
}
EOF
    
    npm install
    
    success "Node.js environment setup complete"
}

# Setup MindsDB
setup_mindsdb() {
    log "Setting up MindsDB..."
    
    # Create MindsDB directory
    mkdir -p mindsdb_data
    
    # Create docker-compose.yml for MindsDB
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  mindsdb:
    image: mindsdb/mindsdb:latest
    container_name: xplaincrypto_mindsdb
    ports:
      - "47334:47334"
      - "47335:47335"
    volumes:
      - ./mindsdb_data:/root/mindsdb_storage
      - ./sql:/sql
      - ./data_sync:/data_sync
    environment:
      - MINDSDB_STORAGE_PATH=/root/mindsdb_storage
      - MINDSDB_CONFIG_PATH=/root/mindsdb_storage/config.json
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:47334/api/status"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  mysql:
    image: mysql:8.0
    container_name: xplaincrypto_mysql
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=xplaincrypto_root_2024
      - MYSQL_DATABASE=crypto_data_db
      - MYSQL_USER=xplaincrypto
      - MYSQL_PASSWORD=xplaincrypto_pass_2024
    volumes:
      - mysql_data:/var/lib/mysql
      - ./sql/init:/docker-entrypoint-initdb.d
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: xplaincrypto_redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped

  mongodb:
    image: mongo:7
    container_name: xplaincrypto_mongodb
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_ROOT_USERNAME=xplaincrypto
      - MONGO_INITDB_ROOT_PASSWORD=xplaincrypto_mongo_2024
    volumes:
      - mongodb_data:/data/db
    restart: unless-stopped

volumes:
  mysql_data:
  redis_data:
  mongodb_data:
EOF
    
    success "MindsDB docker-compose configuration created"
}

# Create configuration files
create_configuration_files() {
    log "Creating configuration files..."
    
    # Create MindsDB config
    mkdir -p mindsdb_data
    cat > mindsdb_data/config.json << EOF
{
    "api": {
        "http": {
            "host": "0.0.0.0",
            "port": "47334"
        },
        "mysql": {
            "host": "0.0.0.0",
            "port": "47335",
            "user": "mindsdb",
            "password": "",
            "database": "mindsdb",
            "ssl": false
        }
    },
    "storage": {
        "db": {
            "type": "sqlite",
            "path": "/root/mindsdb_storage/mindsdb.sqlite3"
        }
    },
    "debug": false,
    "integrations": {
        "default_mysql": {
            "enabled": true,
            "host": "mysql",
            "port": 3306,
            "user": "xplaincrypto",
            "password": "xplaincrypto_pass_2024",
            "database": "crypto_data_db"
        }
    },
    "jobs": {
        "disable": false,
        "check_interval": 30
    }
}
EOF
    
    # Create environment file
    cat > .env << EOF
# XplainCrypto MindsDB Environment Configuration

# Database Configuration
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=xplaincrypto
MYSQL_PASSWORD=xplaincrypto_pass_2024
MYSQL_DATABASE=crypto_data_db

# MindsDB Configuration
MINDSDB_HOST=localhost
MINDSDB_PORT=47334
MINDSDB_USER=mindsdb
MINDSDB_PASSWORD=

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# MongoDB Configuration
MONGODB_HOST=localhost
MONGODB_PORT=27017
MONGODB_USER=xplaincrypto
MONGODB_PASSWORD=xplaincrypto_mongo_2024

# API Keys (Replace with actual keys)
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here
COINMARKETCAP_API_KEY=your_coinmarketcap_api_key_here
BINANCE_API_KEY=your_binance_api_key_here
BINANCE_SECRET_KEY=your_binance_secret_key_here

# N8N Configuration
N8N_HOST=localhost
N8N_PORT=5678
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=xplaincrypto_n8n_2024

# Notification Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_app_password
NOTIFICATION_EMAIL=admin@xplaincrypto.com

# Slack Configuration (Optional)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
EOF
    
    # Create database initialization script
    mkdir -p sql/init
    cat > sql/init/01_create_databases.sql << EOF
-- Create databases for XplainCrypto MindsDB implementation

CREATE DATABASE IF NOT EXISTS crypto_data_db;
CREATE DATABASE IF NOT EXISTS user_data_db;
CREATE DATABASE IF NOT EXISTS fastapi_ops_db;

-- Create user for MindsDB access
CREATE USER IF NOT EXISTS 'mindsdb_user'@'%' IDENTIFIED BY 'mindsdb_pass_2024';
GRANT ALL PRIVILEGES ON crypto_data_db.* TO 'mindsdb_user'@'%';
GRANT ALL PRIVILEGES ON user_data_db.* TO 'mindsdb_user'@'%';
GRANT ALL PRIVILEGES ON fastapi_ops_db.* TO 'mindsdb_user'@'%';

-- Create basic tables structure
USE crypto_data_db;

CREATE TABLE IF NOT EXISTS deployment_log (
    deployment_id VARCHAR(100) PRIMARY KEY,
    status VARCHAR(50),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    components TEXT,
    components_deployed INT,
    test_results TEXT,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sync_tracking (
    id INT AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20),
    source VARCHAR(50),
    last_sync TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_symbol_source (symbol, source)
);

CREATE TABLE IF NOT EXISTS cost_optimization_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    optimization_date TIMESTAMP,
    total_optimizations INT,
    high_priority_count INT,
    estimated_monthly_savings DECIMAL(10,2),
    actions_executed TEXT,
    optimization_report JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS monitoring_dashboard_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp TIMESTAMP,
    health_score INT,
    status VARCHAR(50),
    alerts_count INT,
    warnings_count INT,
    active_users INT,
    total_interactions INT,
    dashboard_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

FLUSH PRIVILEGES;
EOF
    
    success "Configuration files created"
}

# Setup directory structure
setup_directory_structure() {
    log "Setting up directory structure..."
    
    # Create necessary directories
    mkdir -p {logs,backups,temp,data,exports}
    mkdir -p sql/init
    mkdir -p tests/{datasets,scenarios,reports}
    mkdir -p docs/{api,guides,troubleshooting}
    mkdir -p scripts/{backup,monitoring,maintenance}
    
    # Create log directories
    mkdir -p logs/{mindsdb,n8n,application,errors}
    
    # Set permissions
    chmod +x scripts/*.sh 2>/dev/null || true
    
    success "Directory structure created"
}

# Create startup scripts
create_startup_scripts() {
    log "Creating startup scripts..."
    
    # Create start script
    cat > scripts/start_services.sh << 'EOF'
#!/bin/bash

# XplainCrypto MindsDB Services Startup Script

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log "Starting XplainCrypto MindsDB services..."

# Start Docker services
log "Starting Docker services..."
docker-compose up -d

# Wait for services to be ready
log "Waiting for services to be ready..."
sleep 30

# Check MindsDB health
log "Checking MindsDB health..."
for i in {1..10}; do
    if curl -f http://localhost:47334/api/status >/dev/null 2>&1; then
        success "MindsDB is ready"
        break
    fi
    log "Waiting for MindsDB... (attempt $i/10)"
    sleep 10
done

# Check MySQL health
log "Checking MySQL health..."
for i in {1..10}; do
    if mysql -h localhost -P 3306 -u xplaincrypto -pxplaincrypto_pass_2024 -e "SELECT 1" >/dev/null 2>&1; then
        success "MySQL is ready"
        break
    fi
    log "Waiting for MySQL... (attempt $i/10)"
    sleep 5
done

# Start N8N (optional)
if command -v n8n &> /dev/null; then
    log "Starting N8N..."
    nohup n8n start > logs/n8n/n8n.log 2>&1 &
    echo $! > logs/n8n/n8n.pid
    success "N8N started in background"
fi

success "All services started successfully!"
log "Services available at:"
log "  - MindsDB: http://localhost:47334"
log "  - MySQL: localhost:3306"
log "  - N8N: http://localhost:5678 (if started)"
log "  - Redis: localhost:6379"
log "  - MongoDB: localhost:27017"
EOF

    # Create stop script
    cat > scripts/stop_services.sh << 'EOF'
#!/bin/bash

# XplainCrypto MindsDB Services Stop Script

set -e

# Colors
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${RED}[STOPPED]${NC} $1"
}

log "Stopping XplainCrypto MindsDB services..."

# Stop N8N if running
if [ -f logs/n8n/n8n.pid ]; then
    log "Stopping N8N..."
    kill $(cat logs/n8n/n8n.pid) 2>/dev/null || true
    rm -f logs/n8n/n8n.pid
    success "N8N stopped"
fi

# Stop Docker services
log "Stopping Docker services..."
docker-compose down

success "All services stopped"
EOF

    # Create status check script
    cat > scripts/check_status.sh << 'EOF'
#!/bin/bash

# XplainCrypto MindsDB Services Status Check Script

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_service() {
    local service_name=$1
    local host=$2
    local port=$3
    local protocol=${4:-tcp}
    
    if nc -z $host $port 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $service_name is running ($host:$port)"
        return 0
    else
        echo -e "${RED}✗${NC} $service_name is not accessible ($host:$port)"
        return 1
    fi
}

check_http_service() {
    local service_name=$1
    local url=$2
    
    if curl -f $url >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $service_name is responding ($url)"
        return 0
    else
        echo -e "${RED}✗${NC} $service_name is not responding ($url)"
        return 1
    fi
}

echo -e "${BLUE}XplainCrypto MindsDB Services Status${NC}"
echo "================================================"

# Check Docker services
echo -e "\n${YELLOW}Docker Services:${NC}"
docker-compose ps

echo -e "\n${YELLOW}Service Connectivity:${NC}"
check_service "MySQL" "localhost" "3306"
check_service "Redis" "localhost" "6379"
check_service "MongoDB" "localhost" "27017"
check_service "MindsDB" "localhost" "47334"
check_service "MindsDB MySQL" "localhost" "47335"

echo -e "\n${YELLOW}HTTP Services:${NC}"
check_http_service "MindsDB API" "http://localhost:47334/api/status"

if [ -f logs/n8n/n8n.pid ]; then
    check_http_service "N8N" "http://localhost:5678"
else
    echo -e "${YELLOW}!${NC} N8N is not running"
fi

echo -e "\n${YELLOW}Disk Usage:${NC}"
df -h . | head -2

echo -e "\n${YELLOW}Memory Usage:${NC}"
free -h | head -2

echo ""
EOF

    # Make scripts executable
    chmod +x scripts/*.sh
    
    success "Startup scripts created"
}

# Create backup script
create_backup_script() {
    log "Creating backup script..."
    
    cat > scripts/backup/backup_system.sh <
