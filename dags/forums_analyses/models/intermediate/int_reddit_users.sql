{{
    config(
        materialized='view'
    )
}}

SELECT
    DISTINCT
    comment_author_username AS username,
    comment_author_id_full AS user_id
FROM {{ ref('stg_reddit_posts_comments') }}
WHERE comment_author_name IS NOT NULL

UNION BY NAME

SELECT
    DISTINCT
    post_author_id_full AS user_id,
    post_author_username AS username
FROM {{ ref('stg_reddit_posts') }}
WHERE post_name IS NOT NULL