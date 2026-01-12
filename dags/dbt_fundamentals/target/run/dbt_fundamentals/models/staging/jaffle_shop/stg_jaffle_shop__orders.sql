
  create or replace   view FORUMS_ANALYSES_DB.FORUMS_ANALYSES_BRONZE.stg_jaffle_shop__orders
  
  
  
  
  as (
    

WITH jaffle_shop_orders AS (
    SELECT
        ID AS order_id,
        USER_ID AS user_id,
        ORDER_DATE AS order_date,
        STATUS AS status, 
        CURRENT_TIMESTAMP() AS dbt_load_timestamp
    FROM FORUMS_ANALYSES_DB.FORUMS_ANALYSES_BRONZE.orders
)

SELECT *    
FROM jaffle_shop_orders

-- this is a comment for jinja template

  );

