USE DATABASE forums_analyses_db;
USE SCHEMA forums_analyses_bronze;
SELECT * FROM raw_youtube_videos;

-- check for duplicates before creating stream object
-- mote we can use a catchall columns since
-- we are grouping anyway by all columns
SELECT  
    *
FROM raw_youtube_videos
GROUP BY ALL
HAVING COUNT(*) > 1;

-- create a stream on the raw youtube videos 
-- because this is an iceberg table we cannot track
-- changes that invovle update, delete transactions 
-- so we are limited to only tracking transactions that
-- involve inserts/appends so we INSERT_ONLY array_agg
-- to true to explicitly tell snowflake that we will
-- exclude tracking update or delete transactions
CREATE OR REPLACE STREAM raw_youtube_videos_stream 
ON TABLE forums_analyses_db.forums_analyses_bronze.raw_youtube_videos
INSERT_ONLY = TRUE;

-- initially querying from our stream object
-- that will presumably be containing meta data
-- of the newly inserted rows (not rows that
-- that have been deleted or updated though)
-- will be empty, but once this iceberg table by
-- way of an insert transaction the stream object
-- when queried will contain the meta data of the
-- newly inserted row/s, together with what kind of
-- transaction was involved in this case only an
-- insert
SELECT * FROM forums_analyses_db.forums_analyses_bronze.raw_youtube_videos_stream;

-- after an insertion of new data in our
-- iceberg table
SELECT * FROM forums_analyses_db.forums_analyses_bronze.raw_youtube_videos_stream;

-- create temporary table that will contain
-- resulting aggregations/transformations
-- from invoking stored procedure
CREATE OR REPLACE TEMPORARY TABLE top_10_yt_vids (
    video_title VARCHAR(255),
    channel_title VARCHAR(255),
    like_count INTEGER
);

CREATE OR REPLACE PROCEDURE forums_analyses_db.forums_analyses_bronze.get_top_10_yt_videos ()
RETURNS VARCHAR
AS 
$$
    BEGIN
        INSERT INTO top_10_yt_vids (
            video_title,
            channel_title,
            like_count
        ) WITH recent_videos AS (
            -- we can create a stored procedure here to pick out
            -- the inserts, 
            SELECT
                *
            FROM forums_analyses_db.forums_analyses_bronze.raw_youtube_videos_stream
            WHERE METADATA$ACTION = 'INSERT'
        )
        -- make an aggregation or some sort of
        -- transformation to the data
        SELECT
            video_title,
            channel_title,
            like_count
        FROM recent_videos
        ORDER BY like_count DESC
        LIMIT 10;
    END
$$;

DESCRIBE TABLE raw_youtube_videos;

-- -- note iceberg tables cannot be modified
-- -- as they are only read only
-- INSERT INTO forums_analyses_db.forums_analyses_bronze.raw_youtube_videos (
--     VIDEO_ID,
--     DURATION,
--     CHANNEL_ID,
--     CHANNEL_TITLE,
--     VIDEO_TITLE,
--     VIDEO_DESCRIPTION,
--     VIDEO_TAGS,
--     COMMENT_COUNT,
--     FAVORITE_COUNT,
--     LIKE_COUNT,
--     VIEW_COUNT,
--     MADE_FOR_KIDS,
--     PUBLISHED_AT,
--     ADDED_AT
-- ) VALUES (
--     'somevideoid',
--     'PT30S',
--     'somechannelid',
--     'somechannelid',
--     'somechanneltitle',
--     'somevidtitle',
--     'somedescription',
--     ['some tag 1', 'some tag 2'],
--     999,
--     999,
--     999999999999,
--     999999999999,
--     TRUE,
--     '1945-09-02 00:00:00.000',
--     CURRENT_TIMESTAMP()
-- );

SELECT * FROM top_10_yt_vids;

-- invoke stored procedure to make transformations
-- from recent inserts in stream object
CALL forums_analyses_db.forums_analyses_bronze.get_top_10_yt_videos();

-- after invokation we should finally see our
-- newly inserted rows in our table that should
-- contain our transformations
SELECT * FROM top_10_yt_vids;



-- creating dynamic tables
