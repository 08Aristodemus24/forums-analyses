{{
    config(
        materialized='ephemeral',
    )
}}

-- reformat the dates of the stg_reddit_posts_comments 
-- table determine sentiment of comment of user

WITH comment_activity_w_prob AS (
    SELECT
        *,
        CAST(TO_CHAR(DATE(comment_created_at), 'YYYYMMDD') AS INT) AS date_id,
        SNOWFLAKE.CORTEX.SENTIMENT(comment_body) AS comment_sentiment_probability
    FROM {{ ref('stg_reddit_posts_comments') }}
)

SELECT
    *,
    CASE 
        WHEN comment_sentiment_probability < 0 THEN 'NEG'
        WHEN comment_sentiment_probability > 0 THEN 'POS'
        ELSE 'NEU'
    END AS comment_sentiment_probability
FROM comment_activity_w_prob