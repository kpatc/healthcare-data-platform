#!/bin/bash

echo "🔧 Starting services..."
docker-compose -f docker-compose-airflow.yaml up -d

echo "🔒 Fixing Docker socket permissions..."
sleep 10

# Juste fixer les permissions comme dans l'exemple GitHub
docker exec -u root pulsestack-airflow-webserver-1 /bin/bash -c "chmod 777 /var/run/docker.sock"
docker exec -u root pulsestack-airflow-scheduler-1 /bin/bash -c "chmod 777 /var/run/docker.sock" 
docker exec -u root pulsestack-airflow-worker-1 /bin/bash -c "chmod 777 /var/run/docker.sock"

echo "✅ Permissions fixed!"
echo "🌐 Airflow UI: http://localhost:8080"