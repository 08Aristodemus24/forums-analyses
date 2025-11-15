{{ 
    config(
        materialized='incremental',
        unique_key=['post_id']
    )
}}

WITH reddit_posts AS (
    SELECT
        *,
        
        -- Get the last load time from the warehouse for incremental logic
        CURRENT_TIMESTAMP() AS dbt_load_timestamp
        -- Add more columns as needed
    FROM {{ source('forums_data', 'raw_reddit_posts') }}
)

SELECT *
FROM reddit_posts
{% if is_incremental() %}
WHERE
    -- Process files that were created/uploaded to S3 *after* the last max timestamp
    -- stored in your Snowflake destination table.
    -- we use the comment/reply's created_at timestmap    
    added_at > (SELECT MAX(added_at) FROM {{ this }})
{% endif %}