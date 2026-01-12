
  create or replace   view FORUMS_ANALYSES_DB.FORUMS_ANALYSES_BRONZE.stg_stripe__payments
  
  
  
  
  as (
    

WITH stripe_payments AS (
    SELECT
        ID AS payment_id,
        ORDERID AS order_id,
        PAYMENTMETHOD AS payment_method,
        STATUS AS status,

        -- amount is stored in cents so convert it to dollars
        AMOUNT / 100 AS amount,
        CREATED AS created_at,
        CURRENT_TIMESTAMP() AS dbt_load_timestamp
    FROM FORUMS_ANALYSES_DB.FORUMS_ANALYSES_BRONZE.payments
)

SELECT *
FROM stripe_payments

  );

