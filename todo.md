# Setting up azure workspace
* create an azure account at 
* setup azure databricks service (data transformation)
* setup azure storage account (data lake to store raw and transformed data)
* create azure synapse analytics service (DWH)
* configuring azure databricks to communicate with azure data lake storage to read data

# setting up reddit api data extractor 
* <s>create the records for each post, comment, and reply from each comment and reply in a post</s>
* <s>dump to aws s3 as data lake storage for later ingestion by dbt to data warehouse</s>

# setting up ingestor of reddit data in s3 to snowflake
* <s>HTTPError: 422 Client Error: Unprocessable Entity for url still occurs in SnowflakeSqlApiOperator when attempting to run code that will ingest data from s3 into snowflake through catalog integration</s>

- https://www.astronomer.io/docs/learn/connections/snowflake
- https://www.astronomer.io/docs/learn/airflow-snowflake

# setting up infrastructure for IAM Policy, S3 Bucket, Snowflake External Stage
* <s>if snowflake trial epires create account again, and setup credentials again in profiles.yaml of dbt and in .env since you run it also in airflow</s>
* <s>this will mean setting up sequentially IAM role, IAM policy,  storage integrations again</s>
- https://medium.com/@nakaken0629/how-to-create-an-external-stage-for-amazon-s3-on-snowflake-by-terraform-34c67c78a22a
- reason why you may not be able to describe external volume created by terraform is because of privileges, since creating an external volume through the UI vs having terraform creating it perhaps may only grant certain permissions to it
- https://snowstack.ai/blog/snowflake-terraform-complete-guide-zero-to-production
- https://medium.com/snowflake/so-you-want-to-terraform-snowflake-a6d16ca3237e
- https://stackoverflow.com/questions/66609641/setting-a-multi-line-value-in-terraform-variables

# setting up reddit_posts staging model
* <s>I will have to also include timestamp to when comment or post was made so that incremental model can include a potentially edited post if a post has been edited and just so happened to be scraped again </s>

# setting up intermediate models of reddit posts and reddit posts comments
* setup the dimension of users for posts and comments tables
    |- draw table of posts and posts comments to get only columns needed for transaction table
    |- need some way to modify the timestamps of the posts and comments tables to model them into date dimension tables
    |- draw the vague idea of your users and date dimension tables
* there is snowflake cortex ai to determine the sentiment of the posts and comments of users
    |- do I determine the sentiment when data is still raw meaning before loading to data warehouse using `load_data_from_s3`
    |- or do I determine the sentiment when data is finally loaded into the datawarehouse using dbt? I mean the former does violate the ELT process
    |- what we could do is build an intermediate table that determines the sentiment of posts and comments using snowflake cortex ai
* 

# setting up youtube api data extractor
* <s>setup search of videos of a certain topic</s>
* <s>use the searched video ids to get statistics, snippet, etc.</s>
* <s>in each video id setup request for getting the comment threads from each video</s>
* I know now why
```
-- check for duplicates in youtube videos comments
SELECT
    COUNT(*),
    comment_id,
    video_id 
FROM acen_ops_playground.larry.raw_youtube_videos_comments
GROUP BY ALL
HAVING COUNT(*) > 1
LIMIT 500;
```
kept returning duplicates of particular comment ids like 'Ugxg_icY1-vLqVV2gJV4AaABAg' even if there was a different timestamp e.g. 
[comment, 5QIQ5QHqDbw, Ugxg_icY1-vLqVV2gJV4AaABAg, UC2negEr32z8nhZ5cPxCxJMg, UCNqFDjYTexJDET3rPDrmJKg, null, Your. Idol, Your. Idol, 2025-12-24 18:14:39.000, 2025-12-24 18:14:39.000, 0, @OLAOLUWAKIITANALIMABIOLA, http://www.youtube.com/@OLAOLUWAKIITANALIMABIOLA, 2025-12-25 02:18:53.336] and [comment, 5QIQ5QHqDbw, Ugxg_icY1-vLqVV2gJV4AaABAg, UC2negEr32z8nhZ5cPxCxJMg, UCNqFDjYTexJDET3rPDrmJKg, null, Your. Idol, Your. Idol, 2025-12-24 18:14:39.000, 2025-12-24 18:14:39.000, 0, @OLAOLUWAKIITANALIMABIOLA, http://www.youtube.com/@OLAOLUWAKIITANALIMABIOLA, 2025-12-25 02:18:53.720]

it is because my scraper 

```
# define comments where all comments in videos will be
# stored
comments = []
for video_id in video_ids:
        try: 
            params = {
                "part": ",".join(["snippet", "replies"]),
                "videoId": video_id,
                "maxResults": 100
            }
            
            next_page_token = None
            request = youtube.commentThreads().list(**params)

            for _ in range(limit):
                response = request.execute()
                
                for item in response["items"]:
                    # append top level comment statistics
                    comments.append({
                        "level": "comment",
                
                ...

                next_page_token = response.get("nextPageToken")
                if not next_page_token:
                    break
...
```

* Going back to the youtube videos comments scraper that potentially duplicates the comments scraped and still writes the duplicates in a delta table I've rewritten it actually back to the original

```
def extract_videos_comments(

    youtube,

    video_ids: list[str],

    limit: int,

    aws_creds: dict,

    bucket_name: str,

    folder_name: str,

    object_name: str,

    is_local: bool,

    upsert_func: Callable

):

    """

    Docstring for extract_videos_comments

   

    :param youtube: Description

    :param video_ids: Description

    :param limit: Description

    :param aws_creds: Description

    :param bucket_name: Description

    :param folder_name: Description

    :param object_name: Description

    :param is_local: Description

    :param upsert_func: Description

    """



   

    # define comments where all comments in videos will be

    # stored

    comments = []

    for video_id in video_ids:

        try:

            params = {

                "part": ",".join(["snippet", "replies"]),

                "videoId": video_id,

                "maxResults": 100

            }

           

            next_page_token = None

            request = youtube.commentThreads().list(**params)



            count = 0

            # for _ in range(limit):

            while True:

                response = request.execute()

               

                for item in response["items"]:

                    print(f"count is at {count} for item: ")

                    pprint.pprint(item)

                    # append top level comment statistics

                    comments.append({

                        "level": "comment",

                        "video_id": item.get("snippet")\

                            .get("topLevelComment")\

                            .get("snippet")\

                            .get("videoId"),

                        "comment_id": item.get("id"),

                        "author_channel_id": item.get("snippet")\

                            .get("topLevelComment")\

                            .get("snippet")\

                            .get("authorChannelId")\

                            .get("value"),

                        "channel_id_where_comment_was_made": item.get("snippet")\

                            .get("topLevelComment")\

                            .get("snippet")\

                            .get("channelId"),

                        "parent_comment_id": None,

                        "text_original": item.get("snippet")\

                            .get("topLevelComment")\

                            .get("snippet")\

                            .get("textOriginal"),

                        "text_display": item.get("snippet")\

                            .get("topLevelComment")\

                            .get("snippet")\

                            .get("textDisplay"),

                        "published_at": item.get("snippet")\

                            .get("topLevelComment")\

                            .get("snippet")\

                            .get("publishedAt"),

                        "updated_at": item.get("snippet")\

                            .get("topLevelComment")\

                            .get("snippet")\

                            .get("updatedAt"),

                        "like_count": item.get("snippet")\

                            .get("topLevelComment")\

                            .get("snippet")\

                            .get("likeCount"),

                        "author_display_name": item.get("snippet")\

                            .get("topLevelComment")\

                            .get("snippet")\

                            .get("authorDisplayName"),

                        "author_channel_url": item.get("snippet")\

                            .get("topLevelComment")\

                            .get("snippet")\

                            .get("authorChannelUrl"),

                        "added_at": dt.datetime.now()

                    })



                    # if replies key does not exist in items then

                    # that means there are no replies to the top

                    # level comment thereby not running the loop

                    if item.get("replies"):

                        for reply in item.get("replies").get("comments"):

                            comments.append({

                                "level": "reply",

                                "video_id": reply.get("snippet")\

                                    .get("videoId"),

                                "comment_id": reply.get("id"),

                                "author_channel_id": reply.get("snippet")\

                                    .get("authorChannelId")\

                                    .get("value"),

                                "channel_id_where_comment_was_made": reply.get("snippet")\

                                    .get("channelId"),

                                "parent_comment_id": reply.get("snippet")\

                                    .get("parentId"),

                                "text_original": reply.get("snippet")\

                                    .get("textOriginal"),

                                "text_display": reply.get("snippet")\

                                    .get("textDisplay"),

                                "published_at": reply.get("snippet")\

                                    .get("publishedAt"),

                                "updated_at": reply.get("snippet")\

                                    .get("updatedAt"),

                                "like_count": reply.get("snippet")\

                                    .get("likeCount"),

                                "author_display_name": reply.get("snippet")\

                                    .get("authorDisplayName"),

                                "author_channel_url": reply.get("snippet")\

                                    .get("authorChannelUrl"),

                                "added_at": dt.datetime.now()

                            })



                next_page_token = response.get("nextPageToken")

                if not next_page_token:

                    break



                count += 1



        except HttpError as e:

            logger.warning(f"error `{e}` has occured from videoId {video_id}.")

            logger.warning("Appending empty comment still...")



            # append empty comment, as we know this comes from a

            # made for kids video, however this can still be prone to

            # duplicates, since the comment scraper can potentially

            # use the same video, raise an error because of lack

            # of stats trigger the except block and append a duplicate

            # empty comment  

            comments.append({
                "level": "comment",
                "video_id": video_id,
                "comment_id": None,
                "author_channel_id": None,
                "channel_id_where_comment_was_made": None,
                "parent_comment_id": None,
                "text_original": None,
                "text_display": None,
                "published_at": None,
                "updated_at": None,
                "like_count": None,
                "author_display_name": None,
                "author_channel_url": None,
                "added_at": dt.datetime.now()
            })    

    pprint.pprint(comments)

    logger.info(f"comments count: {len(comments)}")



    # convert the list of dictionaries/records to pyarrow

    # table from scraped data

    videos_comments_table = pa.Table.from_pylist(comments)

    logger.info(f"videos comments and replies table shape:{videos_comments_table.shape}")



    write_delta_to_bucket(aws_creds, videos_comments_table, bucket_name, object_name, folder_name, is_local, upsert_func)
```

However this is why I originally replaced before the while True to for _ in range(args.limit) instead so that it limits to large comment sections to only a few handful say if a comment section has 100000 comments I only limit it to 250 but sometimes I think that whhen a video contains 50 comments only and the limit si 250 the
```
for _ in range(args.limit)
    ...
    next_page_token = response.get('nextPageToken'):
    ...
    if not next_page_token:
        break
```
has to run 250 times. But my question with this is won't next_page_token have to be null if we've already hit the limit of comments in the first place which is 50 which is less than 250? Idk help me understand?

You’ve got a solid grasp of the logic here, but there is one subtle "gotcha" regarding the difference between API requests and total comments that might be causing the confusion.

To answer your main question: Yes, you are correct. If a video only has 50 comments and you've set a limit of 250, the code will not run 250 times. It will stop as soon as it sees that the next_page_token is empty.

1. How the "Emergency Exit" works
The API is actually quite smart. When you make a request for comments, YouTube looks at its database. If there are no more comments to show, it simply doesn't return a nextPageToken.

In your code, this line is your "Emergency Exit":

Python
if not next_page_token:
    break
Even if you used for _ in range(250), the loop will hit that break statement on the very first iteration (since 50 comments fit in one 100-result page). It won't keep trying to talk to the API 249 more times.

2. The "Limit" Confusion: Requests vs. Comments
There is a slight difference in how limit is applied based on whether you use while True or for _ in range(limit):

maxResults is set to 100. This means 1 API call = up to 100 comments.

If you use for _ in range(250), you are actually limiting yourself to 250 API calls.

250 calls × 100 comments = 25,000 total comments.

If your goal was only to get 250 comments total, the loop should only run 3 times (100 + 100 + 50).

3. Addressing the Duplicate "Ghost" in your except block
You mentioned earlier that you were worried about duplicates. Look closely at your except HttpError block. This is a common place where "dirty data" enters a Delta Table:
```
Python
except HttpError as e:
    # ...
    comments.append({
        "level": "comment",
        "video_id": video_id,
        "comment_id": None, # <--- THIS IS THE PROBLEM
        "added_at": dt.datetime.now()
    })
```
If you run this script twice on the same "Made for Kids" video:

Both times it will hit the except block.

Both times it will append a row with comment_id: None.

Because the comment_id is None, your upsert_func (the Delta Merge) won't have a Unique Key to match on.

Delta Lake will see them as two different "empty" records and you'll end up with duplicate empty rows.

Recommended Fix: Hybrid Loop
To make your pipeline cost-efficient and avoid duplicates, I recommend using a counter that tracks the number of comments, not the number of pages:

Python
comment_count = 0
while comment_count < limit:
    response = request.execute()
    
    for item in response.get("items", []):
        # ... your extraction logic ...
        comment_count += 1
        if comment_count >= limit:
            break

    next_page_token = response.get("nextPageToken")
    if not next_page_token:
        break
    
    # Prepare the next request with the token
    params["pageToken"] = next_page_token
    request = youtube.commentThreads().list(**params)
Why this is better for your Delta Table:
Strict Limits: You get exactly the number of comments you want (e.g., 250), saving on AWS storage and compute costs.

No Useless Calls: The if not next_page_token still protects you if the video has fewer comments than your limit.

Clean Upserts: If you use comment_id as your Merge Key in your Delta Table, any comment that hasn't changed text or likes won't trigger a new write, keeping your "millions of rows" problem under control.

Would you like me to help you refine the upsert_func specifically to handle those None comment IDs so they don't duplicate in your Delta table? 

* so the reason whhy there are duplicates is not because delta tables failed to not insert a duplicate record/comment of the same key which in this case is comment_id, but that your scraper before records were even written to your delta tables was already duplicating these records, and mind you delta table does not actually deduplicate duplicate records that have not yet been written to it. So even though
[comment, 5QIQ5QHqDbw, Ugxg_icY1-vLqVV2gJV4AaABAg, UC2negEr32z8nhZ5cPxCxJMg, UCNqFDjYTexJDET3rPDrmJKg, null, Your. Idol, Your. Idol, 2025-12-24 18:14:39.000, 2025-12-24 18:14:39.000, 0, @OLAOLUWAKIITANALIMABIOLA, http://www.youtube.com/@OLAOLUWAKIITANALIMABIOLA, 2025-12-25 02:18:53.336] and [comment, 5QIQ5QHqDbw, Ugxg_icY1-vLqVV2gJV4AaABAg, UC2negEr32z8nhZ5cPxCxJMg, UCNqFDjYTexJDET3rPDrmJKg, null, Your. Idol, Your. Idol, 2025-12-24 18:14:39.000, 2025-12-24 18:14:39.000, 0, @OLAOLUWAKIITANALIMABIOLA, http://www.youtube.com/@OLAOLUWAKIITANALIMABIOLA, 2025-12-25 02:18:53.720]
are duplicate records with different timestamps delta table still writes these as essentially new rows as the comment_id key does not yet exist in the existing delta table

* there are still duplicates that have not been deleted in manual delete transaction I did
level | video id | comment id | author channel id | channel id where comment was made | parent comment id | text original | text display | published at | updated at | like count | author display name | author channel uri | added at
comment	Ug_pv5-r1js	null	null	null	null	null	null	null	null	null	null	null	2025-12-24 15:36:08.911
comment	Ug_pv5-r1js	null	null	null	null	null	null	null	null	null	null	null	2025-12-25 02:15:10.721
comment	Ug_pv5-r1js	null	null	null	null	null	null	null	null	null	null	null	2025-12-24 15:16:10.152

* transforming columns in stg_youtube_posts table
in addition I have columns in my stg_youtube_videos table: VIDEO_ID VIDEO_DURATION VIDEOS_CHANNEL_ID CHANNEL_NAME VIDEO_TITLE VIDEO_DESCRIPTION VIDEO_TAGS COMMENT_COUNT FAVORITE_COUNT LIKE_COUNT VIEW_COUNT MADE_FOR_KIDS VIDEO_CREATED_AT ADDED_AT

how might I approach transforming this staging table in dbt into int_youtube_videos where I can do meaningful analysis for it, in my previosu table stg_reddit_posts I transformed it and added new columns in a manner that could be useful for my analysis:

```
-- reformat the dates of the stg_reddit_posts_comments
-- table determine sentiment of comment of user

WITH post_activity_w_prob AS (
    SELECT
        *,
        CAST(TO_CHAR(DATE(post_created_at), 'YYYYMMDD') AS INT) AS date_id,
        SNOWFLAKE.CORTEX.SENTIMENT(post_body) AS probability
    FROM {{ ref('stg_reddit_posts') }}
)

SELECT
    *,
    CASE
        WHEN probability < 0 THEN 'NEG'
        WHEN probability > 0 THEN 'POS'
        ELSE 'NEU'
    END AS sentiment
FROM post_activity_w_prob
```

how might I use the embedded out of the box NLP functions that snowflake provides, since this table after all uses mainly text for its columns



for context I have:

* video duration which could be useful for determining the amount of length of videos people gravitate to.

* video description full of text about the video but not exactly the content, or it could be none at all since some videos don't have descriptions, I wanted to extract somethign like a transcript of the video to determine its "post_body" akin to the stg_reddit_posts table but only have this unfortunately

* I have video tags which is an array that could be useful in determining the keywords about the video

* I have the quantifiable values like comment_count, view_count, like_count, and favorite_count,

* made_for_kids which is a boolean to whether a video is made for kids or just the ordinary aged individual which could determine dmeographics

* video_created_at which is a date that tells when the video was uploaded.

Now how might I use NLP or other useful snowflake functions on this table for transformation?

Since you are already comfortable with SNOWFLAKE.CORTEX.SENTIMENT, you can significantly expand your int_youtube_videos model using Snowflake’s larger suite of LLM-based functions. Because YouTube descriptions are often cluttered with links and "calls to action," applying these functions strategically is key.

Here is how you can approach the transformation for meaningful analysis:

1. NLP Transformations (Snowflake Cortex)
Since you don't have a transcript, your best proxies for content analysis are the Title and Description.

SNOWFLAKE.CORTEX.SUMMARIZE: Video descriptions can be long and messy. Use this to create a "clean" one-sentence summary of what the video is about.

SNOWFLAKE.CORTEX.CLASSIFY_TEXT: Instead of manually guessing categories, you can feed the title and tags into this function to categorize videos into buckets (e.g., "Educational," "Entertainment," "Gaming").

SNOWFLAKE.CORTEX.SENTIMENT: Apply this to the VIDEO_TITLE. A "clickbait" title might have a very different sentiment than the actual content.

2. Handling Complex Data Types
ISO 8601 Duration to Seconds: YouTube VIDEO_DURATION usually comes in a format like PT1M30S (1 minute, 30 seconds). You need to convert this to a numeric value to calculate averages.

Tag Analysis (FLATTEN): VIDEO_TAGS is an array. To see which keywords drive the most views, you'll want to "explode" these tags so you can run aggregations on them.

3. Proposed int_youtube_videos.sql
Here is a dbt model that combines standard SQL feature engineering with Snowflake's NLP functions:

SQL
WITH base_videos AS (
    SELECT * FROM {{ ref('stg_youtube_videos') }}
),

transformed AS (
    SELECT
        video_id,
        video_title,
        -- Handle null descriptions to prevent Cortex errors
        COALESCE(video_description, 'No description provided') AS clean_description,
        
        -- 1. ISO Duration Parsing (Basic Regex for PT#M#S format)
        -- Note: For complex durations (hours), a UDF or more robust regex is better
        REGEXP_SUBSTR(video_duration, '(\\d+)M', 1, 1, 'e')::INT * 60 +
        REGEXP_SUBSTR(video_duration, '(\\d+)S', 1, 1, 'e')::INT AS duration_seconds,

        -- 2. Engagement Metrics (Avoid division by zero)
        view_count,
        like_count,
        comment_count,
        (like_count / NULLIF(view_count, 0)) * 100 AS like_view_ratio,
        
        -- 3. Date IDs for partitioning/analysis
        CAST(TO_CHAR(DATE(video_created_at), 'YYYYMMDD') AS INT) AS created_date_id,
        
        -- 4. Demographic Flag
        CASE WHEN made_for_kids = TRUE THEN 'Kids' ELSE 'General' END AS audience_type,
        
        -- 5. Snowflake Cortex NLP
        SNOWFLAKE.CORTEX.SENTIMENT(video_title) AS title_sentiment_score,
        
        -- Only summarize if description is long enough to be meaningful (> 50 chars)
        CASE 
            WHEN LENGTH(video_description) > 50 
            THEN SNOWFLAKE.CORTEX.SUMMARIZE(video_description) 
            ELSE video_description 
        END AS video_summary

    FROM base_videos
)

SELECT 
    *,
    -- Categorize Sentiment
    CASE 
        WHEN title_sentiment_score < -0.5 THEN 'Highly Negative'
        WHEN title_sentiment_score < 0 THEN 'Negative'
        WHEN title_sentiment_score = 0 THEN 'Neutral'
        WHEN title_sentiment_score < 0.5 THEN 'Positive'
        ELSE 'Highly Positive'
    END AS title_sentiment_label
FROM transformed
4. Advanced Keyword Analysis (The "Tag Cloud" Approach)
If you want to do meaningful analysis on VIDEO_TAGS, I recommend creating a separate intermediate model or a CTE that flattens the array. This allows you to answer: "Which tags are associated with the highest engagement?"

SQL
-- int_youtube_tag_performance.sql
WITH flattened_tags AS (
    SELECT
        video_id,
        view_count,
        like_count,
        TRIM(t.value::STRING) AS tag
    FROM {{ ref('stg_youtube_videos') }},
    LATERAL FLATTEN(input => video_tags) t
)

SELECT
    tag,
    COUNT(video_id) AS video_count,
    AVG(view_count) AS avg_views,
    AVG(like_count) AS avg_likes
FROM flattened_tags
GROUP BY 1
HAVING video_count > 1
ORDER BY avg_views DESC
Why this approach works:
Duration Analysis: By converting PT1M30S to 90 seconds, you can finally create buckets like "Shorts" (<60s), "Medium" (1-5m), and "Long-form" (>5m).

Summary vs. Description: SNOWFLAKE.CORTEX.SUMMARIZE removes the "follow me on Instagram" junk and extracts the core topic.

Auditability: You keep the raw counts but add like_view_ratio, which is a much better metric for "video quality" than raw view counts.

Would you like me to show you how to write a custom Snowflake Macro in dbt to handle that ISO duration conversion for all your video sources?

# IBM Interview Prep
* need to know how to build macros

* <s>need to know how incremental models work: </s>
- https://www.youtube.com/watch?v=-9RzZRkHay4&t=2s
- https://www.youtube.com/watch?v=QDcUpHj_mWw&t=543s&pp=0gcJCQMKAYcqIYzv
- https://www.youtube.com/watch?v=bjemdsZibdM&t=143s
- https://www.youtube.com/watch?v=77qbJw8QzSE&t=67s
- https://www.youtube.com/watch?v=MgSO6458c_4

* need to know how to use dbt cloud and deploy to dbt cloud: 
- https://www.youtube.com/watch?v=nHsWKHkc8No&t=272s

* need to know how to 

# improvements:
* one problem I really do see with this architecture is the collection/extraction of reddit data and youtube data creates a bottle neck from the extraction process itself in that data collected first before it is ever written as a delta table in s3. The main problem with this is that if collection fails then thousands of potentially collected data prior to failing may be lost and irrecoverable, wasting time or even worse compute credits in the process, medyo mataas ang latency so maybe here kafka could be useful

