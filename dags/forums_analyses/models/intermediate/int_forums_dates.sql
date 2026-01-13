-- combine all dates in youtube dates and reddit dates
{{
    config(
        materialized='view',
    )
}}

SELECT *
FROM {{ ref('int_reddit_dates') }}
UNION
SELECT *
FROM {{ ref('int_youtube_dates') }}