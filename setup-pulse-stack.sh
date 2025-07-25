#!/usr/bin/env bash

# Pulse Stack Setup Script
# Basé sur modern-data-stack-demo avec adaptations healthcare

up() {
  echo "🚀 Starting Pulse Stack - Modern Healthcare Data Platform"
  echo "========================================================"
  
  # Create necessary directories
  echo "📁 Creating directories..."
  mkdir -p ./dags ./logs ./plugins ./temporal/dynamicconfig
  mkdir -p ./superset ./dbt ./great_expectations ./postgres/init-scripts
  mkdir -p /tmp/airbyte_local
  
  # Set proper permissions for Airflow
  echo "🔧 Setting Airflow permissions..."
  echo -e "AIRFLOW_UID=$(id -u)\nAIRFLOW_GID=0" >> .env
  
  # Start Pulse Components (MinIO, PostgreSQL, Superset, dbt, Great Expectations)
  echo ""
  echo "🏥 Starting Pulse Healthcare Components..."
  docker-compose -f docker-compose-pulse-components.yaml down -v
  docker-compose -f docker-compose-pulse-components.yaml up -d
  
  echo "⏳ Waiting for Pulse components to initialize (30s)..."
  sleep 30
  
  # Start Airbyte
  echo ""
  echo "🔄 Starting Airbyte..."
  docker-compose -f docker-compose-airbyte.yaml down -v
  docker-compose -f docker-compose-airbyte.yaml up -d
  
  echo "⏳ Waiting for Airbyte to initialize (60s)..."
  sleep 60

  # Start Airflow
  echo ""
  echo "🌪️ Starting Airflow..."
  docker-compose -f docker-compose-airflow.yaml down -v
  docker-compose -f docker-compose-airflow.yaml up airflow-init
  docker-compose -f docker-compose-airflow.yaml up -d
  
  echo "⏳ Waiting for Airflow to initialize (45s)..."
  sleep 45
  
  echo ""
  echo "🎉 Pulse Stack is starting up!"
  echo ""
  echo "📋 Service Access Information:"
  echo "=============================="
  echo "🔄 Airbyte:    http://localhost:8000"
  echo "🌪️ Airflow:    http://localhost:8080 (airflow/airflow)"
  echo "📊 Superset:   http://localhost:8088 (admin/admin)"
  echo "🪣 MinIO:      http://localhost:9001 (minio/minio123)"
  echo "🗄️ PostgreSQL: localhost:5433 (admin/admin)"
  echo ""
  echo "💡 Next Steps:"
  echo "1. Access Airbyte at http://localhost:8000 and set up a connection"
  echo "2. Configure your data sources and destinations"
  echo "3. Note your Airbyte connection ID for Airflow integration"
  echo ""
  
  # Interactive setup for Airbyte connection
  echo "🔗 Airbyte Connection Setup"
  echo "=========================="
  echo "Please:"
  echo "1. Go to http://localhost:8000"
  echo "2. Create a source (e.g., PostgreSQL, CSV, API)"
  echo "3. Create a destination (MinIO or PostgreSQL)"
  echo "4. Set up a connection and note the Connection ID"
  echo ""
  echo "Enter your Airbyte connection ID (or press Enter to skip): "
  read connection_id
  
  if [ ! -z "$connection_id" ]; then
    echo "🔧 Configuring Airflow with Airbyte connection..."
    # Set connection ID for DAG
    docker-compose -f docker-compose-airflow.yaml run --rm airflow-webserver airflow variables set 'AIRBYTE_CONNECTION_ID' "$connection_id"
    docker-compose -f docker-compose-airflow.yaml run --rm airflow-webserver airflow connections add 'airbyte_default' --conn-uri 'airbyte://host.docker.internal:8000'
    echo "✅ Airflow configured with Airbyte connection ID: $connection_id"
  else
    echo "⏭️ Skipping Airbyte connection setup. You can configure it later in Airflow."
  fi

  echo ""
  echo "🎯 Pulse Stack Healthcare Data Platform is Ready!"
  echo "================================================="
  echo ""
  echo "🏥 Healthcare Data Architecture:"
  echo "• Bronze Layer: Raw data in MinIO + PostgreSQL"
  echo "• Silver Layer: Cleaned data with dbt transformations"
  echo "• Gold Layer: Business metrics and KPIs"
  echo ""
  echo "📊 Available Services:"
  echo "• Airbyte: Data ingestion from 100+ sources"
  echo "• Airflow: Pipeline orchestration and scheduling"
  echo "• Superset: BI dashboards and visualizations"
  echo "• MinIO: Object storage for data lake"
  echo "• dbt: Data transformations and modeling"
  echo "• Great Expectations: Data quality validation"
  echo ""
  echo "🔧 Management Commands:"
  echo "• View status: docker-compose -f docker-compose-pulse-components.yaml ps"
  echo "• View logs: docker-compose -f docker-compose-[service].yaml logs -f [container]"
  echo "• Stop all: ./setup-pulse-stack.sh down"
}

down() {
  echo "🛑 Stopping Pulse Stack..."
  echo "=========================="
  
  echo "Stopping Airflow..."
  docker-compose -f docker-compose-airflow.yaml down -v
  
  echo "Stopping Airbyte..."
  docker-compose -f docker-compose-airbyte.yaml down -v
  
  echo "Stopping Pulse Components..."
  docker-compose -f docker-compose-pulse-components.yaml down -v
  
  echo "✅ Pulse Stack stopped successfully."
}

status() {
  echo "📊 Pulse Stack Status"
  echo "===================="
  echo ""
  echo "🏥 Pulse Components:"
  docker-compose -f docker-compose-pulse-components.yaml ps
  echo ""
  echo "🔄 Airbyte:"
  docker-compose -f docker-compose-airbyte.yaml ps
  echo ""
  echo "🌪️ Airflow:"
  docker-compose -f docker-compose-airflow.yaml ps
}

logs() {
  echo "📋 Recent logs from all services:"
  echo "================================="
  echo ""
  echo "🏥 Pulse Components:"
  docker-compose -f docker-compose-pulse-components.yaml logs --tail 5
  echo ""
  echo "🔄 Airbyte:"
  docker-compose -f docker-compose-airbyte.yaml logs --tail 5
  echo ""
  echo "🌪️ Airflow:"
  docker-compose -f docker-compose-airflow.yaml logs --tail 5
}

case $1 in
  up)
    up
    ;;
  down)
    down
    ;;
  status)
    status
    ;;
  logs)
    logs
    ;;
  *)
    echo "🚀 Pulse Stack - Modern Healthcare Data Platform"
    echo "==============================================="
    echo ""
    echo "Usage: $0 {up|down|status|logs}"
    echo ""
    echo "Commands:"
    echo "  up     - Start all Pulse Stack services"
    echo "  down   - Stop all Pulse Stack services"
    echo "  status - Show status of all services"
    echo "  logs   - Show recent logs from all services"
    echo ""
    echo "Services included:"
    echo "• Airbyte (Data Ingestion)"
    echo "• Airflow (Orchestration)"
    echo "• Superset (Visualization)"
    echo "• MinIO (Data Lake)"
    echo "• dbt (Transformations)"
    echo "• Great Expectations (Quality)"
    echo "• PostgreSQL (Database)"
    ;;
esac