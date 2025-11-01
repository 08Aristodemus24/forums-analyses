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

# setting up reddit_posts staging model
* I will have to also include timestamp to when comment or post was made
so that incremental model can 