{{ 
    config(
        materialized='incremental',
        unique_key=['post_id_full', 'comment_id_full', 'comment_parent_id_full'],
        on_schema_change='sync_all_columns'
    )
}}

WITH reddit_posts_comments AS (
    SELECT
        post_id,
        post_name AS post_id_full,
        level,
        comment_id,
        comment_name AS comment_id_full,
        comment_upvotes,
        comment_downvotes,
        comment_created_at,
        comment_edited_at,
        comment_author_name AS comment_author_username,
        comment_author_fullname AS comment_author_id_full,
        comment_parent_id AS comment_parent_id_full,
        comment_body,
        added_at
        -- Add more columns as needed
    FROM {{ source('forums_data', 'raw_reddit_posts_comments') }}
)
-- This Jinja macro tells dbt: only execute the WHERE clause after the first run.

SELECT *
FROM reddit_posts_comments
{% if is_incremental() %}
WHERE
    -- Process files that were created/uploaded to S3 *after* the last max timestamp
    -- stored in your Snowflake destination table.
    -- we use the comment/reply's created_at timestmap
    
    -- say our scraper scrapes a comment with created_at 2025-11-7 and
    -- initially edited_at as 1970-01-01, and then by some chance the 
    -- comment is edited again at 2025-11-9 

    -- how incremental model works is that it adds newer records
    -- and this includes newly inserted ones and updated ones in our
    -- OLTP system or in this case our, but how these new records are
    -- identified is up to us. 

    -- we can use created_at for a comment to identify a new comment
    -- scraped since every comment made has strictly a unique timestamp
    
    -- but how do we track updates for our incremental models? This
    -- means comment edits, as well as the automatic changing of its
    -- edited_at timestamp. 

    -- in our case hindi predictable na makuha natin ang same comment 
    -- since our scraper runs daily supposedly, and sometimes top posts
    -- change everyday and therefore the comments in it also
    -- change, but at times we may indeed scrape the same post and
    -- therefore the same comment which may have indeed have changed
    -- and this is what we want to track, kasi pag created_at lang ang
    -- ginawa natin identifier as a new record, we can never know if
    -- this is a new record since it will not be selected because of
    -- the below query since it only queries for our records more recent
    -- than those in our data warehouse. We want also to include this
    -- record that just so happened to also be scraped and at the same time
    -- edited

    -- so if we use a primary key or in this case composite key (a group 
    -- of primary keys) we could track the changes of this record in our 
    -- "OLTP system" because it has been included in this filter for the
    -- incremental model
    
    added_at > (SELECT MAX(added_at) FROM {{ this }})
{% endif %}