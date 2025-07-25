-- Exemple de modèle Silver: données nettoyées et standardisées
-- Ce modèle nettoie et standardise les données bronze

{{ config(materialized='table') }}

SELECT 
    id,
    TRIM(UPPER(name)) as patient_name,
    admission_date::date as admission_date,
    CASE 
        WHEN status = 'Active' THEN 'ACTIVE'
        WHEN status = 'Discharged' THEN 'DISCHARGED'
        ELSE 'UNKNOWN'
    END as patient_status,
    loaded_at
FROM {{ ref('raw_patients') }}
WHERE name IS NOT NULL
