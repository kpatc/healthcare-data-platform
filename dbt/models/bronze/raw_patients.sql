-- Exemple de modèle Bronze: données brutes
-- Ce modèle représente les données telles qu'elles arrivent dans le système

{{ config(materialized='view') }}

SELECT 
    1 as id,
    'Example Patient' as name,
    '2024-01-01' as admission_date,
    'Active' as status,
    current_timestamp as loaded_at

UNION ALL

SELECT 
    2 as id,
    'Another Patient' as name,
    '2024-01-02' as admission_date,
    'Discharged' as status,
    current_timestamp as loaded_at
