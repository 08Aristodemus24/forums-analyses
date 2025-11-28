-- materialize this as table since dim are much 
-- wider than narrower
{{
    config(
        materialized='table',
        unique_key=['user_id']
    )
}}

SELECT
    username,
    user_id
FROM {{ ref('int_reddit_users') }}
