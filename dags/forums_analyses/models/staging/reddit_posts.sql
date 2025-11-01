{{ config(materialized='incremental') }}

WITH raw_reddit_posts AS (
    SELECT
        $1:title::VARCHAR AS title,
        $1:score::INTEGER AS score,
        $1:id::VARCHAR AS id,
        $1:url::VARCHAR AS url,
        $1:name::VARCHAR AS name,
        $1:ups::INTEGER AS upvotes,
        $1:downs::INTEGER AS downvotes,
        $1:created::DATETIME AS createdAt,
        $1:edited::DATETIME AS editedAt,
        $1:author_name::VARCHAR AS authorName,
        $1:parent_id::VARCHAR AS parentId,
        $1:comment::VARCHAR AS comment,
        
        -- Get the last load time from the warehouse for incremental logic
        CURRENT_TIMESTAMP() AS dbt_load_timestamp
        -- Add more columns as needed
    FROM @sa_ext_stage_integration/raw_reddit_data.parquet
)
-- This Jinja macro tells dbt: only execute the WHERE clause after the first run.

SELECT *
FROM raw_reddit_posts
{% if is_incremental() %}
WHERE
    -- Process files that were created/uploaded to S3 *after* the last max timestamp
    -- stored in your Snowflake destination table.
    createdAt > (SELECT MAX(createdAt) FROM raw_reddit_posts)
{% endif %}