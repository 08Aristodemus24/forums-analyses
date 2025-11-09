USE forums_analyses_db;

USE forums_analyses_db.forums_analyses_bronze;

-- SELECT SYSTEM$VERIFY_EXTERNAL_VOLUME('forums_analyses_ext_vol');

CREATE FILE FORMAT IF NOT EXISTS pff
    TYPE = PARQUET;

CREATE OR REPLACE STAGE sa_ext_stage_integration
    STORAGE_INTEGRATION = forums_analyses_si
    URL = 's3://forums-analyses-bucket' -- Replace with your S3 bucket and folder path
    FILE_FORMAT = pff;

LIST @sa_ext_stage_integration;

--create the catalog integration for Delta tables 
CREATE OR REPLACE CATALOG INTEGRATION delta_catalog_integration
    CATALOG_SOURCE = OBJECT_STORE
    TABLE_FORMAT = DELTA
    ENABLED = TRUE;

CREATE OR REPLACE ICEBERG TABLE raw_reddit_posts_comments
    CATALOG = delta_catalog_integration
    EXTERNAL_VOLUME = forums_analyses_ext_vol
    BASE_LOCATION = 'raw_reddit_posts_comments'
    AUTO_REFRESH = TRUE;

SELECT * FROM raw_reddit_posts_comments;
-- -- we can now just select from this table as 
-- -- if it were an existing table in snowflake because
-- -- mind you this table has not yet been created in our 
-- -- database schema
-- CREATE TABLE IF NOT EXISTS RawRedditData AS (
--     SELECT
--         $1:title::VARCHAR AS title,
--         $1:score::INTEGER AS score,
--         $1:id::VARCHAR AS id,
--         $1:url::VARCHAR AS url,
--         $1:comment::VARCHAR AS comment,
--         -- Add more columns as needed
--     FROM @sa_ext_stage_integration/raw_reddit_data.parquet
-- );