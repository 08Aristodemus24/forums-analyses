{{
    config(
        materialized='view'
    )
}}

WITH added_features AS (
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
        added_at,

        -- 
        CAST(TO_CHAR(DATE(video_created_at), 'YYYYMMDD') AS INT) AS date_id,

        SNOWFLAKE.CORTEX.SENTIMENT(video_description) AS probability,

        REGEXP_SUBSTR(video_duration, '(\\d+)M', 1, 1, 'e')::INT * 60 +
        REGEXP_SUBSTR(video_duration, '(\\d+)S', 1, 1, 'e')::INT AS 
        duration_seconds,

        -- Engagement Metrics (Avoid division by zero)
        (like_count / NULLIF(view_count, 0)) * 100 AS like_view_ratio,
        
        -- Demographic Flag
        CASE WHEN made_for_kids = TRUE THEN 'Kids' ELSE 'General' END AS audience_type,
        
        -- Snowflake Cortex NLP
        SNOWFLAKE.CORTEX.SENTIMENT(video_title) AS title_sentiment_score,
        SNOWFLAKE.CORTEX.SENTIMENT(video_description) AS description_sentiment_score,
        
        -- Only summarize if description is long enough to be meaningful (> 50 chars)
        CASE 
            WHEN LENGTH(video_description) > 50 
            THEN SNOWFLAKE.CORTEX.SUMMARIZE(video_description) 
            ELSE video_description 
        END AS video_summary
    FROM {{ ref("stg_youtube_videos") }}
),

added_features_refined AS (
    SELECT
        *,
        -- convert title sentiment probability to human 
        -- readable values
        {{ get_sentiment_label(title_sentiment_score) }} AS title_sentiment_label,
        {{ get_sentiment_label(description_sentiment_score) }} AS description_sentiment_label
),

flattened_tags AS (
    SELECT
        -- get all columns but exclude
        the video tags column with which video tag was
        derived through flattening
        * EXCLUDE(video_tags),

        -- basic transformations
        t.value AS video_tag
    FROM forums_analyses_db.forums_analyses_bronze.stg_youtube_videos syv,
    LATERAL FLATTEN(input => syv.video_tags) t
    WHERE syv.video_id = '34Na4j8AVgA'
),

final AS (
    *,
    CASE 
        WHEN duration_seconds < 60 THEN 'Short'
        WHEN duration_seconds BETWEEN 60 AND 600 THEN 'Medium'
        WHEN duration_seconds > 600 THEN 'Long'
        ELSE 'Infinite'
    END AS duration_bucket
)

select * from final