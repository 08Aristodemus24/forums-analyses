{{
    -- If you need to clean or transform your data before snapshotting, 
    -- create an ephemeral model or a staging model that applies the 
    -- necessary transformations. Then, reference this model in your 
    -- snapshot configuration. This approach keeps your snapshot 
    -- definitions clean and allows you to test and run transformations 
    -- separately.
    config(
        materialized='ephemeral'
    )
}}

SELECT * FROM {{ ref('stg_reddit_posts_comments') }}