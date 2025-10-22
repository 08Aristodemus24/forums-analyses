USE subreddit_analyses_db;

USE subreddit_analyses_db.subreddit_analyses_bronze;

CREATE FILE FORMAT IF NOT EXISTS pff
    TYPE = PARQUET;

CREATE STAGE IF NOT EXISTS sa_ext_stage_integration
    STORAGE_INTEGRATION = subreddit_analyses_si
    URL = 's3://subreddit-analyses-bucket' -- Replace with your S3 bucket and folder path
    FILE_FORMAT = pff;

LIST @sa_ext_stage_integration;

-- -- we can now just select from this table as 
-- -- if it were an existing table in snowflake because
-- -- mind you this table has not yet been created in our 
-- -- database schema
-- SELECT
--     $1:title::VARCHAR AS title,
--     $1:score::INTEGER AS score,
--     $1:id::VARCHAR AS id,
--     $1:url::VARCHAR AS url,
--     $1:comment::VARCHAR AS comment,
--     -- Add more columns as needed
-- FROM @sa_ext_stage_integration/raw_reddit_data.parquet;

CREATE TABLE IF NOT EXISTS RawRedditData AS (
    SELECT
        $1:title::VARCHAR AS title,
        $1:score::INTEGER AS score,
        $1:id::VARCHAR AS id,
        $1:url::VARCHAR AS url,
        $1:comment::VARCHAR AS comment,
        -- Add more columns as needed
    FROM @sa_ext_stage_integration/raw_reddit_data.parquet
);