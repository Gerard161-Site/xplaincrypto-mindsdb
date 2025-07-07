# XplainCrypto PostgreSQL Databases Deployment Guide

## 🎯 Overview
This guide covers the deployment and connection of all 3 PostgreSQL databases in the XplainCrypto infrastructure.

## 📊 Database Architecture

### **Database 1: Crypto Data (Port 5432)**
- **Purpose**: Historical crypto data, AI training data, market analysis
- **User**: mindsdb
- **Status**: ✅ WORKING - Connected to MindsDB

### **Database 2: User Data (Port 5433)**  
- **Purpose**: User accounts, portfolios, social features, educational content
- **User**: xplaincrypto
- **Status**: ❌ CONTAINER NOT RUNNING

### **Database 3: Operational Data (Port 5434)**
- **Purpose**: FastAPI logs, sessions, caching, operational metrics  
- **User**: fastapi
- **Status**: ❌ CONTAINER NOT RUNNING

## 🚀 Deployment Status

### ✅ **SUCCESSFULLY DEPLOYED:**
- **crypto_data_db** - Connected and verified via MindsDB

### ⚠️ **PENDING DEPLOYMENT:**
- **user_data_db** - Requires xplaincrypto-user-database container
- **operational_data_db** - Requires xplaincrypto-fastapi postgres container

## 🔧 **Working Connection Details**

### Database 1 (crypto_data_db) - ✅ VERIFIED WORKING
```
Host: 142.93.49.20
Port: 5432
Database: crypto_data
User: mindsdb
Password: rfmveurVyThziPsujMdMsnya6JNirlz8nFrcH34o9Xs=
Schema: public
sslmode: disable
```

### Database 2 (user_data_db) - ⚠️ READY TO DEPLOY
```
Host: 142.93.49.20
Port: 5433
Database: user_data
User: xplaincrypto
Password: rfmveurVyThziPsujMdMsnya6JNirlz8nFrcH34o9Xs=
Schema: public
sslmode: disable
```

### Database 3 (operational_data_db) - ⚠️ READY TO DEPLOY
```
Host: 142.93.49.20
Port: 5434
Database: operational_data
User: fastapi
Password: rfmveurVyThziPsujMdMsnya6JNirlz8nFrcH34o9Xs=
Schema: public
sslmode: disable
```

## 🔨 **Deployment Commands**

### **Option 1: Manual (MindsDB Editor)**
Copy and paste `postgresql_connections_complete.sql` into http://142.93.49.20:47334/editor

### **Option 2: Curl (Automated)**

#### Database 1 (Working):
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"query":"CREATE DATABASE IF NOT EXISTS crypto_data_db WITH ENGINE = \"postgres\", PARAMETERS = {\"host\": \"142.93.49.20\", \"port\": 5432, \"database\": \"crypto_data\", \"user\": \"mindsdb\", \"password\": \"rfmveurVyThziPsujMdMsnya6JNirlz8nFrcH34o9Xs=\"};"}' \
  http://142.93.49.20:47334/api/sql/query
```

#### Database 2 (When container is running):
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"query":"CREATE DATABASE IF NOT EXISTS user_data_db WITH ENGINE = \"postgres\", PARAMETERS = {\"host\": \"142.93.49.20\", \"port\": 5433, \"database\": \"user_data\", \"user\": \"xplaincrypto\", \"password\": \"rfmveurVyThziPsujMdMsnya6JNirlz8nFrcH34o9Xs=\"};"}' \
  http://142.93.49.20:47334/api/sql/query
```

#### Database 3 (When container is running):
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"query":"CREATE DATABASE IF NOT EXISTS operational_data_db WITH ENGINE = \"postgres\", PARAMETERS = {\"host\": \"142.93.49.20\", \"port\": 5434, \"database\": \"operational_data\", \"user\": \"fastapi\", \"password\": \"rfmveurVyThziPsujMdMsnya6JNirlz8nFrcH34o9Xs=\"};"}' \
  http://142.93.49.20:47334/api/sql/query
```

## 🔍 **Verification Commands**

### Check All PostgreSQL Connections:
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT name, engine FROM information_schema.databases WHERE name LIKE \"%data_db\" ORDER BY name;"}' \
  http://142.93.49.20:47334/api/sql/query
```

### Expected Output (When All Working):
```
crypto_data_db (postgres)
operational_data_db (postgres) 
user_data_db (postgres)
```

## 🚨 **Troubleshooting**

### **Issue**: Database 2 & 3 Connection Timeout
**Cause**: PostgreSQL containers not running on ports 5433 and 5434

**Solution**: Start the required containers:
```bash
# Start user database container
cd xplaincrypto-user-database
docker-compose up -d

# Start FastAPI postgres container  
cd xplaincrypto-fastapi
docker-compose up -d postgres
```

### **Issue**: Password Authentication Failed
**Cause**: Incorrect password or user

**Solution**: Use the verified working password:
`rfmveurVyThziPsujMdMsnya6JNirlz8nFrcH34o9Xs=`

## 📈 **Next Steps**

### **Immediate (Database 1 Working):**
1. ✅ crypto_data_db connection established
2. ✅ Can proceed with AI agents that use crypto data
3. ✅ Can create historical data schema

### **Pending (Databases 2 & 3):**
1. Start xplaincrypto-user-database container
2. Start xplaincrypto-fastapi postgres container  
3. Test Database 2 & 3 connections
4. Complete full 3-database integration

## 🎯 **Success Criteria**

**Current Status**: 1/3 PostgreSQL databases connected ✅
**Target Status**: 3/3 PostgreSQL databases connected

**When complete, MindsDB will have access to:**
- Historical crypto data and AI training data
- User accounts, portfolios, and social features  
- FastAPI operational data and logs

**Ready for the next phase of deployment!** 