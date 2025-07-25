-- Exemple de modèle Gold: métriques business et agrégations
-- Ce modèle crée des vues orientées business

{{ config(materialized='table') }};

SELECT 
    patient_status,
    COUNT(*) as patient_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as percentage,
    MIN(admission_date) as earliest_admission,
    MAX(admission_date) as latest_admission,
    current_timestamp as report_generated_at
FROM {{ ref('cleaned_patients') }}
GROUP BY patient_status;
