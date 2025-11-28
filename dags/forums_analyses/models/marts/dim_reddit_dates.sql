-- materialize this as table since dim are much 
-- wider than narrower
{{
    config(
        
        materialized='table',
        unique_key=['date_id']
    )
}}

SELECT
    date_actual,
    date_id,
    calendar_year,
    calendar_month,
    calendar_day,
    day_of_week,
    is_weekend
FROM {{ ref('int_reddit_dates') }}
