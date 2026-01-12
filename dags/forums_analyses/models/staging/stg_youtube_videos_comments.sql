{{ 
    config(
        materialized='incremental',
        unique_key=['video_id', 'comment_id'],
        on_schema_change='sync_all_columns',
        incremental_strategy='merge'
    )
}}

WITH youtube_videos_comments AS (
    SELECT
        level,
        video_id,
        comment_id,
        author_channel_id AS comment_author_id_full,
        channel_id_where_comment_was_made AS videos_channel_id,
        parent_comment_id AS comment_parent_id,
        text_original AS comment_body,
        -- text_display,
        published_at AS comment_created_at,
        updated_at AS comment_updated_at,
        like_count AS comment_likes,
        REPLACE(author_display_name, '@', '') AS comment_author_username,
        author_channel_url,
        added_at
    FROM {{ source('forums_data', 'raw_youtube_videos_comments') }}
)

SELECT *
FROM youtube_videos_comments
{% if is_incremental() %}
WHERE
    added_at > (SELECT MAX(added_at) FROM {{ this }})
{% endif %}