{{ 
    config(
        materialized='incremental',
        unique_key=['post_id', 'author_fullname']
    ) 
}}

WITH reddit_posts_comments AS (
    SELECT
        *,
        
        -- Get the last load time from the warehouse for incremental logic
        CURRENT_TIMESTAMP() AS dbt_load_timestamp
        -- Add more columns as needed
    FROM {{ source('forums_data', 'raw_reddit_posts_comments') }}
)
-- This Jinja macro tells dbt: only execute the WHERE clause after the first run.

SELECT *
FROM reddit_posts_comments
{% if is_incremental() %}
WHERE
    -- Process files that were created/uploaded to S3 *after* the last max timestamp
    -- stored in your Snowflake destination table.
    created_at > (SELECT MAX(created_at) FROM reddit_posts_comments)
{% endif %}