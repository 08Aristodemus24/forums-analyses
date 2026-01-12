-- extracts the unique dates from the timestamp columns of 
-- posts and those that made comments and replies
{{
    config(
        materialized='view',
    )
}}

-- Get unique dates from the comments staging table
WITH unique_comment_dates AS (
    SELECT 
        DISTINCT
        DATE(comment_created_at) AS date_actual -- Extract only the DATE part
    FROM {{ ref('stg_reddit_posts_comments') }} -- Reference your staging comments table
    WHERE comment_created_at IS NOT NULL
),

-- Union with unique dates from the posts staging table
unique_post_dates AS (
    SELECT 
        DISTINCT
        DATE(post_created_at) AS date_actual
    FROM {{ ref('stg_reddit_posts') }} -- Reference your staging posts table
    WHERE post_created_at IS NOT NULL
),

-- Combine all unique dates into one list
all_unique_dates AS (
    SELECT date_actual 
    FROM unique_comment_dates
    
    UNION BY NAME

    SELECT date_actual 
    FROM unique_post_dates
),

reformated_dates AS (
    SELECT
        date_actual,
        
        -- Generate the surrogate key (e.g., YYYYMMDD)
        CAST(TO_CHAR(date_actual, 'YYYYMMDD') AS INT) AS date_id,

        -- Basic date attributes
        EXTRACT(YEAR FROM date_actual) AS calendar_year,
        EXTRACT(MONTH FROM date_actual) AS calendar_month_num,
        EXTRACT(DAY FROM date_actual) AS calendar_day,
        
        -- Day of week attributes
        DAYNAME(date_actual) AS day_of_week,
        CASE
            -- if 0 or 6 it means sunday and saturday respectively
            -- 0, 1, 2, 3, 4, 5, 6 represent sunday to monday
            WHEN DAYOFWEEK(date_actual) IN (0, 6) THEN TRUE ELSE FALSE 
        END AS is_weekend
        
    FROM all_unique_dates
)
-- Final output with core attributes derived from the date
SELECT
    date_actual,
    date_id,
    calendar_year,
    CASE 
        WHEN calendar_month_num = 1 THEN 'January'
        WHEN calendar_month_num = 2 THEN 'February'
        WHEN calendar_month_num = 3 THEN 'March'
        WHEN calendar_month_num = 4 THEN 'April'
        WHEN calendar_month_num = 5 THEN 'May'
        WHEN calendar_month_num = 6 THEN 'June'
        WHEN calendar_month_num = 7 THEN 'July'
        WHEN calendar_month_num = 8 THEN 'August'
        WHEN calendar_month_num = 9 THEN 'September'
        WHEN calendar_month_num = 10 THEN 'October'
        WHEN calendar_month_num = 11 THEN 'November'
        WHEN calendar_month_num = 12 THEN 'December'
        ELSE NULL
    END AS calendar_month,
    calendar_day,
    day_of_week,
    is_weekend
FROM reformated_dates
ORDER BY date_actual

-- question is would hour at least matter in analyses of comments and posts?
-- because if it would we need to remove it