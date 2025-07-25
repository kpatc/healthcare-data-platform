-- Script d'initialisation pour les bases de données PostgreSQL
-- Ce script crée les bases de données nécessaires pour les différents services

-- Base de données pour Airflow
CREATE DATABASE airflow;
CREATE USER airflow WITH PASSWORD 'airflow';
GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow;
GRANT ALL PRIVILEGES ON DATABASE airflow TO admin;

-- Base de données pour Superset
CREATE DATABASE superset;
GRANT ALL PRIVILEGES ON DATABASE superset TO admin;

-- Note: Airbyte utilise sa propre base de données séparée (airbyte-db service)
-- pour éviter les conflits de configuration

-- Affichage des bases de données créées
\l
