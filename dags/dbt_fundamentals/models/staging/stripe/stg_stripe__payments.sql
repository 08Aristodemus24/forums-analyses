{{
    config(
        materialized='incremental',
        unique_key=['id'],
        on_schema_change='sync_all_columns',
        incremental_strategy='merge'
    )
}}

WITH stripe_payments AS (
    SELECT
        ID AS id,
        ORDERID AS order_id,
        PAYMENTMETHOD AS payment_method,
        STATUS AS status,
        AMOUNT AS amount,
        CREATED AS created_at,
        CURRENT_TIMESTAMP() AS dbt_load_timestamp
    FROM {{ source('stripe', 'raw_stripe_payments') }}
)

SELECT *
FROM stripe_payments
{% if is_incremental() %}
WHERE dbt_load_timestamp > (SELECT MAX(dbt_load_timestamp) FROM {{ this }})
{% endif %}
