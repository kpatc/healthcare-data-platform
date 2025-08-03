SELECT
    *
FROM {{ source('bronze', 'patients') }}