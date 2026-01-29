{{
    config(
        materialized='table',
        unique_key=['post_id_full', 'comment_id_full', 'comment_parent_id_full']
    )
}}

WITH reddit_posts AS (
    SELECT * 
    FROM {{ ref('dim_reddit_posts') }}
),

reddit_dates AS (
    SELECT *
    FROM {{ ref('dim_reddit_dates') }}
),

reddit_users AS (
    SELECT *
    FROM {{ ref('dim_reddit_users') }}
)

-- post_id_full, comment_author_id_full, and date_id are
-- the foreign keys to the primary keys of the dimension
-- tables
SELECT
    rc.level,
    rc.comment_id,
    rc.comment_id_full,
    rc.comment_upvotes,
    rc.comment_downvotes,
    rc.comment_edited_at,
    rc.comment_parent_id_full,
    rc.comment_body,
    rc.added_at,
    rc.comment_sentiment_score,
    rc.comment_sentiment_label,

    -- foreign keys that refer to our dim tables
    rd.date_id,
    ru.user_id,
    rp.post_id_full
FROM {{ ref('int_reddit_comments') }} rc
LEFT JOIN reddit_dates rd
ON rc.date_id = rd.date_id
LEFT JOIN reddit_users ru
ON rc.comment_author_id_full = ru.user_id
LEFT JOIN reddit_posts rp
ON rc.post_id_full = rp.post_id_full