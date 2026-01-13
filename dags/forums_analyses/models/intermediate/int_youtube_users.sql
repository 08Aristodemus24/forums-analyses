-- extracts all the unique users in both posts and in 
-- those that made comments/replies
{{
    config(
        materialized='view',
    )
}}

SELECT
    DISTINCT
    comment_author_id_full AS user_id,
    comment_author_username AS username
FROM {{ ref('stg_youtube_videos_comments') }}
WHERE comment_author_id_full IS NOT NULL

UNION

SELECT
    DISTINCT
    videos_channel_id AS user_id,
    channel_name AS username
FROM {{ ref('stg_youtube_videos') }}
WHERE videos_channel_id IS NOT NULL