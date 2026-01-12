{{ 
    config(
        materialized='incremental',
        unique_key=['video_id'],
        on_schema_change='sync_all_columns',
        incremental_strategy='merge'
    )
}}

WITH youtube_videos AS (
    SELECT
        video_id,
        duration AS video_duration,
        channel_id AS videos_channel_id,
        channel_title AS channel_name,
        video_title,
        video_description,
        video_tags,
        comment_count,
        favorite_count,
        like_count,
        view_count,
        made_for_kids,
        published_at AS video_created_at,
        added_at
    FROM {{ source('forums_data', 'raw_youtube_videos') }}
)

SELECT *
FROM youtube_videos
{% if is_incremental() %}
WHERE
    added_at > (SELECT MAX(added_at) FROM {{ this }})
{% endif %}