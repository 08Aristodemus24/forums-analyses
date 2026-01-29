{{
    config(
        materialized='ephemeral',
    )
}}

-- reformat the dates of the stg_reddit_posts_comments 
-- table determine sentiment of comment of user
WITH post_activity_w_prob AS (
    SELECT
        *,
        -- creating date ids for each reddit post
        CAST(TO_CHAR(DATE(post_created_at), 'YYYYMMDD') AS INT) AS date_id,

        -- calculating sentiment probability
        SNOWFLAKE.CORTEX.SENTIMENT(post_body) AS post_sentiment_score
    FROM {{ ref('stg_reddit_posts') }}
)

SELECT
    *,
    -- converting sentiment to human readable values
    CASE 
        WHEN post_sentiment_score < 0 THEN 'NEG'
        WHEN post_sentiment_score > 0 THEN 'POS'
        ELSE 'NEU'
    END AS post_sentiment_label
FROM post_activity_w_prob