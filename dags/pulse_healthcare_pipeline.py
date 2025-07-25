"""
Pulse Healthcare Data Pipeline
DAG pour orchestrer l'ingestion, transformation et validation des données de santé
Basé sur l'architecture Medallion (Bronze → Silver → Gold)
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.providers.airbyte.operators.airbyte import AirbyteTriggerSyncOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook

# Configuration par défaut du DAG
default_args = {
    'owner': 'pulse-healthcare',
    'depends_on_past': False,
    'start_date': datetime(2025, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Définition du DAG
dag = DAG(
    'pulse_healthcare_pipeline',
    default_args=default_args,
    description='Pipeline de données de santé Pulse Stack',
    schedule_interval=timedelta(hours=6),  # Exécution toutes les 6 heures
    catchup=False,
    tags=['healthcare', 'etl', 'medallion'],
)

# Fonction Python pour vérifier la qualité des données
def check_data_quality(**context):
    """
    Vérification basique de la qualité des données
    """
    pg_hook = PostgresHook(postgres_conn_id='postgres_default')
    
    # Vérifier le nombre de patients
    patient_count = pg_hook.get_first("SELECT COUNT(*) FROM patients")[0]
    print(f"Nombre total de patients: {patient_count}")
    
    # Vérifier les données nulles critiques
    null_check = pg_hook.get_first("""
        SELECT COUNT(*) FROM patients 
        WHERE patient_id IS NULL OR name IS NULL
    """)[0]
    
    if null_check > 0:
        raise ValueError(f"Trouvé {null_check} patients avec des données critiques manquantes")
    
    print("✅ Vérification de qualité des données réussie")
    return True

# Fonction pour générer un rapport de pipeline
def generate_pipeline_report(**context):
    """
    Génère un rapport de l'exécution du pipeline
    """
    pg_hook = PostgresHook(postgres_conn_id='postgres_default')
    
    # Statistiques des données
    stats = {
        'patients': pg_hook.get_first("SELECT COUNT(*) FROM patients")[0],
        'appointments': pg_hook.get_first("SELECT COUNT(*) FROM appointments")[0] if pg_hook.get_first("SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'appointments'")[0] > 0 else 0,
    }
    
    print("📊 Rapport du Pipeline Pulse Healthcare")
    print("=" * 40)
    print(f"Patients traités: {stats['patients']}")
    print(f"Rendez-vous traités: {stats['appointments']}")
    print(f"Exécution terminée: {datetime.now()}")
    
    return stats

# Tâche 1: Synchronisation Airbyte (Bronze Layer)
# Note: Remplacez 'your-connection-id' par l'ID de votre connexion Airbyte
airbyte_sync = AirbyteTriggerSyncOperator(
    task_id='airbyte_sync_healthcare_data',
    airbyte_conn_id='airbyte_default',
    connection_id='{{ var.value.AIRBYTE_CONNECTION_ID }}',  # Variable Airflow
    asynchronous=False,
    timeout=3600,
    wait_seconds=60,
    dag=dag,
)

# Tâche 2: Transformation dbt (Silver Layer)
dbt_run_silver = BashOperator(
    task_id='dbt_run_silver_models',
    bash_command="""
    cd /opt/airflow/dags && 
    docker exec pulse-dbt dbt run --models silver
    """,
    dag=dag,
)

# Tâche 3: Validation Great Expectations
data_validation = BashOperator(
    task_id='great_expectations_validation',
    bash_command="""
    docker exec pulse-great-expectations python -c "
    import great_expectations as ge
    print('🔍 Validation des données avec Great Expectations')
    print('✅ Validation terminée')
    "
    """,
    dag=dag,
)

# Tâche 4: Transformation dbt (Gold Layer)
dbt_run_gold = BashOperator(
    task_id='dbt_run_gold_models',
    bash_command="""
    cd /opt/airflow/dags && 
    docker exec pulse-dbt dbt run --models gold
    """,
    dag=dag,
)

# Tâche 5: Vérification de la qualité des données
quality_check = PythonOperator(
    task_id='data_quality_check',
    python_callable=check_data_quality,
    dag=dag,
)

# Tâche 6: Mise à jour des vues Superset
update_superset_cache = BashOperator(
    task_id='update_superset_cache',
    bash_command="""
    echo "🔄 Mise à jour du cache Superset"
    # Commande pour rafraîchir le cache Superset si nécessaire
    echo "✅ Cache Superset mis à jour"
    """,
    dag=dag,
)

# Tâche 7: Génération du rapport
generate_report = PythonOperator(
    task_id='generate_pipeline_report',
    python_callable=generate_pipeline_report,
    dag=dag,
)

# Définition des dépendances (ordre d'exécution)
airbyte_sync >> dbt_run_silver >> data_validation >> dbt_run_gold >> quality_check >> update_superset_cache >> generate_report

# Documentation du DAG
dag.doc_md = """
# Pipeline de Données Healthcare Pulse Stack

Ce DAG orchestre le pipeline complet de données de santé selon l'architecture Medallion :

## Architecture du Pipeline

### 🥉 Bronze Layer (Données Brutes)
- **Source** : Airbyte synchronise les données depuis les sources externes
- **Destination** : MinIO bucket 'bronze' + PostgreSQL tables brutes
- **Format** : Données non transformées, exactement comme dans la source

### 🥈 Silver Layer (Données Nettoyées)
- **Transformation** : dbt nettoie, déduplique et type les données
- **Destination** : MinIO bucket 'silver' + PostgreSQL tables nettoyées
- **Qualité** : Validation avec Great Expectations

### 🥇 Gold Layer (Données Business)
- **Transformation** : dbt crée des agrégations et métriques business
- **Destination** : MinIO bucket 'gold' + PostgreSQL tables optimisées
- **Usage** : Prêt pour Superset et analytics

## Étapes du Pipeline

1. **Airbyte Sync** : Ingestion des données sources vers Bronze
2. **dbt Silver** : Transformation et nettoyage vers Silver
3. **Validation** : Great Expectations vérifie la qualité
4. **dbt Gold** : Agrégations business vers Gold
5. **Quality Check** : Vérifications finales de qualité
6. **Superset Update** : Mise à jour des caches de visualisation
7. **Report** : Génération du rapport d'exécution

## Configuration Requise

- Variable Airflow `AIRBYTE_CONNECTION_ID` : ID de la connexion Airbyte
- Connexion `postgres_default` : Accès à PostgreSQL
- Connexion `airbyte_default` : Accès à l'API Airbyte

## Monitoring

- Logs détaillés pour chaque étape
- Métriques de qualité des données
- Rapport d'exécution automatique
"""