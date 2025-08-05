{{ config(materialized='table') }}

WITH base_metrics AS (
    SELECT
        discharge_year,
        gender,
        race,
        age_group,
        health_service_area,
        COUNT(*) AS total_stays,
        AVG(total_charges) AS avg_charges,
        AVG(total_costs) AS avg_costs,
        AVG(length_of_stay) AS avg_length_of_stay,
        -- Remplacer MEDIAN par PERCENTILE_CONT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_charges) AS median_charges,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_costs) AS median_costs,
        MIN(total_charges) AS min_charges,
        MAX(total_charges) AS max_charges,
        MIN(total_costs) AS min_costs,
        MAX(total_costs) AS max_costs,
        STDDEV(total_charges) AS stddev_charges,
        STDDEV(total_costs) AS stddev_costs
    FROM {{ ref('silver_patients') }}
    GROUP BY 1, 2, 3, 4, 5
),

derived_metrics AS (
    SELECT
        *,
        -- Calculer des métriques dérivées
        CASE 
            WHEN avg_charges > 0 THEN (avg_costs / avg_charges) * 100
            ELSE NULL
        END AS avg_cost_to_charge_ratio,
        
        -- Standardiser les groupes d'âge
        CASE 
            WHEN age_group = '0 to 17' THEN 'Pediatric'
            WHEN age_group IN ('18 to 29', '30 to 49') THEN 'Adult'
            WHEN age_group IN ('50 to 69') THEN 'Middle Age'
            WHEN age_group = '70 or Older' THEN 'Senior'
            ELSE 'Unknown'
        END AS age_category,
        
        -- Catégoriser la durée de séjour moyenne
        CASE 
            WHEN avg_length_of_stay IS NULL THEN 'Unknown'
            WHEN avg_length_of_stay <= 1 THEN 'Same Day'
            WHEN avg_length_of_stay BETWEEN 1.1 AND 3 THEN 'Short Stay'
            WHEN avg_length_of_stay BETWEEN 3.1 AND 7 THEN 'Medium Stay'
            WHEN avg_length_of_stay > 7 THEN 'Long Stay'
        END AS avg_stay_category,
        
        -- Catégoriser le volume de patients
        CASE 
            WHEN total_stays < 10 THEN 'Low Volume'
            WHEN total_stays BETWEEN 10 AND 100 THEN 'Medium Volume'
            WHEN total_stays BETWEEN 101 AND 1000 THEN 'High Volume'
            WHEN total_stays > 1000 THEN 'Very High Volume'
        END AS volume_category,
        
        -- Catégoriser les coûts moyens
        CASE 
            WHEN avg_costs < 5000 THEN 'Low Cost'
            WHEN avg_costs BETWEEN 5000 AND 15000 THEN 'Medium Cost'
            WHEN avg_costs BETWEEN 15001 AND 50000 THEN 'High Cost'
            WHEN avg_costs > 50000 THEN 'Very High Cost'
        END AS cost_category
        
    FROM base_metrics
)

SELECT 
    discharge_year,
    gender,
    race,
    age_group,
    age_category,
    health_service_area,
    total_stays,
    volume_category,
    avg_charges,
    avg_costs,
    cost_category,
    avg_cost_to_charge_ratio,
    avg_length_of_stay,
    avg_stay_category,
    median_charges,
    median_costs,
    min_charges,
    max_charges,
    min_costs,
    max_costs,
    stddev_charges,
    stddev_costs
FROM derived_metrics
ORDER BY discharge_year, total_stays DESC