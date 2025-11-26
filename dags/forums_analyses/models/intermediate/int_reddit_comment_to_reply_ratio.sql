{{ 
    config(
        materialized='view',
        on_schema_change='sync_all_columns'
    )
}}


SELECT 
    level, 
    COUNT(level) AS cnt 
FROM {{ ref('stg_reddit_posts_comments') }}
GROUP BY level
