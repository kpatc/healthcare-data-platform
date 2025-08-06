from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.http.operators.http import SimpleHttpOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from datetime import datetime, timedelta
import json

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2025, 8, 5),
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

# IDs  connections Airbyte (change by your ids)
CSV_TO_MINIO_CONNECTION_ID = "084f31d7-e9a0-45e1-94ec-ac45a86e2f83"
CSV_TO_POSTGRES_CONNECTION_ID = "edb6c2b7-d235-4084-80bd-0dabf1ae267d"

with DAG(
    'daily_data_pipeline',
    default_args=default_args,
    description='Daily data pipeline: Airbyte sync → dbt transformation',
    schedule_interval='0 1 * * *',  # Run every day at 1 AM
    catchup=False,
    tags=['Daily pipeline', 'monitoring'],
) as dag:

    # 1. Sync CSV to MinIO (backup/raw storage)
    sync_csv_to_minio = SimpleHttpOperator(
        task_id='sync_csv_to_minio',
        http_conn_id='airbyte_api',
        endpoint='/api/v1/connections/sync',
        method='POST',
        headers={'Content-Type': 'application/json'},
        data=json.dumps({'connectionId': CSV_TO_MINIO_CONNECTION_ID}),
    )

    # 2. Sync CSV to PostgreSQL (for dbt processing)
    sync_csv_to_postgres = SimpleHttpOperator(
        task_id='sync_csv_to_postgres',
        http_conn_id='airbyte_api',
        endpoint='/api/v1/connections/sync',
        method='POST',
        headers={'Content-Type': 'application/json'},
        data=json.dumps({'connectionId': CSV_TO_POSTGRES_CONNECTION_ID}),
    )

    # 3. Wait for both syncs to complete
    wait_for_syncs = BashOperator(
        task_id='wait_for_syncs',
        bash_command='sleep 300',  # Wait 5 minutes for syncs to complete
    )

    # 4. Check if new data exists in PostgreSQL
    check_new_data = PostgresOperator(
        task_id='check_new_data',
        postgres_conn_id='pulse_postgres',
        sql="""
        SELECT COUNT(*) FROM bronze._airbyte_raw_patients 
        WHERE _airbyte_emitted_at >= NOW() - INTERVAL '2 hours';
        """,
    )

    # 5. Run dbt silver models
    dbt_run_silver = BashOperator(
        task_id='dbt_run_silver',
        bash_command='docker compose -f docker-compose-pulse-components.yaml exec dbt dbt run --models silver_patients',
    )

    # 6. Run dbt gold models
    dbt_run_gold = BashOperator(
        task_id='dbt_run_gold',
        bash_command='docker compose -f docker-compose-pulse-components.yaml exec dbt dbt run --models gold_patient_stats',
    )

    # 7. Run dbt tests
    dbt_test = BashOperator(
        task_id='dbt_test',
        bash_command='docker compose -f docker-compose-pulse-components.yaml exec dbt dbt test',
    )

    # 8. Generate dbt docs
    dbt_docs = BashOperator(
        task_id='dbt_docs',
        bash_command='docker compose -f docker-compose-pulse-components.yaml exec dbt dbt docs generate',
    )

    # Define task dependencies
    # Les deux syncs peuvent s'exécuter en parallèle
    [sync_csv_to_minio, sync_csv_to_postgres] >> wait_for_syncs >> check_new_data >> dbt_run_silver >> dbt_run_gold >> dbt_test >> dbt_docs