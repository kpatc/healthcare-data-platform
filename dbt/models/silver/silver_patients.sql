{{ config(materialized='table') }}

WITH cleaned AS (
    SELECT
        (_airbyte_data->>'Health Service Area')::TEXT AS health_service_area,
        (_airbyte_data->>'Hospital County')::TEXT AS hospital_county,
        (_airbyte_data->>'Operating Certificate Number')::FLOAT AS operating_certificate_number,
        (_airbyte_data->>'Facility Id')::FLOAT AS facility_id,
        (_airbyte_data->>'Facility Name')::TEXT AS facility_name,
        (_airbyte_data->>'Age Group')::TEXT AS age_group,
        (_airbyte_data->>'Zip Code - 3 digits')::TEXT AS zip_prefix,
        (_airbyte_data->>'Gender')::TEXT AS gender,
        (_airbyte_data->>'Race')::TEXT AS race,
        (_airbyte_data->>'Ethnicity')::TEXT AS ethnicity,
        CASE 
            WHEN (_airbyte_data->>'Length of Stay') ~ '^[0-9]+$' 
            THEN (_airbyte_data->>'Length of Stay')::INTEGER
            ELSE NULL
        END AS length_of_stay,
        (_airbyte_data->>'Type of Admission')::TEXT AS admission_type,
        (_airbyte_data->>'Patient Disposition')::TEXT AS disposition,
        (_airbyte_data->>'Discharge Year')::INTEGER AS discharge_year,
        (_airbyte_data->>'CCS Diagnosis Code')::INTEGER AS ccs_diagnosis_code,
        (_airbyte_data->>'CCS Diagnosis Description')::TEXT AS diagnosis_description,
        (_airbyte_data->>'CCS Procedure Code')::INTEGER AS ccs_procedure_code,
        (_airbyte_data->>'CCS Procedure Description')::TEXT AS procedure_description,
        (_airbyte_data->>'APR DRG Code')::INTEGER AS apr_drg_code,
        (_airbyte_data->>'APR DRG Description')::TEXT AS drg_description,
        (_airbyte_data->>'APR MDC Code')::INTEGER AS apr_mdc_code,
        (_airbyte_data->>'APR MDC Description')::TEXT AS mdc_description,
        (_airbyte_data->>'APR Severity of Illness Code')::INTEGER AS apr_severity_code,
        (_airbyte_data->>'APR Severity of Illness Description')::TEXT AS severity,
        (_airbyte_data->>'APR Risk of Mortality')::TEXT AS risk_of_mortality,
        (_airbyte_data->>'APR Medical Surgical Description')::TEXT AS medical_surgical_description,

        -- Gestion des Payment Typology avec traitement des "NaN"
        CASE 
            WHEN (_airbyte_data->>'Payment Typology 1') = 'NaN' THEN NULL
            ELSE (_airbyte_data->>'Payment Typology 1')::TEXT
        END AS payment_typology_1,
        CASE 
            WHEN (_airbyte_data->>'Payment Typology 2') = 'NaN' THEN NULL
            ELSE (_airbyte_data->>'Payment Typology 2')::TEXT
        END AS payment_typology_2,
        CASE 
            WHEN (_airbyte_data->>'Payment Typology 3') = 'NaN' THEN NULL
            ELSE (_airbyte_data->>'Payment Typology 3')::TEXT
        END AS payment_typology_3,

        (_airbyte_data->>'Birth Weight')::INTEGER AS birth_weight,
        (_airbyte_data->>'Abortion Edit Indicator')::TEXT AS abortion_edit_indicator,
        (_airbyte_data->>'Emergency Department Indicator')::TEXT AS emergency_department_indicator,
        (_airbyte_data->>'Total Charges')::FLOAT AS total_charges,
        (_airbyte_data->>'Total Costs')::FLOAT AS total_costs,
        _airbyte_emitted_at AS loaded_at
        
    FROM {{ source('staging', '_airbyte_raw_patients') }}
    WHERE (_airbyte_data->>'Discharge Year')::INTEGER >= 2015
        AND (_airbyte_data->>'Total Charges')::FLOAT > 0
        AND (_airbyte_data->>'Total Costs')::FLOAT > 0
)

SELECT * FROM cleaned