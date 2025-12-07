{{
    config(
        materialized='incremental',
        unique_key=['customer_id'],
        on_schema_change='sync_all_columns',
        incremental_strategy='merge'
    )
}}

WITH jaffle_shop_customers AS (
    SELECT
        ID AS customer_id,
        FIRST_NAME AS first_name,
        LAST_NAME AS last_name,
        CURRENT_TIMESTAMP() AS dbt_load_timestamp
    FROM {{ source('jaffle_shop', 'customers') }}
)

SELECT *
FROM jaffle_shop_customers
{% if is_incremental() %}
WHERE dbt_load_timestamp > (SELECT MAX(dbt_load_timestamp) FROM {{ this }})
{% endif %}
