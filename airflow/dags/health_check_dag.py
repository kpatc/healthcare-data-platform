"""
DAG de test pour valider l'installation d'Airflow
Ce DAG simple permet de vérifier que Airflow fonctionne correctement
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator

def hello_world():
    """Fonction Python simple pour tester les tâches Python"""
    print("Hello from Pulse Stack Data Platform!")
    print("Airflow is working correctly!")
    return "success"

def check_connections():
    """Vérifier les connexions aux autres services"""
    import socket
    services = {
        'postgres': ('postgres', 5432),
        'minio': ('minio', 9000),
        'redis': ('redis', 6379)
    }
    
    results = {}
    for service, (host, port) in services.items():
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((host, port))
            sock.close()
            results[service] = 'OK' if result == 0 else 'FAILED'
        except Exception as e:
            results[service] = f'ERROR: {str(e)}'
    
    print("Service connectivity check:")
    for service, status in results.items():
        print(f"  {service}: {status}")
    
    return results

# Configuration par défaut du DAG
default_args = {
    'owner': 'pulse-stack',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Définition du DAG
dag = DAG(
    'pulse_stack_health_check',
    default_args=default_args,
    description='DAG de vérification de santé de la plateforme Pulse Stack',
    schedule_interval=timedelta(hours=1),
    catchup=False,
    tags=['health-check', 'monitoring'],
)

# Tâche 1: Test simple Python
hello_task = PythonOperator(
    task_id='hello_world',
    python_callable=hello_world,
    dag=dag,
)

# Tâche 2: Test bash
bash_task = BashOperator(
    task_id='system_info',
    bash_command='echo "System: $(uname -a)" && echo "Date: $(date)" && echo "Disk usage:" && df -h',
    dag=dag,
)

# Tâche 3: Vérification des connexions
connection_check = PythonOperator(
    task_id='check_service_connections',
    python_callable=check_connections,
    dag=dag,
)

# Définition des dépendances
hello_task >> bash_task >> connection_check
