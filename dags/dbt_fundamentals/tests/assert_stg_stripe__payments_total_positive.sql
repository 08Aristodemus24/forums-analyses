-- Refunds have a negative amount, so the total amount should always be >= 0.
-- Therefore return records where total_amount < 0 to make the test fail.
SELECT
    order_id,
    SUM(amount) AS total_amount
FROM {{ ref('stg_stripe__payments') }}
GROUP BY order_id
HAVING total_amount < 0