SELECT
    discharge_year,
    gender,
    race,
    COUNT(*) AS total_stays,
    AVG(total_charges) AS avg_charges,
    AVG(total_costs) AS avg_costs
FROM {{ ref('silver_patients') }}
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3