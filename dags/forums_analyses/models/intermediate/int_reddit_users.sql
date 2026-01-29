-- extracts all the unique users in both posts and in 
-- those that made comments/replies
{{
    config(
        materialized='ephemeral',
    )
}}

SELECT
    DISTINCT
    comment_author_id_full AS user_id,
    comment_author_username AS username
FROM {{ ref('stg_reddit_posts_comments') }}
WHERE comment_author_id_full IS NOT NULL

UNION

SELECT
    DISTINCT
    post_author_id_full AS user_id,
    post_author_username AS username
FROM {{ ref('stg_reddit_posts') }}
WHERE post_author_id_full IS NOT NULL