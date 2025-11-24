{{
    config(
        materialized='view'
    )
}}

SELECT
    DISTINCT
    comment_author_name AS user_id,
    comment_author_fullname AS username
FROM {{ ref('stg_reddit_posts_comments') }}
WHERE comment_author_name IS NOT NULL

UNION BY NAME

SELECT
    DISTINCT
    post_name AS user_id,
    post_author_name AS username
FROM {{ ref('stg_reddit_posts') }}
WHERE post_name IS NOT NULL