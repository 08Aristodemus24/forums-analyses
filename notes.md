# Techonologies:
* DBT - for transformation logic inside the data warehouse itself
* Snowflake/Motherduck - for data warehousing. I'll use motherduck for testing sql code since snowflake only has a trial of 30 days
* Praw - for extracting reddit data. No need for kakfa here now since data scraping will only happen on a daily basis and will not likely imply a high throughput process like a per second need to scrape data because of the volume of data being posted per second kind of like meta's messenger or any kind of application that receives transactions on a per second basis
* AWS S3/azure data lake - for storing the raw scraped data as parquet in a single staging layer, as idea will be to load this raw parquets as data into the data warehouse and once this raw data is loaded as a table in a data warehouse then we can then do our dbt transformations sequentially
* Apache Airflow - to orchestrate the transformations by dbt sequentially
* Terraform - to setup data lake storage and possibly the data warehouse chosen

# Insights:
* Ok so now I understand spark and dbt. Akala ko dati talaga that they were just tools meant for the smae task of data transformation and then its loading to a datawarehouse. It was partly true and I understnad now that why spark is used in the transformation step in ETL specifically is because it can leverage its distributed computation capabilities for this step until it is loaded to a cloud data warehouse, and then as for DBT this is a transformation tool yes, but how it works is mainly through an ELT paradigm where data instead of being transformed after extraction is loaded directly into a data warehouse and the data warehouses distributed computing capabilities is what is exactly leveraged by DBT since dbt basically takes the SQL jinja scripts you made and runs this SQL specific to the cloud data warehouses dialect of SQL in a sequential manner liek how a transformation step would occur in an ETL paradigm

Spark: Leverages its own dedicated, elastic cluster (its own virtual machine/CPU/memory) to perform transformations before the data touches the warehouse. This is essential when the data is too messy, too large, or needs complex Python/Scala logic before storage.

dbt: Leverages the Data Warehouse's compute resources (the cloud vendor's CPU, storage, and networking). The beauty of dbt is that it essentially turns complex data pipelines into simple, well-organized, dependency-managed SQL commands that push the computation down to the highly optimized data warehouse platform.

Your understanding that dbt runs SQL in a sequential, dependency-aware manner (like a transformation step would occur) is exactly right—it handles the orchestration of the T in ELT.

Now that you've mastered this concept, you can easily speak to why a company might choose one over the other in an interview!

* Feature	Apache Spark	dbt (data build tool)
Primary Paradigm	ETL (Extract, Transform, Load)	ELT (Extract, Load, Transform)
Transformation Location	Outside the Data Warehouse (on a dedicated cluster like EMR, Databricks, Synapse, or local Spark cluster).	Inside the Data Warehouse (on Snowflake, BigQuery, Redshift, etc.).
Computing Engine	Spark Engine (JVM-based, distributed memory/CPU on worker nodes).	Data Warehouse Engine (Leverages the DW's MPP, columnar storage, and distributed compute).
Transformation Logic	Written in Python (PySpark), Scala, or SQL using DataFrames.	Written primarily in SQL (templated with Jinja), which is then compiled and executed by the DW.
Best For	Massive, unstructured, or streaming data; complex procedural logic; data cleaning before loading.	Structured, already-loaded data; modular, version-controlled transformations; testing and documentation.

* `pip install <dbt adapter of your choice e.g. dbt-snowflake dbt-bigquery dbt-redshift dbt-synapse>` actually allows us to pick between different data warehouse tools as adapters when we run `dbt init`. When we run dbt init with the adapter of our choice it sets up our project in a way that when we do compile our jinja sql code for the ELT pipeline it compiles this sql code into the dialect of the data warehouse we picked as our adapter so if during dbt init we picked motherduck or maybe synapse when we compile our sql dbt will actually do the transformations in the data warehouse we chose in its own sql dialect.

* the `profiles.yml` file when we install dbt actually contains the necessary information dbt needs to make the transformations in your data warehouse of choice. This is where we place the secret access keys we need in order for dbt to communicate with the data warehouse itself in order to make the necessary transformations
```
dbt_data_analysis:
  outputs:
    dev:
      type: duckdb
      path: dev.duckdb
      threads: 1

    prod:
      type: duckdb
      path: prod.duckdb
      threads: 4

  target: dev
```

```
jaffle_shop:

  target: dev
  outputs:
    dev:
      type: duckdb
      schema: dev_sung
      path: 'md:jaffle_shop'
      threads: 16
      extensions: 
        - httpfs
      settings:
        s3_region: "{{ env_var('S3_REGION', 'us-west-1') }}"
        s3_access_key_id: "{{ env_var('S3_ACCESS_KEY_ID') }}"
        s3_secret_access_key: "{{ env_var('S3_SECRET_ACCESS_KEY') }}"

    dev_public_s3:
      type: duckdb
      schema: dev_sung
      path: 'md:jaffle_shop'
      threads: 16
      extensions: 
        - httpfs
      settings:
        s3_region: "{{ env_var('S3_REGION', 'us-east-1') }}" # default region to make hello_public_s3.sql work correctly!
        s3_access_key_id: "{{ env_var('S3_ACCESS_KEY_ID') }}"
        s3_secret_access_key: "{{ env_var('S3_SECRET_ACCESS_KEY') }}"

    prod:
      type: duckdb
      schema: prod_sung
      path: 'md:jaffle_shop'
      threads: 16
      extensions: 
        - httpfs
      settings:
        s3_region: us-west-1
        s3_access_key_id: "{{ env_var('S3_ACCESS_KEY_ID') }}"
        s3_secret_access_key: "{{ env_var('S3_SECRET_ACCESS_KEY') }}"
```

* Basically when we run dbt run it creates the database we specified in our profiles.yml file in our chosen datawarehouse. Above we see we specified a local duckdb database and set target to dev, and had outputs either be dev (development) or prod (production) (so that we can also use dev for development and testing and production only for production grade entities/tables). We see that dev has its keys like `path` and `type` set to `<name of our in process duckdb database>.duckdb` and `duckdb` respectively so when we run dbt run this naturally creates `dev.duckdb` in our project directory. 

Ito na yung in process OLAP database or data warehouse natin which contain the tables that have been created from our queries.

And essentially yung filename (minus the extension of course) ng models natin like in this `case my_first_dbt_model.sql` and `my_second_dbt_model.sql` are what is basically created as tables when we run `dbt run`

* To read a local `.csv` and have it be queried in the target database we actually need to place this file in the seeds folder in our dbt project directory and then run `dbt seed` and if you see below once we run the latter command and check our data warehouse instance we will see the file created as a table where we can now do certain transformations to by creating more `.sql` files in our models folder  
```
(tech-interview) C:\Users\LARRY\Documents\Scripts\data-engineering-path\dbt-data-analysis\dbt_data_analysis>dbt seed
06:34:54  Running with dbt=1.10.13
06:34:55  Registered adapter: duckdb=1.9.6
06:34:56  Found 2 models, 4 data tests, 1 seed, 444 macros
06:34:56
06:34:56  Concurrency: 1 threads (target='dev')
06:34:56
06:34:57  1 of 1 START seed file main.flights ............................................ [RUN]
06:35:08  1 of 1 OK loaded seed file main.flights ........................................ [INSERT 100000 in 10.99s]
06:35:08
06:35:08  Finished running 1 seed in 0 hours 0 minutes and 11.98 seconds (11.98s).
06:35:08
06:35:08  Completed successfully
06:35:08
06:35:08  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 NO-OP=0 TOTAL=1

(tech-interview) C:\Users\LARRY\Documents\Scripts\data-engineering-path\dbt-data-analysis\dbt_data_analysis>python
Python 3.11.8 | packaged by Anaconda, Inc. | (main, Feb 26 2024, 21:34:05) [MSC v.1916 64 bit (AMD64)] on win32
Type "help", "copyright", "credits" or "license" for more information.
>>> import duckdb
>>>
>>> conn = duckdb.connect("dev.duckdb")
>>> conn.sql("SHOW TABLES")
┌─────────────────────┐
│        name         │
│       varchar       │
├─────────────────────┤
│ flights             │
│ my_first_dbt_model  │
│ my_second_dbt_model │
└─────────────────────┘
```

* oh ok so `dbt build` by default just uses the specified target in the profiles.yml file and `dbt build --target <name of output we want to have as target e.g. prod or dev or any name you specified as an output in the profiles.yml file>` basically overrides the target specified in the profiles.yml file in favor of the target you provided

* so di pala muna pwede mag run nito:
```
dbt_data_analysis:
  outputs:
    dev_cloud:
      type: duckdb
      path: md:dbt_data_analysis_db
      threads: 4

    dev_local:
      type: duckdb
      path: dev.duckdb
      threads: 1

    prod_local:
      type: duckdb
      path: prod.duckdb
      threads: 4

  target: dev_local
```

because it will raise an error when we run dbt seed --target dev_cloud or dbt build --target dev_cloud such as `:Failed to attach 'dbt_data_analysis_db': no database/share named 'dbt_data_analysis_db' found"` so we need to make sure we create this database in our chosen data warehouse first. But can we do it or set it up programmatically is the question. We could set it up via terraform

* to set token use `set motherduck_token=<the secret we generated in motherduck (ote this must be unquoted)>` in windows (this would be different for linux). To see if temporary secret has been set run `echo %motherduck_token%`

# Articles, Videos, Papers:

