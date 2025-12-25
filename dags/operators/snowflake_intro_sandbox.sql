USE acen_ops_playground;

CREATE SCHEMA IF NOT EXISTS larry;

USE acen_ops_playground.larry;

-- working with unstructured data
WITH my_comment_table AS (
    SELECT PARSE_JSON('{
      "etag": "aHTTcyKom34kuM7FUJwIwmvhH4s",
      "id": "UgxobbYFW5QNK-WFcNF4AaABAg",
      "kind": "youtube#commentThread",
      "replies": {
        "comments": [
          {
            "etag": "AIOuAJxmbBzRJ9s2le8VsLT6_gY",
            "id": "UgxobbYFW5QNK-WFcNF4AaABAg.9s4V-mdzLq79s5enfTdY8b",
            "kind": "youtube#comment",
            "snippet": {
              "authorChannelId": {
                "value": "UCaizTs-t-jXjj8H0-S3ATYA"
              },
              "authorChannelUrl": "http://www.youtube.com/@analyticswithadam",
              "authorDisplayName": "@analyticswithadam",
              "authorProfileImageUrl": "https://yt3.ggpht.com/2PBxLW_kGCY1hfybNHu216RHGBDBNZW4m7aS9kU2Lj_6waMwDMmDrGGEg6zJsYuAq63nDtNd=s48-c-k-c0x00ffffff-no-rj",
              "canRate": True,
              "channelId": "UCaizTs-t-jXjj8H0-S3ATYA",
              "likeCount": 0,
              "parentId": "UgxobbYFW5QNK-WFcNF4AaABAg",
              "publishedAt": "2023-07-13T06:26:01Z",
              "textDisplay": "Glad it was useful",
              "textOriginal": "Glad it was useful",
              "updatedAt": "2023-07-13T06:26:01Z",
              "videoId": "SIm2W9TtzR0",
              "viewerRating": "none"
            }
          },
          {
            "etag": "nsigOsdXr79YDN2WHK4gwJXAR7k",
            "id": "UgxobbYFW5QNK-WFcNF4AaABAg.9s4V-mdzLq7AOXiT2PhrVd",
            "kind": "youtube#comment",
            "snippet": {
              "authorChannelId": {
                "value": "UCA_EdNiC9bUaQsbTT3-YsAg"
              },
              "authorChannelUrl": "http://www.youtube.com/@JennaHasm",
              "authorDisplayName": "@JennaHasm",
              "authorProfileImageUrl": "https://yt3.ggpht.com/WUm40JH_Uqb4dYhjx6jYFBQzJHmwEMOFYPxLvHLLwo-1_5aISu5XaISbB84S7IYZG4Y0afJEyQ=s48-c-k-c0x00ffffff-no-rj",
              "canRate": True,
              "channelId": "UCaizTs-t-jXjj8H0-S3ATYA",
              "likeCount": 0, 
              "parentId": "UgxobbYFW5QNK-WFcNF4AaABAg",
              "publishedAt": "2025-10-21T09:12:46Z",
    
              "textDisplay": "\u200b@analyticswithadam<br>Do\\nyou know why youtube\\nrewards (monetarely)\\nchannel owners that\\ncreate distructive\\ncontent instead of\\nchannel owners like\\nyours for example. From\\nwhat O noticed it&#39;s\\nnot the niche topic\\nthat is the problem,\\nit&#39;s ... rewarding\\nthe worst of\\nhumans.<br>It\\ndoesn&#39;t make a lot\\nof sense to me.",
    
              "textOriginal": "\u200b@analyticswithadam<br>Do\\nyou know why youtube\\nrewards (monetarely)\\nchannel owners that\\ncreate distructive\\ncontent instead of\\nchannel owners like\\nyours for example. From\\nwhat O noticed it&#39;s\\nnot the niche topic\\nthat is the problem,\\nit&#39;s ... rewarding\\nthe worst of\\nhumans.<br>It\\ndoesn&#39;t make a lot\\nof sense to me.",
    
              "updatedAt": "2025-10-21T09:12:46Z",
              "videoId": "SIm2W9TtzR0",
              "viewerRating": "none"
            }
          }
        ]
      },
     "snippet": {
        "canReply": True,
        "channelId": "UCaizTs-t-jXjj8H0-S3ATYA",
        "isPublic": True,
        "topLevelComment": {
          "etag": "81lATGyrrx6iL2m58jTqimCH7bs",
          "id": "UgxobbYFW5QNK-WFcNF4AaABAg",
          "kind": "youtube#comment",
          "snippet": {
            "authorChannelId": {
              "value": "UCAeABcbzXpqZ9ELNznsqRBg"
            },
            "authorChannelUrl": "http://www.youtube.com/@oraclesql",
            "authorDisplayName": "@oraclesql",
            "authorProfileImageUrl": "https://yt3.ggpht.com/FVtbQGQrlS_QWV1bAMc-wZ9vUd1lKKix4yN3wtFE2N07-qdYjakorpSSk8u11Q-NQ5JIq7hl=s48-c-k-c0x00ffffff-no-rj",
            "canRate": True,
            "channelId": "UCaizTs-t-jXjj8H0-S3ATYA",
            "likeCount": 1,
            "publishedAt": "2023-07-12T19:32:27Z",
            "textDisplay": "Thank you for\\nthis Adam. Great\\ntuorial",
            "textOriginal": "Thank you for\\nthis Adam. Great\\ntuorial",
            "updatedAt": "2023-07-12T19:32:27Z",
            "videoId": "SIm2W9TtzR0",
            "viewerRating": "none"
          }
        },
        "totalReplyCount": 2,
        "videoId": "SIm2W9TtzR0"
      }
    }') AS comment_obj
),

comments AS (
    SELECT
        'comment' AS level,
        comment_obj:snippet:topLevelComment:snippet:videoId::VARCHAR(50) AS video_id,
        comment_obj:id::VARCHAR(50) AS comment_id,
        comment_obj:snippet:topLevelComment:snippet:authorChannelId:value::VARCHAR(50) AS author_channel_id,
        comment_obj:snippet:topLevelComment:snippet:channelId::VARCHAR(50) AS channel_id_where_comment_was_made,
        
        NULL AS parent_comment_id,
        
        comment_obj:snippet:topLevelComment:snippet:textOriginal::TEXT AS text_original,
        comment_obj:snippet:topLevelComment:snippet:textDisplay::TEXT AS text_display,
        comment_obj:snippet:topLevelComment:snippet:publishedAt::TIMESTAMP_NTZ AS published_at,
        comment_obj:snippet:topLevelComment:snippet:updatedAt::TIMESTAMP_NTZ AS updated_at,
        comment_obj:snippet:topLevelComment:snippet:likeCount::NUMBER(5, 0) AS like_count,
        comment_obj:snippet:topLevelComment:snippet:authorDisplayName::VARCHAR(50) AS author_display_name,
        comment_obj:snippet:topLevelComment:snippet:authorChannelUrl::VARCHAR(50) AS author_channel_url
    FROM my_comment_table
),

replies AS (
    SELECT 
        'reply' AS level,
        value:snippet:videoId::VARCHAR(50) AS video_id,
        value:id::VARCHAR(50) AS comment_id,
        value:snippet:authorChannelId:value::VARCHAR(50) AS author_channel_id,
        value:snippet:channelId::VARCHAR(50) AS channel_id_where_comment_was_made,
        value:snippet:parentId::VARCHAR(50) AS parent_comment_id,
        value:snippet:textOriginal::TEXT AS text_original,
        value:snippet:textDisplay::TEXT AS text_display,
        value:snippet:publishedAt::TIMESTAMP_NTZ AS published_at,
        value:snippet:updatedAt::TIMESTAMP_NTZ AS updated_at,
        value:snippet:likeCount::NUMBER(5, 0) AS like_count,
        value:snippet:authorDisplayName::VARCHAR(50) AS author_display_name,
        value:snippet:authorChannelUrl::VARCHAR(50) AS author_channel_url
    FROM 
        my_comment_table mct,
        -- this explode our array column value into
        -- their own respective rows, in this case
        -- we are aliasing my_comment_table accessing
        -- accessing the comment_obj column then the value
        -- of the replies key and then  the value of the
        -- comments key
        LATERAL FLATTEN(input => mct.comment_obj:replies:comments)
)

SELECT * FROM comments
UNION BY NAME
SELECT * FROM replies;



-- cloning
-- create a sample table
CREATE OR REPLACE TABLE acen_ops_playground.larry.acen_plant_capacities_copy AS (
    SELECT * FROM wesm.dbt_jquintos.acen_plant_capacities
);

SELECT * FROM acen_ops_playground.larry.acen_plant_capacities_copy;

-- say we want a clone of this table
CREATE OR REPLACE TABLE acen_ops_playground.larry.acen_plant_capacities_copy_clone
CLONE acen_ops_playground.larry.acen_plant_capacities_copy;

-- if we run this we will see that
-- acen_plant_capacities_copy has a certain number of 
-- allocated  bytes while acen_plant_capacities_copy_clone 
-- has 0 number of allocated bytes. This is because until
-- we add new data to this cloned table it will remain 0
-- and if we do decide to add data the size would now be
-- size of the original table + size of newly added data
-- e.g. original table is 20000 bytes and clone is 0 bytes
-- if we add new data of 200 bytes clone will now be 20200
-- bytes
SELECT * FROM acen_ops_playground.information_schema.table_storage_metrics; 

-- time travel with cloning, so let's
-- select our copied table again to ensure it
-- is out most recent query and save this most
-- recent query's id in a variable
SELECT * FROM acen_ops_playground.larry.acen_plant_capacities_copy;
SET good_data_query_id = LAST_QUERY_ID();
SELECT $good_data_query_id;

-- lets say our copied table was corrupted with
-- nulls and zeroes in certain columns
UPDATE acen_ops_playground.larry.acen_plant_capacities_copy
SET
   resource_name = NULL,
   iemop_registered_capacity = 0,
   pmax = 0,
   dc_capacity = 18,
   updated_at = CURRENT_TIMESTAMP();

-- say we want a clone of this corrupted table too
CREATE OR REPLACE TABLE acen_ops_playground.larry.acen_plant_capacities_copy_clone
CLONE acen_ops_playground.larry.acen_plant_capacities_copy;

-- checking our 'corrupted' table
SELECT * FROM acen_ops_playground.larry.acen_plant_capacities_copy;
SELECT * FROM acen_ops_playground.larry.acen_plant_capacities_copy_clone;

-- however running this would not allow us to run the timetravel 
-- statement we need to revert back to the previous state of the 
-- table as it would raise Statement <saved query id> cannot be used 
-- to specify time for time travel query.

    
-- we can however go back to our most recent
-- uncorrupted table state using the query
SELECT * FROM acen_ops_playground.larry.acen_plant_capacities_copy BEFORE(STATEMENT => $good_data_query_id);

-- because the corrupted table does not contain
-- id's we can use to update it with the timetraveled
-- tables values we can just create or replace the
-- corrupted table using the values of the timetraveled 
-- table
CREATE OR REPLACE TABLE acen_ops_playground.larry.acen_plant_capacities_copy_clone
CLONE acen_ops_playground.larry.acen_plant_capacities_copy BEFORE(STATEMENT => $good_data_query_id);

CREATE OR REPLACE TABLE acen_ops_playground.larry.acen_plant_capacities_copy AS (
    SELECT * FROM acen_ops_playground.larry.acen_plant_capacities_copy BEFORE(STATEMENT => $good_data_query_id)
);

-- we revert back both our table and cloned tables to
-- its previous state
SELECT * FROM acen_ops_playground.larry.acen_plant_capacities_copy;
SELECT * FROM acen_ops_playground.larry.acen_plant_capacities_copy_clone;



-- UDFs
-- 1. Create the practice table
CREATE OR REPLACE TABLE stg_youtube_practice (
    LEVEL VARCHAR(10),
    VIDEO_ID VARCHAR(20),
    COMMENT_ID VARCHAR(100) PRIMARY KEY,
    AUTHOR_CHANNEL_ID VARCHAR(50),
    CHANNEL_ID_WHERE_COMMENT_WAS_MADE VARCHAR(50),
    PARENT_COMMENT_ID VARCHAR(100),
    TEXT_ORIGINAL TEXT,
    TEXT_DISPLAY TEXT,
    PUBLISHED_AT TIMESTAMP_NTZ,
    UPDATED_AT TIMESTAMP_NTZ,
    LIKE_COUNT INT,
    AUTHOR_DISPLAY_NAME VARCHAR(100),
    AUTHOR_CHANNEL_URL VARCHAR(255)
);

INSERT INTO acen_ops_playground.larry.stg_youtube_practice (
    LEVEL,
    VIDEO_ID,
    COMMENT_ID,
    AUTHOR_CHANNEL_ID,
    CHANNEL_ID_WHERE_COMMENT_WAS_MADE,
    PARENT_COMMENT_ID,
    TEXT_ORIGINAL,
    TEXT_DISPLAY,
    PUBLISHED_AT,
    UPDATED_AT,
    LIKE_COUNT,
    AUTHOR_DISPLAY_NAME,
    AUTHOR_CHANNEL_URL
)
VALUES 
-- ORIGINAL 3 RECORDS FROM YOUR SCREENSHOTS
('reply', 'SIm2W9TtzR0', 'UgxobbYFW5QNK-WFcNF4AaABAg.9s4V-mdzLq79s5enfTc', 'UCaizTs-t-jXjj8H0-S3ATYA', 'UCaizTs-t-jXjj8H0-S3ATYA', 'UgxobbYFW5QNK-WFcNF4AaABAg', 'Glad it was useful', 'Glad it was useful', '2023-07-13 06:26:01', '2023-07-13 06:26:01', 0, '@analyticswithadam', 'http://www.youtube.com/@analyticswithadam'),
('reply', 'SIm2W9TtzR0', 'UgxobbYFW5QNK-WFcNF4AaABAg.9s4V-mdzLq7AOXiT2P', 'UCA_EdNiC9bUaQsbTT3-YsAg', 'UCaizTs-t-jXjj8H0-S3ATYA', 'UgxobbYFW5QNK-WFcNF4AaABAg', '@analyticswithadam... Do you know why...', '@analyticswithadam... Do you know why...', '2025-10-21 09:12:46', '2025-10-21 09:12:46', 0, '@JennaHasm', 'http://www.youtube.com/@JennaHasm'),
('comment', 'SIm2W9TtzR0', 'UgxobbYFW5QNK-WFcNF4AaABAg', 'UCAeABcbzXpqZ9ELNznsqRBg', 'UCaizTs-t-jXjj8H0-S3ATYA', NULL, 'Thank you for this Adam. Great tutorial', 'Thank you for this Adam. Great tutorial', '2023-07-12 19:32:27', '2023-07-12 19:32:27', 1, '@oraclesql', 'http://www.youtube.com/@oraclesql'),

-- 20 NEW DUMMY RECORDS FOR PRACTICE
('comment', 'SIm2W9TtzR0', 'C_ID_101', 'U_ACEN_001', 'UCaizTs-t-jXjj8H0-S3ATYA', NULL, 'Does ACEN use Snowflake for renewable energy monitoring?', 'Does ACEN use Snowflake for renewable energy monitoring?', '2025-12-16 08:00:00', '2025-12-16 08:00:00', 5, '@energy_watcher', 'http://youtube.com/@energy_watcher'),
('reply', 'SIm2W9TtzR0', 'R_ID_201', 'U_ACEN_002', 'UCaizTs-t-jXjj8H0-S3ATYA', 'C_ID_101', 'Yes, they do! Just started my OJT there today.', 'Yes, they do! Just started my OJT there today.', '2025-12-16 09:15:00', '2025-12-16 09:15:00', 2, '@ojt_newbie', 'http://youtube.com/@ojt_newbie'),
('comment', 'SIm2W9TtzR0', 'C_ID_102', 'U_DATA_003', 'UCaizTs-t-jXjj8H0-S3ATYA', NULL, 'How do I handle LATERAL FLATTEN in dbt?', 'How do I handle LATERAL FLATTEN in dbt?', '2025-12-17 10:30:00', '2025-12-17 10:30:00', 12, '@sql_master', 'http://youtube.com/@sql_master'),
('reply', 'SIm2W9TtzR0', 'R_ID_202', 'U_ACEN_002', 'UCaizTs-t-jXjj8H0-S3ATYA', 'C_ID_102', 'Check out the Snowflake documentation on Variant types.', 'Check out the Snowflake documentation on Variant types.', '2025-12-17 11:00:00', '2025-12-17 11:00:00', 1, '@ojt_newbie', 'http://youtube.com/@ojt_newbie'),
('comment', 'SIm2W9TtzR0', 'C_ID_103', 'U_BIZ_004', 'UCaizTs-t-jXjj8H0-S3ATYA', NULL, 'Market trends in solar are looking great this quarter.', 'Market trends in solar are looking great this quarter.', '2025-12-17 14:00:00', '2025-12-17 14:00:00', 8, '@solar_analyst', 'http://youtube.com/@solar_analyst'),
('reply', 'SIm2W9TtzR0', 'R_ID_203', 'U_ACEN_005', 'UCaizTs-t-jXjj8H0-S3ATYA', 'C_ID_103', 'Especially in the emerging markets!', 'Especially in the emerging markets!', '2025-12-17 15:20:00', '2025-12-17 15:20:00', 3, '@trend_tracker', 'http://youtube.com/@trend_tracker'),
('comment', 'SIm2W9TtzR0', 'C_ID_104', 'U_DEV_006', 'UCaizTs-t-jXjj8H0-S3ATYA', NULL, 'Is the YouTube API quota per user or per project?', 'Is the YouTube API quota per user or per project?', '2025-12-18 09:00:00', '2025-12-18 09:00:00', 20, '@dev_help', 'http://youtube.com/@dev_help'),
('reply', 'SIm2W9TtzR0', 'R_ID_204', 'U_ACEN_002', 'UCaizTs-t-jXjj8H0-S3ATYA', 'C_ID_104', 'Its per project. 10,000 units is the daily limit.', 'Its per project. 10,000 units is the daily limit.', '2025-12-18 10:10:00', '2025-12-18 10:10:00', 4, '@ojt_newbie', 'http://youtube.com/@ojt_newbie'),
('comment', 'SIm2W9TtzR0', 'C_ID_105', 'U_SQL_007', 'UCaizTs-t-jXjj8H0-S3ATYA', NULL, 'Window functions are the best part of Snowflake.', 'Window functions are the best part of Snowflake.', '2025-12-18 11:45:00', '2025-12-18 11:45:00', 15, '@data_engineer', 'http://youtube.com/@data_engineer'),
('reply', 'SIm2W9TtzR0', 'R_ID_205', 'U_DEV_006', 'UCaizTs-t-jXjj8H0-S3ATYA', 'C_ID_105', 'Better than traditional SQL for sure.', 'Better than traditional SQL for sure.', '2025-12-18 12:00:00', '2025-12-18 12:00:00', 2, '@dev_help', 'http://youtube.com/@dev_help'),
('comment', 'SIm2W9TtzR0', 'C_ID_106', 'U_ACEN_008', 'UCaizTs-t-jXjj8H0-S3ATYA', NULL, 'Excited for the ACEN Christmas party!', 'Excited for the ACEN Christmas party!', '2025-12-18 16:30:00', '2025-12-18 16:30:00', 30, '@hr_team', 'http://youtube.com/@hr_team'),
('reply', 'SIm2W9TtzR0', 'R_ID_206', 'U_ACEN_002', 'UCaizTs-t-jXjj8H0-S3ATYA', 'C_ID_106', 'Same here! Can we bring guests?', 'Same here! Can we bring guests?', '2025-12-18 17:00:00', '2025-12-18 17:00:00', 0, '@ojt_newbie', 'http://youtube.com/@ojt_newbie'),
('comment', 'SIm2W9TtzR0', 'C_ID_107', 'U_TECH_009', 'UCaizTs-t-jXjj8H0-S3ATYA', NULL, 'Using Kafka for streaming sensor data is a beast.', 'Using Kafka for streaming sensor data is a beast.', '2025-12-19 08:20:00', '2025-12-19 08:20:00', 11, '@iot_pro', 'http://youtube.com/@iot_pro'),
('reply', 'SIm2W9TtzR0', 'R_ID_207', 'U_DATA_003', 'UCaizTs-t-jXjj8H0-S3ATYA', 'C_ID_107', 'Hard to maintain but worth the latency gains.', 'Hard to maintain but worth the latency gains.', '2025-12-19 09:00:00', '2025-12-19 09:00:00', 1, '@sql_master', 'http://youtube.com/@sql_master'),
('comment', 'SIm2W9TtzR0', 'C_ID_108', 'U_ACEN_010', 'UCaizTs-t-jXjj8H0-S3ATYA', NULL, 'Great year for renewable energy projects.', 'Great year for renewable energy projects.', '2025-12-19 11:00:00', '2025-12-19 11:00:00', 40, '@green_future', 'http://youtube.com/@green_future'),
('reply', 'SIm2W9TtzR0', 'R_ID_208', 'U_ACEN_005', 'UCaizTs-t-jXjj8H0-S3ATYA', 'C_ID_108', 'Philippines is leading the way in Southeast Asia!', 'Philippines is leading the way in Southeast Asia!', '2025-12-19 11:30:00', '2025-12-19 11:30:00', 10, '@trend_tracker', 'http://youtube.com/@trend_tracker'),
('comment', 'SIm2W9TtzR0', 'C_ID_109', 'U_DEV_011', 'UCaizTs-t-jXjj8H0-S3ATYA', NULL, 'Anyone tried Snowflake Cortex AI for sentiment?', 'Anyone tried Snowflake Cortex AI for sentiment?', '2025-12-19 13:00:00', '2025-12-19 13:00:00', 6, '@ai_dev', 'http://youtube.com/@ai_dev'),
('reply', 'SIm2W9TtzR0', 'R_ID_209', 'U_ACEN_002', 'UCaizTs-t-jXjj8H0-S3ATYA', 'C_ID_109', 'Trying it today on these comments actually.', 'Trying it today on these comments actually.', '2025-12-19 13:45:00', '2025-12-19 13:45:00', 3, '@ojt_newbie', 'http://youtube.com/@ojt_newbie'),
('comment', 'SIm2W9TtzR0', 'C_ID_110', 'U_BIZ_012', 'UCaizTs-t-jXjj8H0-S3ATYA', NULL, 'What is the date format in Snowflake by default?', 'What is the date format in Snowflake by default?', '2025-12-19 15:00:00', '2025-12-19 15:00:00', 2, '@new_coder', 'http://youtube.com/@new_coder'),
('reply', 'SIm2W9TtzR0', 'R_ID_210', 'U_SQL_007', 'UCaizTs-t-jXjj8H0-S3ATYA', 'C_ID_110', 'Usually YYYY-MM-DD.', 'Usually YYYY-MM-DD.', '2025-12-19 15:30:00', '2025-12-19 15:30:00', 1, '@data_engineer', 'http://youtube.com/@data_engineer');

SELECT * FROM acen_ops_playground.larry.stg_youtube_practice;

-- creating python UDF
CREATE OR REPLACE FUNCTION foo (str_col VARCHAR, is_parent BOOLEAN)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
HANDLER = 'foo_py'
AS
$$
def foo_py(str_col, is_parent):
    if len(str_col) < 5:
        return "foo"

    elif 5 <= len(str_col) <= 10:
        return "bar"

    else:
        return "foobar"
$$;


-- we can pass whole columns to this UDF like pandas
-- apply functions 
SELECT FOO(author_display_name, TRUE) FROM stg_youtube_practice;

-- showing grants to current user
SHOW GRANTS TO ROLE DATA_ENGINEER;

CREATE OR REPLACE STORAGE INTEGRATION forums_analyses_si
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::612565766933:role/forums-analyses-ext-int-role'
    STORAGE_ALLOWED_LOCATIONS = ('s3://forums-analyses-bucket');

DESCRIBE STORAGE INTEGRATION forums_analyses_si;

CREATE FILE FORMAT IF NOT EXISTS acen_ops_playground.larry.pff
    TYPE = PARQUET;

CREATE OR REPLACE STAGE acen_ops_playground.larry.stg_reddit_posts_comments
    STORAGE_INTEGRATION = forums_analyses_si
    URL = 's3://forums-analyses-bucket/raw_reddit_posts_comments/' -- Replace with your S3 bucket and folder path
    FILE_FORMAT = acen_ops_playground.larry.pff;

CREATE OR REPLACE STAGE acen_ops_playground.larry.stg_reddit_posts
    STORAGE_INTEGRATION = forums_analyses_si
    URL = 's3://forums-analyses-bucket/raw_reddit_posts/' -- Replace with your S3 bucket and folder path
    FILE_FORMAT = acen_ops_playground.larry.pff;

CREATE OR REPLACE STAGE acen_ops_playground.larry.stg_youtube_videos_comments
    STORAGE_INTEGRATION = forums_analyses_si
    URL = 's3://forums-analyses-bucket/raw_youtube_videos_comments/' -- Replace with your S3 bucket and folder path
    FILE_FORMAT = acen_ops_playground.larry.pff;

CREATE OR REPLACE STAGE acen_ops_playground.larry.stg_youtube_videos
    STORAGE_INTEGRATION = forums_analyses_si
    URL = 's3://forums-analyses-bucket/raw_youtube_videos/' -- Replace with your S3 bucket and folder path
    FILE_FORMAT = acen_ops_playground.larry.pff;

-- DROP STAGE IF EXISTS acen_ops_playground.larry.stg_reddit_posts;
-- DROP STAGE IF EXISTS acen_ops_playground.larry.stg_reddit_posts_comments;

LIST @acen_ops_playground.larry.stg_reddit_posts_comments;
LIST @acen_ops_playground.larry.stg_reddit_posts;
LIST @acen_ops_playground.larry.stg_youtube_videos_comments;
LIST @acen_ops_playground.larry.stg_youtube_videos;

SELECT
    $1:post_id::VARCHAR(50) AS post_id,
    $1:post_name::VARCHAR(50) AS post_id_full,
    $1:level::VARCHAR(50) AS level,
    $1:comment_id::VARCHAR(50) AS comment_id,
    $1:comment_name::VARCHAR(50) AS comment_id_full,
    $1:comment_upvotes::INTEGER AS comment_upvotes,
    $1:comment_downvotes::INTEGER AS comment_downvotes,
    $1:comment_created_at::VARCHAR::TIMESTAMP_NTZ AS comment_created_at,
    $1:comment_edited_at::VARCHAR::TIMESTAMP_NTZ AS comment_edited_at,
    $1:comment_author_name::VARCHAR(50) AS comment_author_username,
    $1:comment_author_fullname::VARCHAR(50) AS comment_author_id_full,
    $1:comment_parent_id::VARCHAR(50) AS comment_parent_id_full,
    $1:comment_body::TEXT AS comment_body,
    $1:added_at::VARCHAR::TIMESTAMP_NTZ AS added_at
    -- pattern below is used to match all parquet files
FROM @acen_ops_playground.larry.stg_reddit_posts_comments (FILE_FORMAT => 'pff', PATTERN => '.*\.parquet');

SELECT
    $1:post_title::VARCHAR AS post_title,
    $1:post_score::INTEGER AS post_score,
    $1:post_id::VARCHAR(50) AS post_id,
    $1:post_name::VARCHAR(50) AS post_id_full,
    $1:post_url::VARCHAR AS post_url,
    $1:post_author_name::VARCHAR(50) AS post_author_username,
    $1:post_author_fullname::VARCHAR(50) AS post_author_id_full,
    $1:post_body::TEXT AS post_body,
    $1:post_created_at::VARCHAR::TIMESTAMP_NTZ AS post_created_at,
    $1:post_edited_at::VARCHAR::TIMESTAMP_NTZ AS post_edited_at,
    $1:added_at::VARCHAR::TIMESTAMP_NTZ AS added_at
    -- pattern below is used to match all parquet files
FROM @acen_ops_playground.larry.stg_reddit_posts (FILE_FORMAT => 'pff', PATTERN => '.*\.parquet');

SELECT
    $1:level::VARCHAR(50) AS level,
    $1:video_id::VARCHAR(50) AS video_id,
    $1:comment_id::VARCHAR(50) AS comment_id,
    $1:author_channel_id::VARCHAR(50) AS author_channel_id,
    $1:channel_id_where_comment_was_made::VARCHAR(50) AS channel_id_where_comment_was_made,
    $1:parent_comment_id::VARCHAR(50) AS parent_comment_id,
    $1:text_original::TEXT AS text_original,
    $1:text_display::TEXT AS text_display,
    $1:published_at::VARCHAR::TIMESTAMP_NTZ AS published_at,
    $1:updated_at::VARCHAR::TIMESTAMP_NTZ AS updated_at,
    $1:like_count::INTEGER AS like_count,
    $1:author_display_name::VARCHAR(250) AS author_display_name,
    $1:author_channel_url::VARCHAR AS author_channel_url,
    $1:added_at::VARCHAR::TIMESTAMP_NTZ AS added_at
    -- pattern below is used to match all parquet files
FROM @acen_ops_playground.larry.stg_youtube_videos_comments (FILE_FORMAT => 'pff', PATTERN => '.*\.parquet');

SELECT
    $1:video_id::VARCHAR(50) AS video_id,
    $1:duration::VARCHAR(50) AS duration,
    $1:channel_id::VARCHAR(50) AS channel_id,
    $1:channel_title::VARCHAR(250) AS channel_title,
    $1:video_title::VARCHAR AS video_title,
    $1:video_description::TEXT AS video_description,
    $1:video_tags::ARRAY AS video_tags,
    $1:comment_count::INTEGER AS comment_count,
    $1:favorite_count::INTEGER AS favorite_count,
    $1:like_count::INTEGER AS like_count,
    $1:view_count::INTEGER AS view_count,
    $1:made_for_kids::BOOLEAN AS made_for_kids,
    $1:published_at::VARCHAR::TIMESTAMP_NTZ AS published_at,
    $1:added_at::VARCHAR::TIMESTAMP_NTZ AS added_at
    -- pattern below is used to match all parquet files
FROM @acen_ops_playground.larry.stg_youtube_videos (FILE_FORMAT => 'pff', PATTERN => '.*\.parquet');

-- create tables where copied data will land
-- using snowpipe
CREATE OR REPLACE TABLE raw_reddit_posts_comments (
    post_id VARCHAR(50),
    post_id_full VARCHAR(50),
    level VARCHAR(50),
    comment_id VARCHAR(50),
    comment_id_full VARCHAR(50),
    comment_upvotes INTEGER,
    comment_downvotes INTEGER,
    comment_created_at TIMESTAMP_NTZ,
    comment_edited_at TIMESTAMP_NTZ,
    comment_author_username VARCHAR(50),
    comment_author_id_full VARCHAR(50),
    comment_parent_id_full VARCHAR(50),
    comment_body TEXT,
    added_at TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE raw_reddit_posts (
    post_title VARCHAR,
    post_score INTEGER,
    post_id VARCHAR(50),
    post_id_full VARCHAR(50),
    post_url VARCHAR,
    post_author_username VARCHAR(50),
    post_author_id_full VARCHAR(50),
    post_body TEXT,
    post_created_at TIMESTAMP_NTZ,
    post_edited_at TIMESTAMP_NTZ,
    added_at TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE raw_youtube_videos_comments (
    level VARCHAR(50),
    video_id VARCHAR(50),
    comment_id VARCHAR(50),
    author_channel_id VARCHAR(50),
    channel_id_where_comment_was_made VARCHAR(50),
    parent_comment_id VARCHAR(50),
    text_original TEXT,
    text_display TEXT,
    published_at TIMESTAMP_NTZ,
    updated_at TIMESTAMP_NTZ,
    like_count INTEGER,
    author_display_name VARCHAR(250),
    author_channel_url VARCHAR,
    added_at TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE raw_youtube_videos (
    video_id VARCHAR(50),
    duration VARCHAR(50),
    channel_id VARCHAR(50),
    channel_title VARCHAR(250),
    video_title VARCHAR,
    video_description TEXT,
    video_tags ARRAY,
    comment_count INTEGER,
    favorite_count INTEGER,
    like_count INTEGER,
    view_count INTEGER,
    made_for_kids BOOLEAN,
    published_at TIMESTAMP_NTZ,
    added_at TIMESTAMP_NTZ
);


-- copy the s3 reddit posts comments table into 
-- the empty reddit posts comments snowflake table
-- how this will run is if the s3 delta table 
-- experiences an event of adding new parquet files
-- then this pipe will run the copy
CREATE OR REPLACE PIPE acen_ops_playground.larry.reddit_posts_comments_pipe
AUTO_INGEST = TRUE
AS 
COPY INTO acen_ops_playground.larry.raw_reddit_posts_comments
FROM (
    SELECT
        $1:post_id::VARCHAR(50) AS post_id,
        $1:post_name::VARCHAR(50) AS post_id_full,
        $1:level::VARCHAR(50) AS level,
        $1:comment_id::VARCHAR(50) AS comment_id,
        $1:comment_name::VARCHAR(50) AS comment_id_full,
        $1:comment_upvotes::INTEGER AS comment_upvotes,
        $1:comment_downvotes::INTEGER AS comment_downvotes,
        $1:comment_created_at::VARCHAR::TIMESTAMP_NTZ AS comment_created_at,
        $1:comment_edited_at::VARCHAR::TIMESTAMP_NTZ AS comment_edited_at,
        $1:comment_author_name::VARCHAR(50) AS comment_author_username,
        $1:comment_author_fullname::VARCHAR(50) AS comment_author_id_full,
        $1:comment_parent_id::VARCHAR(50) AS comment_parent_id_full,
        $1:comment_body::TEXT AS comment_body,
        $1:added_at::VARCHAR::TIMESTAMP_NTZ AS added_at
        -- pattern below is used to match all parquet files
    FROM @acen_ops_playground.larry.stg_reddit_posts_comments (FILE_FORMAT => 'pff', PATTERN => '.*\.parquet')
);
-- DROP PIPE IF EXISTS acen_ops_playground.larry.reddit_posts_comments_pipe;

CREATE OR REPLACE PIPE acen_ops_playground.larry.reddit_posts_pipe
AUTO_INGEST = TRUE
AS 
COPY INTO acen_ops_playground.larry.raw_reddit_posts
FROM (
    SELECT
        $1:post_title::VARCHAR AS post_title,
        $1:post_score::INTEGER AS post_score,
        $1:post_id::VARCHAR(50) AS post_id,
        $1:post_name::VARCHAR(50) AS post_id_full,
        $1:post_url::VARCHAR AS post_url,
        $1:post_author_name::VARCHAR(50) AS post_author_username,
        $1:post_author_fullname::VARCHAR(50) AS post_author_id_full,
        $1:post_body::TEXT AS post_body,
        $1:post_created_at::VARCHAR::TIMESTAMP_NTZ AS post_created_at,
        $1:post_edited_at::VARCHAR::TIMESTAMP_NTZ AS post_edited_at,
        $1:added_at::VARCHAR::TIMESTAMP_NTZ AS added_at
        -- pattern below is used to match all parquet files
    FROM @acen_ops_playground.larry.stg_reddit_posts (FILE_FORMAT => 'pff', PATTERN => '.*\.parquet')
);
-- DROP PIPE IF EXISTS acen_ops_playground.larry.reddit_posts_pipe;

CREATE OR REPLACE PIPE acen_ops_playground.larry.youtube_videos_comments_pipe
AUTO_INGEST = TRUE
AS 
COPY INTO acen_ops_playground.larry.raw_youtube_videos_comments
FROM (
    SELECT
        $1:level::VARCHAR(50) AS level,
        $1:video_id::VARCHAR(50) AS video_id,
        $1:comment_id::VARCHAR(50) AS comment_id,
        $1:author_channel_id::VARCHAR(50) AS author_channel_id,
        $1:channel_id_where_comment_was_made::VARCHAR(50) AS channel_id_where_comment_was_made,
        $1:parent_comment_id::VARCHAR(50) AS parent_comment_id,
        $1:text_original::TEXT AS text_original,
        $1:text_display::TEXT AS text_display,
        $1:published_at::VARCHAR::TIMESTAMP_NTZ AS published_at,
        $1:updated_at::VARCHAR::TIMESTAMP_NTZ AS updated_at,
        $1:like_count::INTEGER AS like_count,
        $1:author_display_name::VARCHAR(250) AS author_display_name,
        $1:author_channel_url::VARCHAR AS author_channel_url,
        $1:added_at::VARCHAR::TIMESTAMP_NTZ AS added_at
        -- pattern below is used to match all parquet files
    FROM @acen_ops_playground.larry.stg_youtube_videos_comments (FILE_FORMAT => 'pff', PATTERN => '.*\.parquet')
);

CREATE OR REPLACE PIPE acen_ops_playground.larry.youtube_videos_pipe
AUTO_INGEST = TRUE
AS 
COPY INTO acen_ops_playground.larry.raw_youtube_videos
FROM (
    SELECT
        $1:video_id::VARCHAR(50) AS video_id,
        $1:duration::VARCHAR(50) AS duration,
        $1:channel_id::VARCHAR(50) AS channel_id,
        $1:channel_title::VARCHAR(250) AS channel_title,
        $1:video_title::VARCHAR AS video_title,
        $1:video_description::TEXT AS video_description,
        $1:video_tags::ARRAY AS video_tags,
        $1:comment_count::INTEGER AS comment_count,
        $1:favorite_count::INTEGER AS favorite_count,
        $1:like_count::INTEGER AS like_count,
        $1:view_count::INTEGER AS view_count,
        $1:made_for_kids::BOOLEAN AS made_for_kids,
        $1:published_at::VARCHAR::TIMESTAMP_NTZ AS published_at,
        $1:added_at::VARCHAR::TIMESTAMP_NTZ AS added_at
        -- pattern below is used to match all parquet files
    FROM @acen_ops_playground.larry.stg_youtube_videos (FILE_FORMAT => 'pff', PATTERN => '.*\.parquet')
);

-- we do this to get the value of the notification channel column
-- as we will need this value for the event notification for s3
-- bucket so our pipes trigger when certain events in our s3
-- bucket happen
SHOW PIPES;

SELECT COUNT(*) FROM acen_ops_playground.larry.raw_reddit_posts_comments;
SELECT COUNT(*) FROM acen_ops_playground.larry.raw_reddit_posts;
SELECT COUNT(*) FROM acen_ops_playground.larry.raw_youtube_videos_comments;
SELECT COUNT(*) FROM acen_ops_playground.larry.raw_youtube_videos;

-- check for duplicates in youtube videos comments
SELECT
    COUNT(*),
    comment_id,
    video_id 
FROM acen_ops_playground.larry.raw_youtube_videos_comments
GROUP BY ALL
HAVING COUNT(*) > 1
LIMIT 500;

-- check for duplicates in youtube videos
SELECT 
    COUNT(*),
    video_id
FROM acen_ops_playground.larry.raw_youtube_videos
GROUP BY ALL
HAVING COUNT(*) > 1;

SELECT * FROM acen_ops_playground.larry.raw_youtube_videos LIMIT 10;


SELECT SYSTEM$PIPE_STATUS('reddit_posts_pipe');