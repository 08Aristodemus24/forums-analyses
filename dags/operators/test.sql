USE forums_analyses_db;
USE forums_analyses_db.forums_analyses_bronze;


SELECT 
    user_id, comment_upvotes
FROM fct_reddit_comments;

SELECT
    *
FROM dim_reddit_users;

SELECT
    COUNT(*),
    video_id,
    comment_id
FROM raw_youtube_videos_comments
GROUP BY ALL
HAVING COUNT(*) > 1;

SELECT
    *
FROM raw_youtube_videos;

SELECT
    *
FROM raw_youtube_videos_comments
LIMIT 10;

SELECT date_actual FROM dim_reddit_dates;

SELECT * FROM stg_youtube_videos;
SELECT * FROM stg_youtube_videos_comments;

-- this basically does a 
SELECT
    video_title,
    video_description,

    -- basic transformations
    t.value AS video_tag
FROM stg_youtube_videos,
LATERAL FLATTEN(input => video_tags) t;
