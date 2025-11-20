{{ 
    config(
        materialized='view'
    )
}}


SELECT 
    level, 
    COUNT(level) AS cnt 
FROM {{ ref('stg_reddit_posts_comments') }}
GROUP BY level
