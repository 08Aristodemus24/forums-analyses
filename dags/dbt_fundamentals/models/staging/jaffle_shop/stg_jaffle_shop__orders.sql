{{
    config(
        materialized='incremental',
        unique_key=['order_id'],
        on_schema_change='sync_all_columns',
        incremental_strategy='merge'
    )
}}

WITH jaffle_shop_orders AS (
    SELECT
        ID AS order_id,
        USER_ID AS user_id,
        ORDER_DATE AS order_date,
        STATUS AS status, 
        CURRENT_TIMESTAMP() AS dbt_load_timestamp
    FROM {{ source('jaffle_shop', 'raw_jaffle_shop_orders') }}
)

SELECT *    
FROM jaffle_shop_orders
{% if is_incremental() %}
WHERE dbt_load_timestamp > (SELECT MAX(dbt_load_timestamp) FROM {{ this }})
{% endif %}
