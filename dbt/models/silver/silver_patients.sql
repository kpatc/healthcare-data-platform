
WITH cleaned AS (
    SELECT
        "Health Service Area" AS health_service_area,
        "Hospital County" AS hospital_county,
        "Facility Name" AS facility_name,
        "Age Group" AS age_group,
        CAST("Zip Code - 3 digits" AS INTEGER) AS zip_prefix,
        "Gender" AS gender,
        "Race" AS race,
        "Ethnicity" AS ethnicity,
        CAST("Length of Stay" AS INTEGER) AS length_of_stay,
        "Type of Admission" AS admission_type,
        "Patient Disposition" AS disposition,
        "Discharge Year" AS discharge_year,
        "CCS Diagnosis Description" AS diagnosis_description,
        "APR DRG Description" AS drg_description,
        "APR Severity of Illness Description" AS severity,
        CAST("Total Charges" AS FLOAT) AS total_charges,
        CAST("Total Costs" AS FLOAT) AS total_costs
    FROM {{ ref('bronze_patients') }}
    WHERE "Discharge Year" >= 2020
)

SELECT * FROM cleaned