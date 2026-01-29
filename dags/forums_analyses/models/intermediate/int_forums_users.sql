-- combine all dates in youtube dates and reddit dates
{{
    config(
        materialized='ephemeral',
    )
}}

SELECT *
FROM {{ ref('int_reddit_users') }}
UNION
SELECT *
FROM {{ ref('int_youtube_users') }}