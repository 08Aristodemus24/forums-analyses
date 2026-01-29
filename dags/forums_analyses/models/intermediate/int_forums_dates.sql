-- combine all dates in youtube dates and reddit dates
{{
    config(
        materialized='ephemeral',
    )
}}

SELECT *
FROM {{ ref('int_reddit_dates') }}
UNION
SELECT *
FROM {{ ref('int_youtube_dates') }}