{{ 
    config(
        materialized='incremental',
        unique_key=['post_id'],
        on_schema_change='sync_all_columns'
    )
}}

WITH reddit_posts AS (
    SELECT
        post_title,
        post_score,
        post_id,
        post_name AS post_id_full,
        post_url,
        post_author_name AS post_author_username,
        post_author_fullname AS post_author_id_full,
        post_body,
        post_created_at,
        post_edited_at,
        added_at
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