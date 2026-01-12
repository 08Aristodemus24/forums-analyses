

WITH jaffle_shop_customers AS (
    SELECT
        ID AS customer_id,
        FIRST_NAME AS first_name,
        LAST_NAME AS last_name,
        CURRENT_TIMESTAMP() AS dbt_load_timestamp
    FROM FORUMS_ANALYSES_DB.FORUMS_ANALYSES_BRONZE.customers
)

SELECT *
FROM jaffle_shop_customers
