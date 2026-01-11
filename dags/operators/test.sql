USE forums_analyses_db;
USE forums_analyses_db.forums_analyses_bronze;


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