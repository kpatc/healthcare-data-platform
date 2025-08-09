from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.http.operators.http import SimpleHttpOperator
from airflow.providers.docker.operators.docker import DockerOperator
from datetime import datetime, timedelta
import json

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2025, 8, 5),
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

# IDs connections Airbyte
CSV_TO_MINIO_CONNECTION_ID = "084f31d7-e9a0-45e1-94ec-ac45a86e2f83"
CSV_TO_POSTGRES_CONNECTION_ID = "edb6c2b7-d235-4084-80bd-0dabf1ae267d"

with DAG(
    'daily_data_pipeline',
    default_args=default_args,
    description='Daily data pipeline: Airbyte sync → dbt transformation',
    schedule_interval='0 1 * * *',
    catchup=False,
    tags=['Daily pipeline', 'monitoring'],
) as dag:

    # 1. Sync CSV to MinIO
    sync_csv_to_minio = SimpleHttpOperator(
        task_id='sync_csv_to_minio',
        http_conn_id='airbyte_default',
        endpoint='/api/v1/connections/sync',
        method='POST',
        headers={'Content-Type': 'application/json'},
        data=json.dumps({'connectionId': CSV_TO_MINIO_CONNECTION_ID}),
    )

    # 2. Sync CSV to PostgreSQL
    sync_csv_to_postgres = SimpleHttpOperator(
        task_id='sync_csv_to_postgres',
        http_conn_id='airbyte_default',
        endpoint='/api/v1/connections/sync',
        method='POST',
        headers={'Content-Type': 'application/json'},
        data=json.dumps({'connectionId': CSV_TO_POSTGRES_CONNECTION_ID}),
    )

    # 3. Wait for syncs
    wait_for_syncs = BashOperator(
        task_id='wait_for_syncs',
        bash_command='sleep 600',
    )

    # 4. Run dbt silver models
    dbt_run_silver = DockerOperator(
        task_id='dbt_run_silver',
        image='ghcr.io/dbt-labs/dbt-postgres:1.4.0',
        command='dbt run --models silver_patients',
        auto_remove=True,
        docker_url="unix://var/run/docker.sock",
        network_mode='pulse-stack_pulse-network',
        mount_tmp_dir=False,
        mounts=[
            {
                'source': '/home/josh/Big Data Projects/Pulse Stack/dbt',
                'target': '/usr/app',
                'type': 'bind'
            },
            {
                'source': '/home/josh/Big Data Projects/Pulse Stack/dbt',
                'target': '/root/.dbt',
                'type': 'bind'
            }
        ],
        working_dir='/usr/app',
        environment={'DBT_PROFILES_DIR': '/root/.dbt'}
    )

    # 5. Run dbt gold models
    dbt_run_gold = DockerOperator(
        task_id='dbt_run_gold',
        image='ghcr.io/dbt-labs/dbt-postgres:1.4.0',
        command='dbt run --models gold_patient_stats',
        auto_remove=True,
        docker_url="unix://var/run/docker.sock",
        network_mode='pulse-stack_pulse-network',
        mount_tmp_dir=False,
        mounts=[
            {
                'source': '/home/josh/Big Data Projects/Pulse Stack/dbt',
                'target': '/usr/app',
                'type': 'bind'
            },
            {
                'source': '/home/josh/Big Data Projects/Pulse Stack/dbt',
                'target': '/root/.dbt',
                'type': 'bind'
            }
        ],
        working_dir='/usr/app',
        environment={'DBT_PROFILES_DIR': '/root/.dbt'}
    )

    # 6. Run dbt tests
    dbt_test = DockerOperator(
        task_id='dbt_test',
        image='ghcr.io/dbt-labs/dbt-postgres:1.4.0',
        command='dbt test',
        auto_remove=True,
        docker_url="unix://var/run/docker.sock",
        network_mode='pulse-stack_pulse-network',
        mount_tmp_dir=False,
        mounts=[
            {
                'source': '/home/josh/Big Data Projects/Pulse Stack/dbt',
                'target': '/usr/app',
                'type': 'bind'
            },
            {
                'source': '/home/josh/Big Data Projects/Pulse Stack/dbt',
                'target': '/root/.dbt',
                'type': 'bind'
            }
        ],
        working_dir='/usr/app',
        environment={'DBT_PROFILES_DIR': '/root/.dbt'}
    )

    # 7. Generate dbt docs
    dbt_docs = DockerOperator(
        task_id='dbt_docs',
        image='ghcr.io/dbt-labs/dbt-postgres:1.4.0',
        command='dbt docs generate',
        auto_remove=True,
        docker_url="unix://var/run/docker.sock",
        network_mode='pulse-stack_pulse-network',
        mount_tmp_dir=False,
        mounts=[
            {
                'source': '/home/josh/Big Data Projects/Pulse Stack/dbt',
                'target': '/usr/app',
                'type': 'bind'
            },
            {
                'source': '/home/josh/Big Data Projects/Pulse Stack/dbt',
                'target': '/root/.dbt',
                'type': 'bind'
            }
        ],
        working_dir='/usr/app',
        environment={'DBT_PROFILES_DIR': '/root/.dbt'}
    )

    # Dependencies
    [sync_csv_to_minio, sync_csv_to_postgres] >> wait_for_syncs >> dbt_run_silver >> dbt_run_gold >> dbt_test >> dbt_docs