# Setting up azure workspace
* create an azure account at 
* setup azure databricks service (data transformation)
* setup azure storage account (data lake to store raw and transformed data)
* create azure synapse analytics service (DWH)
* configuring azure databricks to communicate with azure data lake storage to read data

# setting up reddit api data extractor 
* create the records for each post, comment, and reply from each comment and reply in a post
* dump to aws s3 as data lake storage for later ingestion by dbt to data warehouse


# setting up infrastructure for IAM Policy, S3 Bucket, Snowflake External Stage
- if snowflake trial epires create account again, and setup
- credentials again in profiles.yaml of dbt and in .env since you run it also in airflow

# setting up reddit_posts staging model
* I will have to also include timestamp to when comment or post was made so that incremental model can include a potentially edited post if a post has been edited and just so happened to be scraped again 

# IBM Interview Prep
* need to know how to build macros

* need to know how incremental models work: 
- https://www.youtube.com/watch?v=-9RzZRkHay4&t=2s
- https://www.youtube.com/watch?v=QDcUpHj_mWw&t=543s&pp=0gcJCQMKAYcqIYzv
- https://www.youtube.com/watch?v=bjemdsZibdM&t=143s
- https://www.youtube.com/watch?v=77qbJw8QzSE&t=67s
- https://www.youtube.com/watch?v=MgSO6458c_4

* need to know how to use dbt cloud and deploy to dbt cloud: 
- https://www.youtube.com/watch?v=nHsWKHkc8No&t=272s

* need to know how to 