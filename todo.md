# Setting up azure workspace
* create an azure account at 
* setup azure databricks service (data transformation)
* setup azure storage account (data lake to store raw and transformed data)
* create azure synapse analytics service (DWH)
* configuring azure databricks to communicate with azure data lake storage to read data

# setting up reddit api data extractor 
* create the records for each post, comment, and reply from each comment and reply in a post
* dump to kafka producer so that it can be later consumed by a kafka consumer 