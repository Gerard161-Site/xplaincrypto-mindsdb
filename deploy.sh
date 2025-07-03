#!/bin/bash
echo "🚀 Deploying MindsDB..."
docker-compose down
docker-compose up -d --build
echo "✅ Done. Check: curl http://localhost:47334/api/status" 