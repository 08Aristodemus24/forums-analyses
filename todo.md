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
* setup search of videos of a certain topic
* use the searched video ids to get statistics, snippet, etc.
* in each video id setup request for getting the comment threads from each video

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

