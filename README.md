# Pulse Stack - Plateforme de Données Moderne

Une plateforme de données complète utilisant une architecture moderne avec orchestration, ingestion, transformation et visualisation.

## 🏗️ Architecture

![Architecture Pulse Stack](architecture.png)

## 🚀 Services Inclus

### 📊 **PostgreSQL** - Base de données principale
- **Port:** 5433 (externe) / 5432 (interne)
- **Utilisateur:** admin / admin
- **Bases:** healthcare, airflow, superset, airbyte
- **Stockage:** Données Silver/Gold (nettoyées et agrégées)

### 🪣 **MinIO** - Stockage objet (Data Lake)
- **Console:** http://localhost:9001
- **API:** http://localhost:9000
- **Utilisateur:** minio / minio123
- **Buckets:** bronze (données brutes uniquement)
- **Formats:** Parquet, JSON, CSV

### 🔄 **Airbyte** - Ingestion de données
- **Interface:** http://localhost:8000
- **Utilisateur:** airbyte / password
- Connecteurs pour diverses sources de données
- Synchronisation batch et temps réel
- Destination : MinIO (Bronze layer)

### 🌪️ **Airflow** - Orchestration
- **Interface:** http://localhost:8080
- **Utilisateur:** admin / admin
- Orchestration des pipelines ETL/ELT
- Monitoring et alertes
- Déclenche les transformations dbt

### 🔧 **dbt** - Transformation des données
- Architecture Medallion (Bronze → Silver → Gold)
- Source : MinIO (Bronze) → Destination : PostgreSQL (Silver/Gold)
- Tests de qualité intégrés
- Documentation automatique

### ✅ **Great Expectations** - Validation qualité
- Validation des données automatisée
- Profiling des schémas PostgreSQL
- Rapports de qualité des données
- Intégration avec dbt

### 📈 **Superset** - Visualisation BI
- **Interface:** http://localhost:8088
- **Utilisateur:** admin / admin
- Dashboards interactifs
- Source de données : PostgreSQL (Silver/Gold)
- Exploration de données business-ready

### 🔴 **Redis** - Cache et file d'attente
- **Port:** 6379 (interne uniquement)
- Cache pour Airflow et autres services
- File d'attente pour les tâches asynchrones
// ...existing code...

## 🏃‍♂️ Démarrage Rapide

### Prérequis
- Docker et Docker Compose installés
- Au moins 8GB de RAM disponible
- Ports 5432, 8000, 8080, 8088, 9000, 9001 libres

### 1. Démarrage automatique
```bash
./start-platform.sh up
```

### 2. Démarrage manuel
```bash
# Démarrer tous les services
docker-compose up -d

# Vérifier l'état
docker-compose ps

# Voir les logs
docker-compose logs -f [service-name]
```

### 3. Arrêt
```bash
# Arrêter les services
docker-compose down

# Nettoyer complètement (⚠️ supprime les données)
docker-compose down -v
```

## 📋 Accès aux Services

| Service | URL | Utilisateur | Mot de passe |
|---------|-----|-------------|--------------|
| Airflow | http://localhost:8080 | admin | admin |
| Airbyte | http://localhost:8000 | - | - |
| Superset | http://localhost:8088 | admin | admin |
| MinIO Console | http://localhost:9001 | minio | minio123 |
| PostgreSQL | localhost:5432 | admin | admin |

## 🔧 Configuration

### Airflow
- DAGs: `./airflow/dags/`
- Logs: `./airflow/logs/`
- Plugins: `./airflow/plugins/`

### dbt
- Models: `./dbt/models/`
- Profils: `./dbt/profiles.yml`
- Configuration: `./dbt/dbt_project.yml`

### Superset
- Configuration: `./superset/superset_config.py`
- Données: `./superset/`

### Great Expectations
- Configuration: `./great_expectations/`

## 📊 Architecture Medallion

### 🥉 Bronze Layer (Données Brutes)
- Stockage: MinIO bucket `bronze`
- Format: Parquet, JSON, CSV
- Rétention: Données brutes non transformées

### 🥈 Silver Layer (Données Nettoyées)
- Stockage: MinIO bucket `silver` + PostgreSQL
- Transformations: Nettoyage, déduplication, typage
- Tests: Validations de qualité de base

### 🥇 Gold Layer (Données Business)
- Stockage: MinIO bucket `gold` + PostgreSQL
- Agrégations: Métriques business, KPIs
- Optimisation: Tables dénormalisées pour analytics

## 🔍 Monitoring et Maintenance

### Health Checks
```bash
# Vérifier tous les services
./start-platform.sh

# Vérifier un service spécifique
docker-compose exec [service] health_check
```

### Logs
```bash
# Logs en temps réel
docker-compose logs -f

# Logs d'un service
docker-compose logs -f airflow-webserver
```

### Métriques
- Airflow: Interface web avec métriques DAG
- PostgreSQL: pg_stat_activity pour monitoring
- MinIO: Métriques dans l'interface console

## 🛠️ Développement

### Ajouter un DAG Airflow
1. Créer le fichier dans `./airflow/dags/`
2. Le DAG sera automatiquement détecté
3. Vérifier dans l'interface Airflow

### Ajouter un modèle dbt
1. Créer le fichier SQL dans `./dbt/models/`
2. Exécuter: `docker-compose exec dbt dbt run`
3. Tests: `docker-compose exec dbt dbt test`

### Configurer une source Airbyte
1. Interface: http://localhost:8000
2. Créer Source → Destination
3. Configurer la synchronisation

## 🔒 Sécurité

⚠️ **Configuration de développement uniquement!**

Pour la production:
- Changer tous les mots de passe par défaut
- Utiliser des secrets externes (Vault, etc.)
- Configurer HTTPS/TLS
- Mise en place de l'authentification SSO
- Network policies restrictives

## 📚 Ressources

- [Documentation Airflow](https://airflow.apache.org/docs/)
- [Documentation dbt](https://docs.getdbt.com/)
- [Documentation Airbyte](https://docs.airbyte.com/)
- [Documentation Superset](https://superset.apache.org/docs/)
- [Documentation Great Expectations](https://docs.greatexpectations.io/)

## 🤝 Support

Pour des questions ou problèmes:
1. Vérifier les logs: `docker-compose logs [service]`
2. Redémarrer le service: `docker-compose restart [service]`
3. Consulter la documentation du service concerné
