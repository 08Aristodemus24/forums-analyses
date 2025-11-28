{{
    config(
        materialized='table',
        unique_key=['post_id_full']
    )
}}

WITH reddit_dates AS (
    SELECT *
    FROM {{ ref('dim_reddit_dates') }}
),

reddit_users AS (
    SELECT *
    FROM {{ ref('dim_reddit_users') }}
)

SELECT
    rp.post_title,
    rp.post_score,
    rp.post_id,
    rp.post_id_full,
    rp.post_url,
    -- post_author_username,
    
    rp.post_body,
    -- post_created_at,
    rp.post_edited_at,
    rp.added_at,
    rp.probability,
    rp.sentiment,

    rd.date_id,
    ru.user_id
FROM {{ ref('int_reddit_posts') }} rp
LEFT JOIN reddit_dates rd
ON rp.date_id = rd.date_id
LEFT JOIN reddit_users ru
ON rp.post_author_id_full = ru.user_id
