{{
    config(
        materialized='view'
    )
}}

SELECT
    video_id,
    video_duration,
    videos_channel_id,
    channel_name,
    video_title,
    video_description,
    video_tags,
    comment_count,
    favorite_count,
    like_count,
    view_count,
    made_for_kids,
    video_created_at,
    added_at
FROM {{ ref("stg_youtube_videos") }}