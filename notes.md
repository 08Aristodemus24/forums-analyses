# Techonologies:
* DBT - for transformation logic inside the data warehouse itself
* Snowflake/Motherduck - for data warehousing. I'll use motherduck for testing sql code since snowflake only has a trial of 30 days
* Praw - for extracting reddit data. No need for kakfa here now since data scraping will only happen on a daily basis and will not likely imply a high throughput process like a per second need to scrape data because of the volume of data being posted per second kind of like meta's messenger or any kind of application that receives transactions on a per second basis
* AWS S3/azure data lake - for storing the raw scraped data as parquet in a single staging layer, as idea will be to load this raw parquets as data into the data warehouse and once this raw data is loaded as a table in a data warehouse then we can then do our dbt transformations sequentially
* Apache Airflow - to orchestrate the transformations by dbt sequentially
* Terraform - to setup data lake storage and possibly the data warehouse chosen

# Insights:

## DBT
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

if your using s3 as the data source then it would be better to run instead
```
SET motherduck_token=<md token> & SET S3_ACCESS_KEY_ID=<key> & SET S3_SECRET_ACCESS_KEY=<key> & SET S3_REGION=<key>
```

* no need for explicit create table if using dbt because of martelization, no more repeating yourself or manual creating of files with DML, or DDL statements
* merge into in sql compares source table and target table, with materialize = 'incremental' dbt automatically compares the two older and newer tables and merges all old records to old records and adds new records to the new table

incremental 
default value of incremental can depend on platform
if snowflake default incremental strategy is merge into
synapse may be different
big query may be different

https://docs.getdbt.com/docs/build/incremental-models-overview

incremental only detects new records but doesn't count columns of old rows that change. This requires an UPDATE instaed of INSERT

mas costly ang UPDATE kasi it looks at each record row by row
pag 

* inside the warehouse dbt still follows the ETL processes
* important part in dbt cloud over dbt core is that  abstracted na ang profiles.yaml in dbt cloud

* learn materialization concepts like view, slowly changing dimensions, macros, 

durable key for slowy changing dimensions type 4,

* kimball
- flat/one big table
- 

inmon
- snowflake (umaabot na ng 3rd normal form kasi your break down dimension tables into even smaller)
- wala na talaga duplicates kahit ang keys, that means even walang fact tables na potentially may duplicate keys
basically inmon and kimball are two schools of thought in modelling data in a data warehouse

* how dbt runs these models sequentially is because fo the ref() and source() functions

* Ah ok ok, so kaya pala kanina nagfafail yung dbt model na to during the test of checking if the id column is not null: 
```
{{ config(materialized='table') }}

WITH source_data AS (
    SELECT 1 AS id
    UNION ALL
    SELECT NULL AS id
)

SELECT *
FROM source_data
WHERE id IS NOT NULL 
```

kasi even if nauncomment ko na yung `WHERE id IS NOT NULL` (where initially naka uncomment siya) and nirurun yung dbt test nag fafail lagi with the `11:45:36  1 of 4 FAIL 1 not_null_my_first_dbt_model_id ................................... [FAIL 1 in 3.10s]`, pero nung nirun ko muna yung `dbt build` that's when nung nag `dbt test` that it ran successfully finally. So basically if a model changes, you need to always run `dbt build` first then `dbt run` or `dbt test`

Naintindihan ko na ang problema mo! Ang inilarawan mong pag-uugali ay perpekto at inaasahan sa dBT.

Ang pagkakaintindi mo ay tama: kailangan mo munang i-run ang model (dbt build or dbt run) bago mo i-test (dbt test) ito.

🛑 Bakit Nag-Fail ang dbt test Una (At Bakit Ito Inaasahan)
Ang dbt test ay hindi nagpapatakbo ng model. Ito ay nagpapatakbo lang ng SQL queries laban sa existing tables o views sa iyong data warehouse.

Unang Pag-Test (Failure): Nang una mong ginawa ang dbt test, ang dBT ay tumingin sa iyong data warehouse para sa table na tinatawag na `my_first_dbt_model.sql`

Kung ang table ay hindi pa na-create (dahil hindi mo pa na-run ang dbt run o dbt build), o

Kung ang lumang bersyon ng table na may NULL values ay nandoon pa,

Resulta: Ang NOT NULL test ay nag-fail dahil ang data na nakita niya sa table ay may NULL value pa.

Paggamit ng dbt build (Correction):

Ang dbt build (o dbt run) ang gumagawa ng actual table sa iyong warehouse.

Sa pagkakataong ito, pinatakbo nito ang iyong SQL:

```
SQL
SELECT *
FROM source_data
WHERE id IS NOT NULL -- This filters out the NULL row
```

Resulta: Ang bagong table ay nilikha na WALANG NULL values sa id column.
Pangalawang Pag-Test (Success): Nang pinatakbo mo ulit ang dbt test, ang dBT ay tumingin na sa bago at tamang table.

Nakita nito na ang id column ay walang NULL values.

Resulta: Ang test ay nag-succeed.

🔑 Tandaan ang Siklo ng dBT
Para sa bawat development cycle, tandaan ang tamang order ng operations:

Develop SQL→dbt build (o run)→dbt test
Ang dbt build ang nagtatayo ng data, at ang dbt test ang nagba-validate sa naitayong data.

Nakuha mo na ang tamang workflow! Is there anything else about dbt or data warehousing concepts you'd like to clarify?

* This is a great question, and it points directly to the *division of labor* and *best practices* in a modern data team, especially one using ELT tools like dbt and Snowflake!

Your confusion is understandable because the line between the roles of a *Data Engineer* (or Analytics Engineer) and a *Data Analyst* can sometimes feel blurry, but the layered approach (Staging $\rightarrow$ Intermediate $\rightarrow$ Marts) is designed to clear this up.

The short answer is *yes, the Marts layer is specifically designed to contain the final, business-ready tables that directly answer business questions and are used for visualizations.*

**Understanding the Marts Layer**

The Marts (or *Data Marts*) layer in a dbt project is the *final destination* for your transformed data. It represents the "plating" stage, making the data simple, clean, and immediately digestible for the end consumer.

| Layer | Purpose (The Goal) | Key Role (Who Does the Work) |
| :--- | :--- | :--- |
| *Intermediate* | Applying complex, reusable logic (joins, cleaning, re-graining) to prepare the data. It's not for end-users. | *Data/Analytics Engineer* |
| *Marts* | Presenting the *final, business-ready tables* that are structured to directly answer specific business questions and feed dashboards. | *Data/Analytics Engineer* |
| *Visualization/BI* | Creating charts, filtering, and performing ad-hoc analysis on the mart tables to *tell the story*. | *Data Analyst/Business User* |

**The "Business-Ready" Difference**

When we say a mart table is "business-ready," it means you have already performed the majority of the data preparation in the data warehouse (Snowflake, via dbt models).

* *Aggregation and Grouping:* Marts often contain tables that are *pre-aggregated* to a common, useful grain. For example, a fct_daily_sales table might already have sales figures grouped by Date, Customer, and Product. This means the expensive GROUP BY and complex joins are done *once* in the dbt pipeline, not repeatedly by the visualization tool.
* *Simple Joins (Star Schema):* Marts are frequently modeled using Dimensional Modeling (like *Star Schemas*), where a central *Fact* table (e.g., Sales Orders) is surrounded by *Dimension* tables (e.g., Customer, Product). The relationships are straightforward, so Power BI only needs to perform simple joins to link them. 
* *Clear Business Context:* Column names are intuitive (customer_lifetime_value, order_status_description), making the data easy for a business user to understand without needing to know the complex source system logic.

**Where Your Confusion Comes From (and the Role Separation)**

Your current practice of doing aggregations and joins in Power BI is common, especially in smaller or less mature data setups. However, this is where the modern *Analytics Engineer* (your new role) steps in to create a better workflow.

**The Old/Analyst-Driven Way (The Problem)**

* You load large, less-transformed tables into Power BI.
* You perform complex JOINs, GROUP BYs, and custom calculations *within Power BI* (using DAX or Power Query).
* *Consequence:* Power BI becomes slow, you're duplicating complex logic across multiple dashboards, and analysts have to spend more time cleaning and prepping data than analyzing it. This also pushes the compute load from Snowflake (the powerful warehouse) to Power BI (the reporting tool).

**The ELT/dbt Way (The Solution)**

1. *Extract & Load (EL):* Raw data lands in Snowflake.
2. *Transform (T - Engineer's Job):* You (the Data/Analytics Engineer using *dbt*) write SQL models to:
* Clean the data (Staging $\rightarrow$ Intermediate).
* Perform the complex joins, aggregations, and business logic (Intermediate $\rightarrow$ Marts).
* The *Mart* model is the *last step* of this process.
3. *Visualize (Analyst's Job):* The Data Analyst loads the final, clean, pre-calculated *Mart* table into Power BI.
* The Analyst now uses Power BI for its *core purpose*: creating visuals, filtering, and doing *ad-hoc analysis* — not for heavy data transformation.
* The expensive *Group By* and *Join* operations are already done in Snowflake, making the dashboards faster and more reliable.

*Conclusion: You should be doing those aggregations, group bys, and joins in your dbt Mart models so that the data is clean and ready for immediate visualization by the analysts in Power BI.*



* Here is a common, simplified path for how a Staging model becomes a dim_customers (Dimension Customer) table in your Marts layer using dbt and SQL.

**Staging $\rightarrow$ Marts: The dim_customers Example**

This transformation process cleans, enhances, and standardizes your raw customer data, making it useful for analysis.

**1. Staging Layer (stg_customers)**

The Staging layer is about *cleaning* and *standardizing* the raw data from your source systems (like your CRM, website, etc.).

*Goal:* Select the necessary columns, rename confusing source names to standard names, and apply simple data type casts.
```
| Source Column (CRM) | Staging Column | Transformation Applied |
| :--- | :--- | :--- |
| id | customer_key | Rename for clarity, often prefixed with _key. |
| first_name + last_name | full_name | Concatenate for analysis-ready field. |
| creation_ts | customer_since_date | Cast to a simple DATE type. |
| status | is_active | Use a CASE statement to standardize (e.g., CASE WHEN status = 'active' THEN TRUE ELSE FALSE END). |
```

models/staging/stg_crm__customers.sql
```

SELECT
    id AS customer_key,
    first_name || ' ' || last_name AS full_name,
    CAST(creation_ts AS DATE) AS customer_since_date,
    CASE
        WHEN status = 'active' THEN TRUE
        ELSE FALSE
    END AS is_active,
    ...
FROM
    {{ source('crm', 'customers') }}
```

**2. Intermediate Layer (Optional but Recommended)**

For dim_customers, the Intermediate layer is often used to *resolve duplicates* or *enrich* the data by joining it with other sources before creating the final dimension.

*Goal:* Create a single, canonical view of a customer by joining information from multiple sources (e.g., CRM + Web Tracking Data) and calculating key initial metrics.

models/intermediate/int_customers_with_metrics.sql
```
WITH crm_data AS (
    SELECT * FROM {{ ref('stg_crm__customers') }}
),

order_stats AS (
    -- Calculate LTV components using aggregations in the Intermediate layer
    SELECT
        customer_key,
        COUNT(order_id) AS total_orders,
        SUM(order_total) AS total_spent
    FROM
        {{ ref('stg_ecommerce__orders') }}
    GROUP BY 1
)

SELECT
    c.*,
    o.total_orders,
    o.total_spent
FROM
    crm_data c
LEFT JOIN
    order_stats o ON c.customer_key = o.customer_key
```

**3. Marts Layer (dim_customers)**

This is the final, ready-to-use Dimension table in your mart. It's often built directly from the intermediate layer.

*Goal:* Select the final set of columns in a clear, consistent order, and ensure the table adheres to the dimensional model (Star Schema). The columns here are the attributes analysts will use to slice and dice their data (e.g., Customer Region, Customer Tier).

models/marts/core/dim_customers.sql
```
SELECT
    -- Primary Key and Customer Info
    customer_key,
    full_name,
    customer_since_date,

    -- Attributes (Slice and Dice)
    is_active,
    customer_region,
    customer_tier,

    -- Pre-calculated Metrics (Enhancements)
    total_orders,
    total_spent
    -- total_spent is now a static attribute of the customer at the time the model ran.
FROM
    {{ ref('int_customers_with_metrics') }}
```


**Key Takeaways for Your Role**

1. *Modeling Choice:* You are using *Dimensional Modeling* here (creating Fact and Dimension tables). This is the standard for building user-friendly marts in the modern data warehouse.
2. *Location of Logic:* Notice that all the complex logic (CONCAT, CASE, GROUP BY, SUM) happens in the *Staging* and *Intermediate* models, running on the powerful *Snowflake* warehouse.
3. *Visualization Tool's Job:* The Analyst connects Power BI to the final dim_customers table. Power BI no longer needs to run complex logic; it just uses total_spent as a pre-calculated measure and uses customer_region as a simple filter. This makes the entire analytics process faster, cheaper, and more reliable.

Would you like to see the companion example of how a *Fact*table (e.g., fct_orders) is created in the Marts layer?



* You've successfully built the Dimension (dim_customers) table, which answers the "who" and "what." Now, we'll build the Fact table (fct_orders), which answers the "when" and "how much," completing the core of your Star Schema.

The key difference in building a Fact table is that instead of focusing on descriptive attributes, we focus on keys and metrics.

Building a Fact Table: fct_orders Example
We will base the fct_orders model on your existing stg_ecommerce__orders (the cleaned list of orders) and integrate the keys from your newly built dimension table.

**1. Staging Layer (stg_orders)**
This layer is already defined in your example as the source for the intermediate step.

Goal: Clean and standardize the transaction source data.

SQL

models/staging/stg_ecommerce__orders.sql
```
SELECT
    order_id,
    customer_id AS customer_key, -- Standardized key name
    order_date,
    order_total,
    ...
FROM
    {{ source('ecommerce', 'orders') }}
```

**2. Intermediate Layer (Optional but Recommended)**
For a Fact table, the intermediate step is critical for key resolution. This is where you replace natural keys (like customer_key) with robust Surrogate Keys (if your dimensions use them) and prepare all required metrics.

Goal: Replace business/natural keys with dimension Surrogate Keys and calculate transaction-level metrics.

-- models/intermediate/int_orders_with_keys.sql
```
SELECT
    -- 1. Transactional Keys
    o.order_id,
    o.order_date,
    
    -- 2. Foreign Keys (Joining to bring in the Dimension Key)
    o.customer_key, 
    -- If dim_customers had a surrogate key (SK), you would join and select it here:
    -- dc.customer_sk, 

    -- 3. Metrics (The 'Facts')
    o.order_total,
    o.order_line_count,
    
    -- 4. Audit Fields
    o.updated_at
    
FROM
    {{ ref('stg_ecommerce__orders') }} AS o
LEFT JOIN 
    {{ ref('dim_customers') }} AS dc ON o.customer_key = dc.customer_key

-- Optional: Filter out orders with no corresponding customer if required
-- WHERE dc.customer_key IS NOT NULL
```

**3. Marts Layer (fct_orders) 💰**
This is the final table that strictly adheres to the Star Schema design: only keys and measures.

Goal: Select the final set of keys and metrics in a clear, consistent order.

models/marts/core/fct_orders.sql
```
SELECT
    -- 1. Primary Key of the Fact Table (often just the source ID)
    order_id,

    -- 2. Foreign Keys to Dimension Tables
    customer_key,
    -- date_key, (If you had a dim_date, you would join to get the date_key here)
    -- product_key, (If this were an Order_Items fact, you'd include product_key)

    -- 3. Measures (The metrics analysts will aggregate)
    order_total,
    order_line_count
    
FROM
    {{ ref('int_orders_with_keys') }}
```

Key Takeaways for Fact Table Modeling
Focus on Foreign Keys: The most important columns are the keys (customer_key, date_key, etc.) that link to your dimension tables.

Focus on Measures: Fact tables contain numerical, additive measures (e.g., revenue, quantity, count).

Granularity: Fact tables should be at the lowest possible grain (e.g., one row per order, or one row per item within an order, if it's a detail table).

Implementation Choice: Since transactional data like orders is append-only, the fct_orders model would typically be materialized as an incremental model in dbt, using a WHERE order_date > MAX(order_date) IN target logic to ensure fast, daily loading.

* Key takeaways
- heavy transformations occurs in intermediate layer
- instead of user doing joins, complex transformations, aggregations, sorts, in "Power BI" or "Tableau" all of the compute heavy workload is carried out by the DWH (snowflake) itself
- dbt's whole point is to take transformation outside the warehouse involving cleaning, aggregation, reformatting, and modelling, perhaps using spark or other distributed computing frameworks, inside the warehouse itself
- so fact tables and dimension tables are always in the marts layer in dbt
- ephemeral is basically a CTE in SQL, why we use this is that we don't want to materialize a model into a table everytime in a data warehouse as this would be storage inefficient at best, consuming easily our storage space. Moreover`

raw layer may be table
stg layer may be ephemeral/view
int layer may be ephemeral/view
marts layer may be incremental

```
raw ---> stg -|
              |-> int -
raw ---> stg -|       |
                      |-> fact
raw ---> stg -|       |
              |-> int - 
raw ---> stg -|
              |-> int ---> dim
raw ---> stg -|
```

- akala mo dati using views or ephemeral materialization in your tables will lead to you always overwriting the data everytime new or updated records exist, but this is true only in the case of tables and incremental materialization which yoou only use anyway once in the last layers of the DBT DAG mainly the marts layer where tables are directly used by BI users.Why views or ephemeral materializtoins are okay is that when new or updated records the model and the query inside it is just recalculated every time the dag runs with said new and updated records but without hte expensive tneed to overwrite an existing table since there isn't any existing table since this is just a view or ephemeral

* schema evolution or adding new columns in existing delta lake table will be inevitable, that's why you jave to set mergeSchema in spark to true, or set merge_schema to true in delta-rs when using pyarrow tables

* dbt build both builds the tables in the DWH and runs and builds the necessary tests, seeds, and snapshots in our project while dbt run is only confined to building tables in the DWH and dbt test is confined to only running the tests of our models without building or materializing our models in the DWH. 

* on the other hand we can actually select which specific models to run/build/test by using the --select flag and specifying our model and even specify also if models upstream or downstream to it should also be run, built, or tested using `dbt <mode e.g. run, build, or test> --select +<model name>` (to run the model and all models that depend on it upstream) and `dbt <mode e.g. run, build, or test> --select +<model name>+` (to run the model and all models that precede it downstream)


* Modularity in DBT is the degree to which a system's components may be separated and recombined, often with the benefit of flexibility and variety in use. This allows us to build data artifacts in logical steps.

For example, we can stage the raw customers and orders data to shape it into what we want it to look like. Then we can build a model that references both of these to build the final dim_customers model.

* benefit of using subdirectories in your models directory is that it allows you to configure materializations at the folder level for a collection of model

* two functions of a staging model in dbt:
- Perform light transformations on your data set
- Connect to upstream sources using the source macro

* two functions of a marts model in dbt
- Apply business logic for stakeholders
- Reference upstream models using the ref macro

* you always need to check if the source system tables have changed then you have to run `dbt build` to build again all models upstream that reference this source system table and to reflect the changes in the staging, intermediate, and marts models 

* 
You have a table in your data platform called `raw.jaffle_shop.orders`.

You are attempting to run this select statement to preview the `'orders'` source:

`select * from {{ source( 'jaffle_shop', 'orders') }}`

This statement is not running. Examine this YAML configuration :
```
sources:
  - name: jaffle_shop
    database: jaffle_shop
    schema: raw
    tables:
      - name: orders
      - name: customers
```
What is the problem with this YAML file?

A. The source name is `Jaffle_shop`, and should replace `'raw'` In the source macro.
`B. The database and the schema field should be swapped. Correct ✓`
C. The schema name and database name should match.
D. The source macro should also include the database name In addition to the schema name.


*  A new model that you are creating needs to reference your `jaffle_orders_information_table`.
Examine this source configuration:
```
sources:
  - name: jaffle_shop
    database: raw
    schema: jaffle_shop_dataset
    tables:
      - name: orders
        identifier: jaffle_orders_information_table
      - name: customers
        identifier: jaffle_customers_information_table
```
How would you reference this information using the source macro?
A. {{ source('laffle_shop', 'laffle_orders_Information_table') }}
B. {{ source('laffle_shop_dataset', 'orders') }}
`C. {{ source('laffle_shop', 'orders') }} Your Answer: Correct`
D. {{ source('laffle_shop_dataset', 'laffle_orders_Information_table') }}

how identifiers in sources work: https://docs.getdbt.com/reference/resource-properties/identifier


* how come this works in snowflake:
```


MERGE INTO SNOWFLAKE_LEARNING_DB.PUBLIC.STG_JAFFLE_SHOP__CUSTOMERS target
USING (
    WITH jaffle_shop_customers AS (
        SELECT
            ID AS customer_id,
            FIRST_NAME AS first_name,
            LAST_NAME AS last_name,
            CURRENT_TIMESTAMP() AS dbt_load_timestamp
        FROM SNOWFLAKE_LEARNING_DB.PUBLIC.RAW_JAFFLE_SHOP_CUSTOMERS
    )

    SELECT *
    FROM jaffle_shop_customers
    WHERE dbt_load_timestamp > (SELECT MAX(dbt_load_timestamp) FROM SNOWFLAKE_LEARNING_DB.PUBLIC.STG_JAFFLE_SHOP__CUSTOMERS)
) source
ON target.customer_id = source.customer_id
WHEN MATCHED AND (
    source.first_name IS DISTINCT FROM target.first_name OR
    source.last_name IS DISTINCT FROM target.last_name OR
    source.dbt_load_timestamp IS DISTINCT FROM target.dbt_load_timestamp
) THEN
    UPDATE SET
        target.first_name = source.first_name,
        target.last_name = source.last_name,
        target.dbt_load_timestamp = source.dbt_load_timestamp
WHEN NOT MATCHED THEN
    INSERT (
        customer_id, 
        first_name, 
        last_name, 
        dbt_load_timestamp
    ) VALUES
    (source.customer_id, source.first_name, source.last_name, source.dbt_load_timestamp)
```

but this doesn't in dbt?

```
{{
    config(
        materialized='incremental',
        unique_key=['customer_id'],
        on_schema_change='sync_all_columns',
        incremental_strategy='merge'
    )
}}

WITH jaffle_shop_customers AS (
    SELECT
        ID AS customer_id,
        FIRST_NAME AS first_name,
        LAST_NAME AS last_name,
        CURRENT_TIMESTAMP() AS dbt_load_timestamp
    FROM {{ source('jaffle_shop', 'raw_jaffle_shop_customers') }}
)

SELECT *
FROM jaffle_shop_customers
{% if is_incremental() %}
WHERE dbt_load_timestamp > (SELECT MAX(dbt_load_timestamp) FROM {{ this }})
{% endif %}
```

* The `append` strategy is simple to implement and has low processing costs. It inserts selected records into the destination table without updating or deleting existing data. This strategy doesn’t align directly with type 1 or type 2 slowly changing dimensions (SCD). It differs from SCD1, which overwrites existing records, and only loosely resembles SCD2. While it adds new rows (like SCD2), it doesn’t manage versioning or track historical changes explicitly.

Importantly, append doesn't check for duplicates or verify whether a record already exists in the destination. If the same record appears multiple times in the source, it will be inserted again, potentially resulting in duplicate rows. This may not be an issue depending on your use case and data quality requirements.

NOTE: this is why if our source system table e.g. raw_reddit_posts, and raw_reddit_posts_comments change and we need to reflect it in our stg_reddit_posts, and stg_raw_reddit_posts_comments by specifying our incremental_strategy argument as `merge` instead of `append`, and add our necessary predicates for it

* By default the incremental strategy in dbt depends on the adapter being used; however, for data warehouses that support it, the most common default is `merge`. For adapters that don't support a native `merge` statement, dbt may default to `append`. However snowflake supports `merge`, this is why when we use incremental materializations and define a unique key/s in the background snowflake does a merge operation:
```
-- back compat for old kwarg name
  
  begin;
    merge into FORUMS_ANALYSES_DB.FORUMS_ANALYSES_BRONZE.stg_reddit_posts_comments as DBT_INTERNAL_DEST
        using FORUMS_ANALYSES_DB.FORUMS_ANALYSES_BRONZE.stg_reddit_posts_comments__dbt_tmp as DBT_INTERNAL_SOURCE
        on (
                    DBT_INTERNAL_SOURCE.post_id_full = DBT_INTERNAL_DEST.post_id_full
                ) and (
                    DBT_INTERNAL_SOURCE.comment_id_full = DBT_INTERNAL_DEST.comment_id_full
                ) and (
                    DBT_INTERNAL_SOURCE.comment_parent_id_full = DBT_INTERNAL_DEST.comment_parent_id_full
                )

    
    when matched then update set
        "POST_ID" = DBT_INTERNAL_SOURCE."POST_ID","POST_ID_FULL" = DBT_INTERNAL_SOURCE."POST_ID_FULL","LEVEL" = DBT_INTERNAL_SOURCE."LEVEL","COMMENT_ID" = DBT_INTERNAL_SOURCE."COMMENT_ID","COMMENT_ID_FULL" = DBT_INTERNAL_SOURCE."COMMENT_ID_FULL","COMMENT_UPVOTES" = DBT_INTERNAL_SOURCE."COMMENT_UPVOTES","COMMENT_DOWNVOTES" = DBT_INTERNAL_SOURCE."COMMENT_DOWNVOTES","COMMENT_CREATED_AT" = DBT_INTERNAL_SOURCE."COMMENT_CREATED_AT","COMMENT_EDITED_AT" = DBT_INTERNAL_SOURCE."COMMENT_EDITED_AT","COMMENT_AUTHOR_USERNAME" = DBT_INTERNAL_SOURCE."COMMENT_AUTHOR_USERNAME","COMMENT_AUTHOR_ID_FULL" = DBT_INTERNAL_SOURCE."COMMENT_AUTHOR_ID_FULL","COMMENT_PARENT_ID_FULL" = DBT_INTERNAL_SOURCE."COMMENT_PARENT_ID_FULL","COMMENT_BODY" = DBT_INTERNAL_SOURCE."COMMENT_BODY","ADDED_AT" = DBT_INTERNAL_SOURCE."ADDED_AT"
    

    when not matched then insert
        ("POST_ID", "POST_ID_FULL", "LEVEL", "COMMENT_ID", "COMMENT_ID_FULL", "COMMENT_UPVOTES", "COMMENT_DOWNVOTES", "COMMENT_CREATED_AT", "COMMENT_EDITED_AT", "COMMENT_AUTHOR_USERNAME", "COMMENT_AUTHOR_ID_FULL", "COMMENT_PARENT_ID_FULL", "COMMENT_BODY", "ADDED_AT")
    values
        ("POST_ID", "POST_ID_FULL", "LEVEL", "COMMENT_ID", "COMMENT_ID_FULL", "COMMENT_UPVOTES", "COMMENT_DOWNVOTES", "COMMENT_CREATED_AT", "COMMENT_EDITED_AT", "COMMENT_AUTHOR_USERNAME", "COMMENT_AUTHOR_ID_FULL", "COMMENT_PARENT_ID_FULL", "COMMENT_BODY", "ADDED_AT")

;
    commit;
``` 

so in essence we want dbt to run the above akin to this:

```
MERGE INTO SNOWFLAKE_LEARNING_DB.PUBLIC.STG_JAFFLE_SHOP__CUSTOMERS target
USING (
    WITH jaffle_shop_customers AS (
        SELECT
            ID AS customer_id,
            FIRST_NAME AS first_name,
            LAST_NAME AS last_name,
            CURRENT_TIMESTAMP() AS dbt_load_timestamp
        FROM SNOWFLAKE_LEARNING_DB.PUBLIC.RAW_JAFFLE_SHOP_CUSTOMERS
    )

    SELECT *
    FROM jaffle_shop_customers
    WHERE dbt_load_timestamp > (SELECT MAX(dbt_load_timestamp) FROM SNOWFLAKE_LEARNING_DB.PUBLIC.STG_JAFFLE_SHOP__CUSTOMERS)
) source
ON target.customer_id = source.customer_id
WHEN MATCHED AND (
    source.first_name IS DISTINCT FROM target.first_name OR
    source.last_name IS DISTINCT FROM target.last_name OR
    source.dbt_load_timestamp IS DISTINCT FROM target.dbt_load_timestamp
) THEN
    UPDATE SET
        target.first_name = source.first_name,
        target.last_name = source.last_name,
        target.dbt_load_timestamp = source.dbt_load_timestamp
WHEN NOT MATCHED THEN
    INSERT (
        customer_id, 
        first_name, 
        last_name, 
        dbt_load_timestamp
    ) VALUES
    (source.customer_id, source.first_name, source.last_name, source.dbt_load_timestamp)
```

where it successfully changes all dbt load timestamps, first names, and last names

* what if we changed `raw.jaffle_shop.orders` to `raw_test.jaffle_shop.orders`. We would have to change all the `.sql` model files we have in our dbt project making our work manual and tedious, however `sources.yml` solves this by defining a single database argument where we specify which database we use and if we wanted to change the database we would just change it in the `source.yml` file or if our schema name changes from `raw.jaffle_shop.orders` to `raw.flower_shop.orders`

* ephemeral models e.g. `SELECT * FROM table` will be materialized in downstream models as: 
```
WITH <ephemeral model name> AS (
  SELECT * FROM table
)
```

* 
how does source freshness work? Say I have a raw_reddit_posts_comments delta table in s3 as my source with columns

post_id

post_name

level

comment_id

comment_name

comment_upvotes

comment_downvotes

comment_created_at

comment_edited_at

comment_author_name

comment_author_fullname

comment_parent_id

comment_body

added_at



How might I use added_at column since it's a timestamp in checking the freshness of this table? How does it work?

In dbt, source freshness is a built-in feature used to monitor whether your data pipeline is successfully ingesting new data from its origin (like your S3 bucket) into Snowflake.

Since your raw_reddit_posts_comments table includes an added_at timestamp, you have the perfect "hook" to measure how "stale" or "fresh" your data is.

1. How the Freshness Check Works
When you run a freshness check, dbt calculates the "age" of your source data by comparing the most recent timestamp in your table to the current time on the Snowflake server.

The logic follows this formula: `T_age = T_current − max(added_at)` where:
`T_current` is the current timestamp provided by the database (e.g., CURRENT_TIMESTAMP()).
`max(added_at)` is the timestamp of the absolute newest record that successfully made it into your Snowflake table.
`T_age` is the duration (in hours or days) since the last successful data load.

2. Configuring it in your sources.yml
To use the added_at column, you must define it as the loaded_at_field in your dbt project. Here is how you would set it up:

YAML
```
version: 2

sources:
  - name: reddit_source
    database: "{{env}}_forums_analyses_db"
    schema: raw
    freshness:
      warn_after: {count: 6, period: hour}
      error_after: {count: 24, period: hour}
    loaded_at_field: added_at  # This tells dbt which column to check
    tables:
      - name: raw_reddit_posts_comments
```
3. The Execution Steps
When you execute the command dbt source freshness, dbt performs the following steps:

Metadata Query: dbt sends a query to Snowflake: SELECT MAX(added_at) FROM {{env}}_forums_analyses_db.raw.raw_reddit_posts_comments;

Comparison: It retrieves that timestamp and subtracts it from the current time.

Status Report:

Pass: If T 
age is less than 6 hours.

Warn: If T 
age is between 6 and 24 hours.

Error: If T 
age exceeds 24 hours.

4. Why this matters for your S3/Iceberg Setup
In your specific case—where you are ingesting Delta files from S3 into Iceberg tables—source freshness is your early warning system:

Ingestion Failure: If your Python scraper (the one failing with SSL errors) stops uploading files to S3, the added_at column in Snowflake will stop advancing.

Metadata Sync Issues: Since you are using a delta_catalog_integration, if Snowflake fails to refresh the metadata of the Iceberg table, the MAX(added_at) will appear old even if the files are technically in S3.

* `dbt source freshness` is what we run to check the source freshness of our data

`dbt build` is a combination of running `dbt run` and `dbt test` respectively. `dbt run` merely builds our models but does not test them, `dbt test` only tests are built models. So to ensure we have tables to test we either run ``dbtbuild` or `dbt run`

Tests can be run against your current project using a range of commands:
`dbt test` runs all tests in the dbt project
`dbt test --select test_type:generic`
`dbt test --select test_type:singular`
`dbt test --select one_specific_model`

dbt test --select source:*

* deploying pipelines in dbt cloud
 
make sure when you make changes in the development branch that you build them successfully first
then commit 
then merge changes in master branch as the job pulls from the master branch
when anything unmerged in the master branch runs it may create models that raise errors like the ones previously worked on already in the development branch

## Snowflake
* How we can connect to snowflake using dbt:
to avoid any `invalid JWT error` and `listing databases in snowflake` errors using dbt we need to make sure to input hte right credentials in our profiles.yaml in our dbt project
```
forums_analyses:
  outputs:
    dev:
      type: snowflake
      account: <The 'account identifier' displayed in our account details in our snowflake UI e.g. '***SURP-LN34***'>
      user: <the 'login name' displayed in our account details in our snowflake UI e.g. A************0>
      role: <the 'role' displayed in our account details in our snowflake UI e.g. ACCOUNTADMIN>

      private_key_path: <path/to/our/private key/filename.p8>
      private_key_passphrase: <password when we created our private key>
      
      warehouse: <name of our compute warehouse e.g. COMPUTE_WH>
      database: <name of our database (case sensitive) e.g. SUBREDDIT_ANALYSES_DB>
      schema: <name of our schema under the database (case sensitive) e.g. SUBREDDIT_ANALYSES_BRONZE>
      threads: 4
  target: dev
```
1. Assuming openssl is installed in our machine we need to run `openssl genrsa 2048 | openssl pkcs8 -topk8 -v2 des3 -inform PEM -out rsa_key.p8` which generates a private key (can be unencrypted if we add `-nocrypt` flag)
2. then we run `openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub` which generates a public key version of the private key we created
3. we then now grant privilege to our snowflake user to assign it a public key by running this sql command in snowflake through perhaps a file: `GRANT MODIFY PROGRAMMATIC AUTHENTICATION METHODS ON USER <login name> TO ROLE <role>;`
4. And then now run:
```
ALTER USER <login name> 
SET RSA_PUBLIC_KEY='<the string generated for our public key>'
```

note that `"jdbc:snowflake://<account identifier/id which is made up of <organization name>-<account name>>.snowflakecomputing.com/?user=<login name>&warehouse=<warehouse name>&db=<database name which is case sensitive>&schema=<database name which is case sensitive>&authenticator=externalbrowser"` is the JDBC connector we use to connect to snowflake if through something like a python script

* we can actuall yrun dbt snowflake and airflow together without separately using an airflow container: https://www.astronomer.io/docs/astro/cli/install-cli

* Akala natin dati `CREATE ICEBERG TABLE` creates a duplicate of the same delta or iceber table in our data lake s3 when in reality this is what happens:

Creating an Iceberg table in S3 does not inherently duplicate data in Snowflake. Snowflake's native integration with Apache Iceberg allows it to directly query and manage Iceberg tables stored in external cloud storage like S3 without needing to copy the data into Snowflake's internal storage format.

Here's how it works:

Data remains in S3: When you create an Iceberg table in S3 and then define it within Snowflake, the actual data files (e.g., Parquet files) remain in your S3 bucket.

Snowflake manages metadata (for Managed Iceberg tables): If you create a "Managed Iceberg Table" in Snowflake, Snowflake manages the Iceberg table's metadata (schema, snapshots, etc.) while the data itself stays in S3. This allows Snowflake to leverage Iceberg's features like time travel and schema evolution.

Snowflake reads data directly: When you query the Iceberg table in Snowflake, Snowflake's compute engine accesses and processes the data directly from S3, without first ingesting it or creating a separate copy within Snowflake.

In essence, Snowflake acts as a powerful query engine and, for managed tables, a metadata manager for Iceberg tables, but it does not duplicate the underlying data stored in S3. This approach allows for a more open and interoperable data lake architecture, where the same data can be accessed and utilized by various tools and engines.

* snowpark library you can understand as actually just using a spark dataframe and spark user capabilities but utilizing the distributed compute of snowflake
```
# Import python packages
import streamlit as st
import pandas as pd

# Snowpark
from snowflake.snowpark.context import get_active_session
import snowflake.snowpark.functions as F

# Cortex Functions
import snowflake.cortex  as cortex

session = get_active_session()

# Understand the sentiment of customer review using Cortex Sentiment
reviews_df = session.table('truck_reviews')

reviews_df = reviews_df.withColumn('SENTIMENT', cortex.sentiment(F.col('REVIEW')))

reviews_df.select(["REVIEW","SENTIMENT"]).show(15, max_width = 100)
```

* A stage in Snowflake is a temporary cloud storage location (internal to Snowflake or external like S3/Azure/GCS) that acts as a holding area for data files before loading into tables or after unloading
                     |-> External Stages: References data files in your cloud storage (S3, Azure Blob, GCS). 
snowflake -> stages -| 
                     |-> Internal Stages: Storage within Snowflake's system, managed by Snowflake 

Internal stages can have the ff. types:
1. User Stages: Private to each user for personal uploads. `LIST @~<name of stage>`
2. Table Stages: Associated with a specific table for direct loading/unloading. `LIST @%<name of stage>`
3. Named Stages: Reusable, manually created stages for more flexibility. `LIST @<name of stage>`

External stages however are standalone and are distinct to internal stages if their is a reference to the location of the data lake file:
```
CREATE OR REPLACE STAGE sa_ext_stage_integration
    STORAGE_INTEGRATION = forums_analyses_si
    URL = 's3://forums-analyses-bucket' -- Replace with your S3 bucket and folder path
    FILE_FORMAT = pff;

LIST @sa_ext_stage_integration;

CREATE OR REPLACE TABLE raw_reddit_data AS (
  SELECT
    $1:title::VARCHAR AS title,
    $1:score::INTEGER AS score,
    $1:id::VARCHAR AS id,
    $1:url::VARCHAR AS url,
    $1:comment::VARCHAR AS comment,
    -- Add more columns as needed
  FROM @sa_ext_stage_integration/raw_reddit_data.parquet
);
```

OR

```
CREATE OR REPLACE STAGE sa_ext_stage_integration
    STORAGE_INTEGRATION = forums_analyses_si
    URL = 's3://forums-analyses-bucket' -- Replace with your S3 bucket and folder path
    FILE_FORMAT = pff;

LIST @sa_ext_stage_integration;

CREATE OR REPLACE TABLE raw_reddit_data (
  title VARCHAR(255),
  score INTEGER,
  id VARCHAR(20),
  url VARCHAR(255),
  comment VARCHAR
);

COPY INTO raw_reddit_data
FROM @sa_ext_stage_integration/raw_reddit_data.parquet;
```

these are the two ways of creating stages and then copying them into physical tables in the database

* No copy procedures in snowflake are paramount. In a data platform like Snowflake, using a named external stage for data loading typically requires using the `COPY INTO` command to explicitly move or reference data into a standard table, whereas Iceberg tables are designed for direct querying in place without a separate copy or ingestion step.

Here are the key differences:
External Stages and COPY INTO: An external stage in Snowflake points to files in your external cloud storage (like S3, Azure Blob, or GCS). To make that data available in a standard Snowflake-managed table for full DML operations (inserts, updates, deletes), you must execute a COPY INTO command. This command scans the data from the staged files and writes it into the target table, a process that consumes compute resources.

Iceberg Tables and Direct Access: Snowflake-managed Iceberg tables, by contrast, allow you to work with data files directly in your external cloud storage using an open table format specification. Snowflake manages the table metadata and can query the data files in place, eliminating the need for a separate COPY INTO ingestion process to make the data available for analytics.

External Tables (a related concept): Note that "external tables" (a different, read-only Snowflake feature from external stages) also allow querying data in external storage without copying. However, they are read-only and require extra steps (like using ALTER EXTERNAL TABLE ... REFRESH) to update metadata about new files, which Iceberg tables manage more seamlessl

* warehouse manipulation statements in snowflake:
1. 

* Clustering in snowflake:

to create a clustered table in snowflake on a specific column/s we create the table by:
```
CREATE TABLE my_table (
    id INT,
    date_col DATE,
    other_data VARCHAR
)
CLUSTER BY (date_col, id);
```

```
USE acenres;
USE acenres.<schema name>;

-- show tables and views in schema
SHOW TABLES;
```

this is what show tables returns, where we can use it as subquery to return only
the rows or tables that have `automatic_clustering` on
```
retention_time | automatic_clustering | change_tracking | search_optimization
7              | OFF                  | OFF             | OFF
7              | OFF                  | OFF             | OFF
7              | OFF                  | OFF             | OFF
7              | OFF                  | OFF             | OFF
```


`SELECT * FROM <table name>;`

if a table with a clustering key is defined this will not raise an error: `SELECT SYSTEM$CLUSTERING_INFORMATION('<table name>');` however we can still see the clustering information e.g. depth and information of a column in a table without a cluster index defined by specifying the specific column/s
```
SELECT SYSTEM$CLUSTERING_INFORMATION('<table name>', '(raw_metric)');
SELECT SYSTEM$CLUSTERING_DEPTH('<table name>', '(raw_metric)');
```

to define a cluster in an existing table we use: `ALTER TABLE <table_name> CLUSTER BY (<col 1> [, <col 2>, ...])` e.g. `ALTER TABLE my_table CLUSTER BY (date_col, id);`

to drop it simply use `ALTER TABLE <name> DROP CLUSTERING KEY`

just the mere fact that we use the `CLUSTER BY` clause in snowflake for a table will automatically cluster/recluster said table in our database. So when this is the case when we execute `SHOW TABLE` and look through the table that we know has a cluster we will see that the `automatic_clustering` column is set to `ON`. And if ever we wanted to temporarily stop the automatic clustering of the table we would run `ALTER TABLE <table name> SUSPEND RECLUSTER` resulting in that table having an `automatic_clustering` col of `OFF` and if we would want to resume it again we would run `ALTER TABLE <table name> RESUME RECLUSTER`. And finally if we wanted to recluster that tables columns in which it was clustered by we run the latter command again.

It is importatnt to note that automatic clustering consumes snowflake credits, but does not require you to provide a virtual warehouse, this is because snowflake internally manages and achieves efficient resource utilization for reclustering the tables

* external tables/stages moreover cannot use the cluster by feature in snowflake

* The more frequently a table is queried, the more benefit clustering provides. However, the more frequently a table changes, the more expensive it will be to keep it clustered. Therefore, clustering is generally most cost-effective for tables that are queried frequently and do not change frequently.

* Whether you want faster response times or lower overall costs, clustering is best for a table that meets all of the following criteria:

1. The table contains a large number of micro-partitions. Typically, this means that the table contains multiple terabytes (TB) of data.

2. The queries can take advantage of clustering. Typically, this means that one or both of the following are true:

- The queries are selective. In other words, the queries need to read only a small percentage of rows (and thus usually a small percentage of micro-partitions) in the table.

- The queries sort the data. (For example, the query contains an ORDER BY clause on the table.)

3. A high percentage of the queries can benefit from the same clustering key(s). In other words, many/most queries select on, or sort on, the same few column(s).

If your goal is primarily to reduce overall costs, then each clustered table should have a high ratio of queries to DML operations (INSERT/UPDATE/DELETE). This typically means that the table is queried frequently and updated infrequently.

* The number of distinct values (i.e. cardinality, or how many unique values there are) in a column/expression is a critical aspect of selecting it as a clustering key. It is important to choose a clustering key that has:
1. A large enough number of distinct values to enable effective pruning on the table. I.e. many unique values like `DOG`, `CAT`, `MOUSE`, `HORSE`, `DOLPHIN`, `GOAT`, etc. if in the context of perhaps ML for animal species classification
2. A small enough number of distinct values to allow Snowflake to effectively group rows in the same micro-partitions. e.g. dates with only years like `2010`, `2012`, `2013`, `2015`, etc.

so that when for example the year 2010 is only the one being filtered for, we can find the rows with only 2010 in a specific partition and discard all other partitions to retrieve it faster

A column with very low cardinality might yield only minimal pruning, such as a column named IS_NEW_CUSTOMER that contains only Boolean values. At the other extreme, a column with very high cardinality is also typically not a good candidate to use as a clustering key directly. For example, a column that contains nanosecond timestamp values would not make a good clustering key.

extremely high cardinality --- high cardinality --- medium cardinality --- low cardinality --- extremely low cardinality

we can think of this kind of scale where the farther we are to the left or right that clustering may not be a good idea due to the cardinality.

* In general, if a column (or expression) has higher cardinality, then maintaining clustering on that column is more expensive.

The cost of clustering on a unique key might be more than the benefit of clustering on that key, especially if point lookups are not the primary use case for that table.

* If you want to use a column with very high cardinality as a clustering key, Snowflake recommends defining the key as an expression on the column, rather than on the column directly, to reduce the number of distinct values. The expression should preserve the original ordering of the column so that the minimum and maximum values in each partition still enable pruning.

For example, if a fact table has a TIMESTAMP column c_timestamp containing many discrete values (many more than the number of micro-partitions in the table), then a clustering key could be defined on the column by casting the values to dates instead of timestamps (e.g. to_date(c_timestamp)). This would reduce the cardinality to the total number of days, which typically produces much better pruning results.

* If you are defining a multi-column clustering key for a table, the order in which the columns are specified in the CLUSTER BY clause is important. As a general rule, Snowflake recommends ordering the columns from lowest cardinality to highest cardinality. Putting a higher cardinality column before a lower cardinality column will generally reduce the effectiveness of clustering on the latter column.

* A view is simply saved/cached queries e.g. `CREATE OR REPLACE <db name>.<schema name>.<view name> (<col 1>, <col 2>, ..., <col n>) AS (SELECT <col 1 (must be the same name as col definition in view and that means renaming this queried col if needed)>, <col 2>, ..., <col n>)`. This is a non materialized view which can utilize `JOIN` clauses in the select statements. However materialized views such as those used in dbt are used to improve time efficiency of queries frequently used as such
```
Feature        | Materialized View                                 | Non-Materialized View
Data Storage   | Stores data physically (like a table)             | No data stored; it's a virtual definition
Query Speed    | Fast (precomputed)                                | Slower (computed on demand)
Data Freshness | Stale (needs refresh)                             | Always current (real-time)
Storage Cost   | High (stores data)                                | Low (only stores query)
Maintenance    | High (refresh needed)                             | Minimal (none for data)
Best For       | Performance-critical, complex, infrequent changes | Data simplification, security, up-to-date data
```

* A column in a table can be a varient type usually those containing structured data such as:
```
{'etag': 'aHTTcyKom34kuM7FUJwIwmvhH4s',
  'id': 'UgxobbYFW5QNK-WFcNF4AaABAg',
  'kind': 'youtube#commentThread',
  'replies': {
    'comments': [ # these are the replies to the top level comment found
      {
        'etag': 'AIOuAJxmbBzRJ9s2le8VsLT6_gY',
        'id': 'UgxobbYFW5QNK-WFcNF4AaABAg.9s4V-mdzLq79s5enfTdY8b',
        'kind': 'youtube#comment',
        'snippet': {
          'authorChannelId': {
            'value': 'UCaizTs-t-jXjj8H0-S3ATYA'
          },
          'authorChannelUrl': 'http://www.youtube.com/@analyticswithadam',
          'authorDisplayName': '@analyticswithadam',
          'authorProfileImageUrl': 'https://yt3.ggpht.com/2PBxLW_kGCY1hfybNHu216RHGBDBNZW4m7aS9kU2Lj_6waMwDMmDrGGEg6zJsYuAq63nDtNd=s48-c-k-c0x00ffffff-no-rj',
          'canRate': True,
          'channelId': 'UCaizTs-t-jXjj8H0-S3ATYA',
          'likeCount': 0,
          'parentId': 'UgxobbYFW5QNK-WFcNF4AaABAg',
          'publishedAt': '2023-07-13T06:26:01Z',
          'textDisplay': 'Glad it was useful',
          'textOriginal': 'Glad it was useful',
          'updatedAt': '2023-07-13T06:26:01Z',
          'videoId': 'SIm2W9TtzR0',
          'viewerRating': 'none'
        }
      },
      {
        'etag': 'nsigOsdXr79YDN2WHK4gwJXAR7k',
        'id': 'UgxobbYFW5QNK-WFcNF4AaABAg.9s4V-mdzLq7AOXiT2PhrVd',
        'kind': 'youtube#comment',
        'snippet': {
          'authorChannelId': {
            'value': 'UCA_EdNiC9bUaQsbTT3-YsAg'
          },
          'authorChannelUrl': 'http://www.youtube.com/@JennaHasm',
          'authorDisplayName': '@JennaHasm',
          'authorProfileImageUrl': 'https://yt3.ggpht.com/WUm40JH_Uqb4dYhjx6jYFBQzJHmwEMOFYPxLvHLLwo-1_5aISu5XaISbB84S7IYZG4Y0afJEyQ=s48-c-k-c0x00ffffff-no-rj',
          'canRate': True,
          'channelId': 'UCaizTs-t-jXjj8H0-S3ATYA',
          'likeCount': 0, 
          'parentId': 'UgxobbYFW5QNK-WFcNF4AaABAg',
          'publishedAt': '2025-10-21T09:12:46Z',
          'textDisplay': '\u200b@analyticswithadam<br>Do '
                        'you know why youtube '
                        'rewards (monetarely) '
                        'channel owners that '
                        'create distructive '
                        'content instead of '
                        'channel owners like '
                        'yours for example. From '
                        'what O noticed it&#39;s '
                        'not the niche topic '
                        'that is the problem, '
                        'it&#39;s ... rewarding '
                        'the worst of '
                        'humans.<br>It '
                        'doesn&#39;t make a lot '
                        'of sense to me.',
          'textOriginal': '\u200b@analyticswithadam\n'
                          'Do you know why '
                          'youtube rewards '
                          '(monetarely) channel '
                          'owners that create '
                          'distructive content '
                          'instead of channel '
                          'owners like yours for '
                          'example. From what O '
                          "noticed it's not the "
                          'niche topic that is '
                          "the problem, it's ... "
                          'rewarding the worst of '
                          'humans.\n'
                          "It doesn't make a lot "
                          'of sense to me.',
          'updatedAt': '2025-10-21T09:12:46Z',
          'videoId': 'SIm2W9TtzR0', # this is that youtube video's vidoeId
          'viewerRating': 'none'
        }
      }
    ]
  },
 'snippet': {
    'canReply': True,
    'channelId': 'UCaizTs-t-jXjj8H0-S3ATYA',
    'isPublic': True,
    'topLevelComment': {
      'etag': '81lATGyrrx6iL2m58jTqimCH7bs',
      'id': 'UgxobbYFW5QNK-WFcNF4AaABAg',
      'kind': 'youtube#comment',
      'snippet': {
        'authorChannelId': {
          'value': 'UCAeABcbzXpqZ9ELNznsqRBg'
        },
        'authorChannelUrl': 'http://www.youtube.com/@oraclesql',
        'authorDisplayName': '@oraclesql',
        'authorProfileImageUrl': 'https://yt3.ggpht.com/FVtbQGQrlS_QWV1bAMc-wZ9vUd1lKKix4yN3wtFE2N07-qdYjakorpSSk8u11Q-NQ5JIq7hl=s48-c-k-c0x00ffffff-no-rj',
        'canRate': True,
        'channelId': 'UCaizTs-t-jXjj8H0-S3ATYA',
        'likeCount': 1,
        'publishedAt': '2023-07-12T19:32:27Z',
        'textDisplay': 'Thank you for '
                      'this Adam. Great '
                      'tuorial',
        'textOriginal': 'Thank you for '
                        'this Adam. Great '
                        'tuorial',
        'updatedAt': '2023-07-12T19:32:27Z',
        'videoId': 'SIm2W9TtzR0',
        'viewerRating': 'none'
      }
    },
    'totalReplyCount': 2,
    'videoId': 'SIm2W9TtzR0'
  }
}
```
this is an example of one row or instance of a comment from the youtube api which can most likely be a row or instance too in a snowflake column having the variant type. 

lets say we had a table `my_variant_table` e.g.
```
CREATE TABLE my_variant_table (
  comment_obj VARIANT
)
```

OR 

```
WITH my_comment_table AS (
  SELECT PARSE_JSON('{
    "etag": "aHTTcyKom34kuM7FUJwIwmvhH4s",
    "id": "UgxobbYFW5QNK-WFcNF4AaABAg",
    "kind": "youtube#commentThread",
    "replies": {
      "comments": [
        {
          "etag": "AIOuAJxmbBzRJ9s2le8VsLT6_gY",
          "id": "UgxobbYFW5QNK-WFcNF4AaABAg.9s4V-mdzLq79s5enfTdY8b",
          "kind": "youtube#comment",
          "snippet": {
            "authorChannelId": {
              "value": "UCaizTs-t-jXjj8H0-S3ATYA"
            },
            "authorChannelUrl": "http://www.youtube.com/@analyticswithadam",
            "authorDisplayName": "@analyticswithadam",
            "authorProfileImageUrl": "https://yt3.ggpht.com/2PBxLW_kGCY1hfybNHu216RHGBDBNZW4m7aS9kU2Lj_6waMwDMmDrGGEg6zJsYuAq63nDtNd=s48-c-k-c0x00ffffff-no-rj",
            "canRate": True,
            "channelId": "UCaizTs-t-jXjj8H0-S3ATYA",
            "likeCount": 0,
            "parentId": "UgxobbYFW5QNK-WFcNF4AaABAg",
            "publishedAt": "2023-07-13T06:26:01Z",
            "textDisplay": "Glad it was useful",
            "textOriginal": "Glad it was useful",
            "updatedAt": "2023-07-13T06:26:01Z",
            "videoId": "SIm2W9TtzR0",
            "viewerRating": "none"
          }
        },
        {
          "etag": "nsigOsdXr79YDN2WHK4gwJXAR7k",
          "id": "UgxobbYFW5QNK-WFcNF4AaABAg.9s4V-mdzLq7AOXiT2PhrVd",
          "kind": "youtube#comment",
          "snippet": {
            "authorChannelId": {
              "value": "UCA_EdNiC9bUaQsbTT3-YsAg"
            },
            "authorChannelUrl": "http://www.youtube.com/@JennaHasm",
            "authorDisplayName": "@JennaHasm",
            "authorProfileImageUrl": "https://yt3.ggpht.com/WUm40JH_Uqb4dYhjx6jYFBQzJHmwEMOFYPxLvHLLwo-1_5aISu5XaISbB84S7IYZG4Y0afJEyQ=s48-c-k-c0x00ffffff-no-rj",
            "canRate": True,
            "channelId": "UCaizTs-t-jXjj8H0-S3ATYA",
            "likeCount": 0, 
            "parentId": "UgxobbYFW5QNK-WFcNF4AaABAg",
            "publishedAt": "2025-10-21T09:12:46Z",

            "textDisplay": "\u200b@analyticswithadam<br>Do\\nyou know why youtube\\nrewards (monetarely)\\nchannel owners that\\ncreate distructive\\ncontent instead of\\nchannel owners like\\nyours for example. From\\nwhat O noticed it&#39;s\\nnot the niche topic\\nthat is the problem,\\nit&#39;s ... rewarding\\nthe worst of\\nhumans.<br>It\\ndoesn&#39;t make a lot\\nof sense to me.",

            "textOriginal": "\u200b@analyticswithadam<br>Do\\nyou know why youtube\\nrewards (monetarely)\\nchannel owners that\\ncreate distructive\\ncontent instead of\\nchannel owners like\\nyours for example. From\\nwhat O noticed it&#39;s\\nnot the niche topic\\nthat is the problem,\\nit&#39;s ... rewarding\\nthe worst of\\nhumans.<br>It\\ndoesn&#39;t make a lot\\nof sense to me.",

            "updatedAt": "2025-10-21T09:12:46Z",
            "videoId": "SIm2W9TtzR0",
            "viewerRating": "none"
          }
        }
      ]
    },
  "snippet": {
      "canReply": True,
      "channelId": "UCaizTs-t-jXjj8H0-S3ATYA",
      "isPublic": True,
      "topLevelComment": {
        "etag": "81lATGyrrx6iL2m58jTqimCH7bs",
        "id": "UgxobbYFW5QNK-WFcNF4AaABAg",
        "kind": "youtube#comment",
        "snippet": {
          "authorChannelId": {
            "value": "UCAeABcbzXpqZ9ELNznsqRBg"
          },
          "authorChannelUrl": "http://www.youtube.com/@oraclesql",
          "authorDisplayName": "@oraclesql",
          "authorProfileImageUrl": "https://yt3.ggpht.com/FVtbQGQrlS_QWV1bAMc-wZ9vUd1lKKix4yN3wtFE2N07-qdYjakorpSSk8u11Q-NQ5JIq7hl=s48-c-k-c0x00ffffff-no-rj",
          "canRate": True,
          "channelId": "UCaizTs-t-jXjj8H0-S3ATYA",
          "likeCount": 1,
          "publishedAt": "2023-07-12T19:32:27Z",
          "textDisplay": "Thank you for\\nthis Adam. Great\\ntuorial",
          "textOriginal": "Thank you for\\nthis Adam. Great\\ntuorial",
          "updatedAt": "2023-07-12T19:32:27Z",
          "videoId": "SIm2W9TtzR0",
          "viewerRating": "none"
        }
      },
      "totalReplyCount": 2,
      "videoId": "SIm2W9TtzR0"
    }
  }') AS comment_obj
)

SELECT * FROM my_comment_table
```

and we sought to see what data type was the `comment_obj` column using the `TYPEOF()` function we would get a column of `OBJECT`'s since this `comment_obj` column itself has instances of dictionaries, objects, etc. kind of like in python or javascript. 

again important attributes in this object will definitely be: level, video_id, comment_id, author_channel_id, channel_id_where_comment_was_made, parent_comment_id, text_original, text_display, published_at, updated_at, like_count, author_display_name, author_channel_url, added_at

and below is a sample of how we can access jsons/objects/dictionaries with snowflake:
```
USE snowflake_learning_db;

WITH my_comment_table AS (
    SELECT PARSE_JSON('{
      "etag": "aHTTcyKom34kuM7FUJwIwmvhH4s",
      "id": "UgxobbYFW5QNK-WFcNF4AaABAg",
      "kind": "youtube#commentThread",
      "replies": {
        "comments": [
          {
            "etag": "AIOuAJxmbBzRJ9s2le8VsLT6_gY",
            "id": "UgxobbYFW5QNK-WFcNF4AaABAg.9s4V-mdzLq79s5enfTdY8b",
            "kind": "youtube#comment",
            "snippet": {
              "authorChannelId": {
                "value": "UCaizTs-t-jXjj8H0-S3ATYA"
              },
              "authorChannelUrl": "http://www.youtube.com/@analyticswithadam",
              "authorDisplayName": "@analyticswithadam",
              "authorProfileImageUrl": "https://yt3.ggpht.com/2PBxLW_kGCY1hfybNHu216RHGBDBNZW4m7aS9kU2Lj_6waMwDMmDrGGEg6zJsYuAq63nDtNd=s48-c-k-c0x00ffffff-no-rj",
              "canRate": True,
              "channelId": "UCaizTs-t-jXjj8H0-S3ATYA",
              "likeCount": 0,
              "parentId": "UgxobbYFW5QNK-WFcNF4AaABAg",
              "publishedAt": "2023-07-13T06:26:01Z",
              "textDisplay": "Glad it was useful",
              "textOriginal": "Glad it was useful",
              "updatedAt": "2023-07-13T06:26:01Z",
              "videoId": "SIm2W9TtzR0",
              "viewerRating": "none"
            }
          },
          {
            "etag": "nsigOsdXr79YDN2WHK4gwJXAR7k",
            "id": "UgxobbYFW5QNK-WFcNF4AaABAg.9s4V-mdzLq7AOXiT2PhrVd",
            "kind": "youtube#comment",
            "snippet": {
              "authorChannelId": {
                "value": "UCA_EdNiC9bUaQsbTT3-YsAg"
              },
              "authorChannelUrl": "http://www.youtube.com/@JennaHasm",
              "authorDisplayName": "@JennaHasm",
              "authorProfileImageUrl": "https://yt3.ggpht.com/WUm40JH_Uqb4dYhjx6jYFBQzJHmwEMOFYPxLvHLLwo-1_5aISu5XaISbB84S7IYZG4Y0afJEyQ=s48-c-k-c0x00ffffff-no-rj",
              "canRate": True,
              "channelId": "UCaizTs-t-jXjj8H0-S3ATYA",
              "likeCount": 0, 
              "parentId": "UgxobbYFW5QNK-WFcNF4AaABAg",
              "publishedAt": "2025-10-21T09:12:46Z",
    
              "textDisplay": "\u200b@analyticswithadam<br>Do\\nyou know why youtube\\nrewards (monetarely)\\nchannel owners that\\ncreate distructive\\ncontent instead of\\nchannel owners like\\nyours for example. From\\nwhat O noticed it&#39;s\\nnot the niche topic\\nthat is the problem,\\nit&#39;s ... rewarding\\nthe worst of\\nhumans.<br>It\\ndoesn&#39;t make a lot\\nof sense to me.",
    
              "textOriginal": "\u200b@analyticswithadam<br>Do\\nyou know why youtube\\nrewards (monetarely)\\nchannel owners that\\ncreate distructive\\ncontent instead of\\nchannel owners like\\nyours for example. From\\nwhat O noticed it&#39;s\\nnot the niche topic\\nthat is the problem,\\nit&#39;s ... rewarding\\nthe worst of\\nhumans.<br>It\\ndoesn&#39;t make a lot\\nof sense to me.",
    
              "updatedAt": "2025-10-21T09:12:46Z",
              "videoId": "SIm2W9TtzR0",
              "viewerRating": "none"
            }
          }
        ]
      },
     "snippet": {
        "canReply": True,
        "channelId": "UCaizTs-t-jXjj8H0-S3ATYA",
        "isPublic": True,
        "topLevelComment": {
          "etag": "81lATGyrrx6iL2m58jTqimCH7bs",
          "id": "UgxobbYFW5QNK-WFcNF4AaABAg",
          "kind": "youtube#comment",
          "snippet": {
            "authorChannelId": {
              "value": "UCAeABcbzXpqZ9ELNznsqRBg"
            },
            "authorChannelUrl": "http://www.youtube.com/@oraclesql",
            "authorDisplayName": "@oraclesql",
            "authorProfileImageUrl": "https://yt3.ggpht.com/FVtbQGQrlS_QWV1bAMc-wZ9vUd1lKKix4yN3wtFE2N07-qdYjakorpSSk8u11Q-NQ5JIq7hl=s48-c-k-c0x00ffffff-no-rj",
            "canRate": True,
            "channelId": "UCaizTs-t-jXjj8H0-S3ATYA",
            "likeCount": 1,
            "publishedAt": "2023-07-12T19:32:27Z",
            "textDisplay": "Thank you for\\nthis Adam. Great\\ntuorial",
            "textOriginal": "Thank you for\\nthis Adam. Great\\ntuorial",
            "updatedAt": "2023-07-12T19:32:27Z",
            "videoId": "SIm2W9TtzR0",
            "viewerRating": "none"
          }
        },
        "totalReplyCount": 2,
        "videoId": "SIm2W9TtzR0"
      }
    }') AS comment_obj
),

comments AS (
    SELECT
        'comment' AS level,
        comment_obj:snippet:topLevelComment:snippet:videoId::VARCHAR(50) AS video_id,
        comment_obj:id::VARCHAR(50) AS comment_id,
        comment_obj:snippet:topLevelComment:snippet:authorChannelId:value::VARCHAR(50) AS author_channel_id,
        comment_obj:snippet:topLevelComment:snippet:channelId::VARCHAR(50) AS channel_id_where_comment_was_made,
        
        -- we leave as null since there a top level comment
        -- has no parent
        NULL AS parent_comment_id,
        
        comment_obj:snippet:topLevelComment:snippet:textOriginal::TEXT AS text_original,
        comment_obj:snippet:topLevelComment:snippet:textDisplay::TEXT AS text_display,
        comment_obj:snippet:topLevelComment:snippet:publishedAt::TIMESTAMP_NTZ AS published_at,
        comment_obj:snippet:topLevelComment:snippet:updatedAt::TIMESTAMP_NTZ AS updated_at,
        comment_obj:snippet:topLevelComment:snippet:likeCount::NUMBER(5, 0) AS like_count,
        comment_obj:snippet:topLevelComment:snippet:authorDisplayName::VARCHAR(50) AS author_display_name,
        comment_obj:snippet:topLevelComment:snippet:authorChannelUrl::VARCHAR(50) AS author_channel_url
    FROM my_comment_table
),

replies AS (
    SELECT 
        'reply' AS level,
        value:snippet:videoId::VARCHAR(50) AS video_id,
        value:id::VARCHAR(50) AS comment_id,
        value:snippet:authorChannelId:value::VARCHAR(50) AS author_channel_id,
        value:snippet:channelId::VARCHAR(50) AS channel_id_where_comment_was_made,
        value:snippet:parentId::VARCHAR(50) AS parent_comment_id,
        value:snippet:textOriginal::TEXT AS text_original,
        value:snippet:textDisplay::TEXT AS text_display,
        value:snippet:publishedAt::TIMESTAMP_NTZ AS published_at,
        value:snippet:updatedAt::TIMESTAMP_NTZ AS updated_at,
        value:snippet:likeCount::NUMBER(5, 0) AS like_count,
        value:snippet:authorDisplayName::VARCHAR(50) AS author_display_name,
        value:snippet:authorChannelUrl::VARCHAR(50) AS author_channel_url
    FROM 
        my_comment_table mct,
        -- this explode our array column value into
        -- their own respective rows, in this case
        -- we are aliasing my_comment_table accessing
        -- accessing the comment_obj column then the value
        -- of the replies key and then  the value of the
        -- comments key
        LATERAL FLATTEN(input => mct.comment_obj:replies:comments)
)

-- unionize the CTEs of comments and replies
SELECT * FROM comments
UNION BY NAME
SELECT * FROM replies
```

final table will be:
```
| level | video_id | comment_id | ... | like_count | author_channel_id | author_display_name |
| reply | SIm2W9TtzR0 | mdzLq79s5enfTdY8b | ... | 0 | @analyticswithadam | http://... | 
| reply | SIm2W9TtzR0 | mdzLq7AOXiT2PhrVd | ... | 0 | @JennaHasm | http://... | 
| comment | SIm2W9TtzR0 | WFcNF4AaABAg | ... | 0 | @oraclesql | http://... | 
```

basically how LATERAL FLATTEN works is `LATERAL FLATTEN(input => <alias of table with object or array column>.<column array directly or object that might contain the array (if object then we use : as our preceding char instead of .)>.<array directly or object that might contain the array (if object then we use : as our preceding char instead of .)>)`

* different time travel methods:
- using timestamps (use AT and TIMESTAMP)
- using seconds/offsets (use AT and OFFSET )
- using previous query ids (use BEFORE and STATEMENT)

```
SET good_data_query_id = LAST_QUERY_ID();
SET good_data_timestamp = CURRENT_TIMESTAMP;
```

to use the variable use `$good_data_query_id` or `$good_data_timestamp`

to time travel if indeed our data/table has been corrupted and data/table is still within retention time

we use `SELECT * FROM <table we want to retrieve uncorrupted state> AT(TIMESTAMP => $good_data_timestamp);` or `SELECT * FROM <table we want to retrieve uncorrupted state> BEFORE(STATEMENT => $good_query_id);`

* permanent tables retention is 0 <= x <= 90, transient and temporary tables have retentions of 0 <= x <= 90

temporary tables exist until session ends

transient tables exist until they are dropped

* 
```
-- cloning
-- create a sample table
CREATE OR REPLACE TABLE ops_playground.larry.plant_capacities_copy AS (
    SELECT * FROM wesm.dbt_jquintos.plant_capacities
);

SELECT * FROM ops_playground.larry.plant_capacities_copy;

-- say we want a clone of this table
CREATE OR REPLACE TABLE ops_playground.larry.plant_capacities_copy_clone
CLONE ops_playground.larry.plant_capacities_copy;

-- if we run this we will see that
-- plant_capacities_copy has a certain number of 
-- allocated  bytes while plant_capacities_copy_clone 
-- has 0 number of allocated bytes. This is because until
-- we add new data to this cloned table it will remain 0
-- and if we do decide to add data the size would now be
-- size of the original table + size of newly added data
-- e.g. original table is 20000 bytes and clone is 0 bytes
-- if we add new data of 200 bytes clone will now be 20200
-- bytes
SELECT * FROM ops_playground.information_schema.table_storage_metrics; 

-- time travel with cloning, so let's
-- select our copied table again to ensure it
-- is out most recent query and save this most
-- recent query's id in a variable
SELECT * FROM ops_playground.larry.plant_capacities_copy;
SET good_data_query_id = LAST_QUERY_ID();
SELECT $good_data_query_id;

-- lets say our copied table was corrupted with
-- nulls and zeroes in certain columns
UPDATE ops_playground.larry.plant_capacities_copy
SET
   resource_name = NULL,
   iemop_registered_capacity = 0,
   pmax = 0,
   dc_capacity = 18,
   updated_at = CURRENT_TIMESTAMP();

-- say we want a clone of this corrupted table too
CREATE OR REPLACE TABLE ops_playground.larry.plant_capacities_copy_clone
CLONE ops_playground.larry.plant_capacities_copy;

-- checking our 'corrupted' table
SELECT * FROM ops_playground.larry.plant_capacities_copy;
SELECT * FROM ops_playground.larry.plant_capacities_copy_clone;

-- however running this would not allow us to run the timetravel 
-- statement we need to revert back to the previous state of the 
-- table as it would raise Statement <saved query id> cannot be used 
-- to specify time for time travel query.

    
-- we can however go back to our most recent
-- uncorrupted table state using the query
SELECT * FROM ops_playground.larry.plant_capacities_copy BEFORE(STATEMENT => $good_data_query_id);

-- because the corrupted table does not contain
-- id's we can use to update it with the timetraveled
-- tables values we can just create or replace the
-- corrupted table using the values of the timetraveled 
-- table
CREATE OR REPLACE TABLE ops_playground.larry.plant_capacities_copy_clone
CLONE ops_playground.larry.plant_capacities_copy BEFORE(STATEMENT => $good_data_query_id);

CREATE OR REPLACE TABLE ops_playground.larry.plant_capacities_copy AS (
    SELECT * FROM ops_playground.larry.plant_capacities_copy BEFORE(STATEMENT => $good_data_query_id)
);

-- we revert back both our table and cloned tables to
-- its previous state
SELECT * FROM ops_playground.larry.plant_capacities_copy;
SELECT * FROM ops_playground.larry.plant_capacities_copy_clone;
```

* UDFs in snowflake
```
-- creating python UDF
CREATE OR REPLACE FUNCTION foo (str_col VARCHAR, is_parent BOOLEAN)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
HANDLER = 'foo_py'
AS
$$
def foo_py(str_col, is_parent):
    if len(str_col) < 5:
        return "foo"

    elif 5 <= len(str_col) <= 10:
        return "bar"

    else:
        return "foobar"
$$;


-- we can pass whole columns to this UDF like pandas
-- apply functions 
SELECT FOO(author_display_name, TRUE) FROM stg_youtube_practice;  
```

```
CREATE OR REPLACE FUNCTION foo (str_col VARCHAR, comments TABLE)
RETURNS STRING
AS
$$

$$
```

* Stored procedures
```
CREATE OR REPLACE PROCEDURE delete_old ()
RETURNS BOOLEAN
LANGUAGE SQL
AS
$$
  DECLARE
    $max_ts
    $cutoff_ts
  BEGIN
    $max_ts := (SELECT MAX(order_ts) FROM orders)
    -- say the latest order timestamp is 05-07-2001
    -- we want orders that are only 180 days older than
    -- 05-07-2001, and anything earlier than this interval
    -- will be considered old, so 05-07-2001 minus 180 days
    -- is essentially 11-08-2000, so anything older than
    -- 11-08-2000 will be an old record. DATEADD is a scalar
    -- function that takes in the interval we want to subtract
    -- or add from our given date, in this case we want to add
    -- or minus 1 day, and the next param is the number to add
    -- or subtract from the given date, and final param is the 
    -- given date we want to use to add or subtract a value to
    $cutoff_ts := (SELECT DATEADD('DAY', -180, $max_ts))
    DELETE FROM orders
    WHERE order_ts < :cutoff_ts;
$$
```


* roles

ACCOUNTADMIN (
  READ, 
  LIST, 
  CREATE, 
  INSERT, 
  UPDATE, 
  DELETE,
  GRANT, 
  DB, 
  SCHEMA, 
  STAGES, 
  ROLES,
  TABLES,
  VIEWS,
  PROCEDURES,
  FUNCTIONS,
  INTEGRATIONS,
  FILE FORMATS,
  EXTERNAL VOLUMES
) --> DATA_ENGINEER (
  READ,
  LIST,
  CREATE,
  INSERT,
  UPDATE,
  DELETE,
  DB,
  SCHEMA,
  STAGES,
  TABLES,
  VIEWS,
  PROCEDURES,
  FUNCTIONS,
  INTEGRATIONS,
  FILE FORMATS,
  EXTERNAL VOLUMES
) --> DATA_ANALYST (
  READ,
  LIST,
  DB,
  SCHEMA,
  STAGES,
  TABLES,
  VIEWS,
  PROCEDURES,
  INTEGRATIONS,
  EXTERNAL VOLUMES
)

DATA_ENGINEER --> michaelcueva
DATA_ENGINEER --> aleksandrsolzhenitsyn
DATA_ANALYST --> gabriel29820

is easier as opposed to:

ACCOUNTADMIN (with same privileges) --> michaelcueva (
  READ,
  LIST,
  CREATE,
  INSERT,
  UPDATE,
  DELETE,
  DB,
  SCHEMA,
  TABLES,
  VIEWS,
  PROCEDURES,
  FUNCTIONS,
  INTEGRATIONS,
  FILE FORMATS,
  EXTERNAL VOLUMES
)

ACCOUNTADMIN --> aleksandrsolzhenitsyn (
  READ,
  LIST,
  CREATE,
  INSERT,
  UPDATE,
  DELETE,
  DB,
  SCHEMA,
  TABLES,
  VIEWS,
  PROCEDURES,
  FUNCTIONS,
  INTEGRATIONS,
  FILE FORMATS,
  EXTERNAL VOLUMES
)

ACCOUNTADMIN --> gabriel29820 (
  READ,
  LIST,
  DB,
  SCHEMA,
  STAGES,
  TABLES,
  VIEWS,
  PROCEDURES,
  INTEGRATIONS,
  EXTERNAL VOLUMES
)

* Again like PySpark (Apache Spark) its typical statements are replicated in snowflake through a snowflake point of view:
- `from pyspark.sql import SparkSession` is to `from snowflake.snowpark import Session`
- 
```
...
spark_conf = SparkConf()
spark_conf.setAppName("test")
spark_conf.set("spark.driver.memory", "14g") 
spark_conf.set("spark.sql.execution.arrow.maxRecordsPerBatch", "100")

spark_ctxt = SparkContext(conf=spark_conf)

hadoop_conf = spark_ctxt._jsc.hadoopConfiguration()
hadoop_conf.set("fs.s3a.access.key", credentials["aws_access_key_id"])
hadoop_conf.set("fs.s3a.secret.key", credentials["aws_secret_access_key"])
hadoop_conf.set("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
hadoop_conf.set("spark.hadoop.fs.s3a.aws.credentials.provider", "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider")

spark = SparkSession(spark_ctxt).builder\
  .getOrCreate()
...
```

is to

```
connection_parameters = {
  "account": "<your snowflake account>",
  "user": "<your snowflake user>",
  "password": "<your snowflake password>",
  "role": "<your snowflake role>",  # optional
  "warehouse": "<your snowflake warehouse>",  # optional
  "database": "<your snowflake database>",  # optional
  "schema": "<your snowflake schema>",  # optional
}

snowpark = Session.builder.configs(connection_parameters).create()
```

- `spark.stop()`/`spark.close()` is to `snowpark.close()`
- `spark.sql("SELECT * FROM my_table)` is to `snowpark.sql("SELECT * FROM my_table")`
- 
```
train_signals_df = spark.sql("""
    SELECT 
        s.signals AS signals, 
        s.subjectId AS subjectId, 
        s.rowId AS rowId
    FROM {train_labels_df} l
    LEFT JOIN {signals_df} s
    ON l.subjectId = s.subjectId
  """, signals_df=signals_df, train_labels_df=train_labels_df)
```

is to 

-
```
+------+-----+----------+
|row_id|value|subject_id|
+------+-----+----------+
|     0|   10| subject_2|
|     1|   20| subject_2|
|     2|   30| subject_2|
|     3|   40| subject_2|
|     4|   50| subject_2|
|     5|   60| subject_2|
|     6|   70| subject_2|
|     7|   80| subject_2|
|     8|   90| subject_2|
|     9|  100| subject_2|
|    10|  110| subject_2|
|    11|  120| subject_2|
|     0|   10| subject_1|
|     1|   20| subject_1|
|     2|   30| subject_1|
|     3|   40| subject_1|
|     4|   50| subject_1|
|     5|   60| subject_1|
|     6|   70| subject_1|
|     7|   80| subject_1|
|     8|   90| subject_1|
|     9|  100| subject_1|
|    10|  110| subject_1|
|    11|  120| subject_1|
|    12|  130| subject_1|
|    13|  140| subject_1|
|    14|  150| subject_1|
|    15|  160| subject_1|
|    16|  170| subject_1|
|    17|  180| subject_1|
|    18|  190| subject_1|
|    19|  200| subject_1|
+------+-----+----------+
```


```
samples_per_win_size = 6
samples_per_hop_size = 4
feat_window = Window.partitionBy("subject_id").orderBy("row_id").rowsBetween(Window.currentRow, samples_per_win_size - 1)
df_3 = df_3.withColumn("freq_std", F.sum("value").over(feat_window))
```

an implementation of the only including windows after a certain hop size, since we cannot do it directly using spark we can filter out the rows of windows that have not yet made the appropriate hop size using filtering
```
cond = ((F.col("row_id") % samples_per_hop_size) == 0)
df_3 = df_3.where(cond)
```

```
+------+-----+----------+--------+
|row_id|value|subject_id|freq_std|
+------+-----+----------+--------+
|     0|   10| subject_1|     210|
|     4|   50| subject_1|     450|
|     8|   90| subject_1|     690|
|    12|  130| subject_1|     930|
|    16|  170| subject_1|     740|
|     0|   10| subject_2|     210|
|     4|   50| subject_2|     450|
|     8|   90| subject_2|     420|
+------+-----+----------+--------+
```

in snowflake we would just do this with our snowpark session we created

- `import pyspark.sql.functions as F` is to `import snowflake.snowpark.functions as F` 

- 
```
import pyspark.sql as pyspark
import pyspark.sql.functions as F

def main(session: pyspark.SparkSession):
  df = session.read.format("csv")\
  .option("header", "true")\
  .option("inferSchema", "true")\
  .load(INPUT_PATH)

  df = session.sql(f"SELECT col1, col2 FROM {tableName}", tableName=df)
  df = df.filter(F.col("language") == 'python')

  # Print a sample of the df to standard output.
  df.show()

  # Return value will appear in the Results tab.
  return df
```
is to
```
# The Snowpark package is required for Python Worksheets. 
# You can add more packages by selecting them using the Packages control and then importing them.
import snowflake.snowpark as snowpark
import snowflake.snowpark.functions as F

def main(session: snowpark.Session): 
  # Your code goes here, inside the "main" handler.
  tableName = 'information_schema.packages'
  df = session.sql(f"SELECT * FROM {tableName}")
  df = df.filter(F.col("language") == 'python')

  # Print a sample of the df to standard output.
  df.show()

  # Return value will appear in the Results tab.
  return df
```

* I actually have the option of using either snowpipe or dbt incremental models to load my delta table files in s3:
- should I use snowpipe it would imply:
  - extacting and extracting data using python
  - checking if there is already an existing file with same schema of the table, if there is none then create the parquet e.g. raw_youtube_videos_0001.parquet, if there is one already existing get the max number suffix of the file which in this case would be 0001 and then add 1 to it so we can create a number suffix for the new file 0002 e.g. raw_youtube_videos_0002.parquet
  - ```
    CREATE FILE FORMAT IF NOT EXISTS pff
      TYPE = PARQUET;

    CREATE OR REPLACE PIPE my_pipe AUTO_INGEST = TRUE AS
    COPY INTO my_table
    FROM @sa_ext_stage_integration/raw_reddit_data.parquet
    FILE_FORMAT = pff
    ON_ERROR = 'CONTINUE'; -- Or 'SKIP_FILE', 'ABORT_STATEMENT'
  ```

- should I use dbt incremental models it would imply:
  - extracting yes data using python but not possibly duplicated rows of data across multiple files
  - not anymore checking if there is an existing file as this method uses open table formats like delta lake to ensure non duplication of data, and would result in only a single "file" easily maintainable in the data lake as it won't contain the same tables with different rows across different files like `raw_youtube_videos_0001.parquet`, `raw_youtube_videos_0002.parquet`, `raw_youtube_videos_0003.parquet`, ..., `raw_youtube_videos_000N.parquet`.
  - when ever new data is added to the delta table dbt incremental models can compare the existing table in snowflake against the one in s3 and add/insert or update these rows in snowflake as needed based on some kind of primary/composite key
  - a zero copy operation as snowflake will essentially make these delta tables a part/extension of its own catalog since snowflake will basically be merely pointing to these tables for potential use in queries. The drawbacks to this of course is in high performance queries compute may slow down because snowflake has to go across towards s3 to retrieve the data
  - ```
    -- create external volume 
    CREATE OR REPLACE EXTERNAL VOLUME forums_analyses_ext_vol
    STORAGE_LOCATIONS =
    (
        (
            NAME = 'delta-ap-southeast-2'
            STORAGE_PROVIDER = 'S3'
            STORAGE_BASE_URL = 's3://forums-analyses-bucket/'
            STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<arn number>:role/<role>'
        )
    )
    ALLOW_WRITES = TRUE

    -- create the catalog integration for Delta tables 
    CREATE CATALOG INTEGRATION IF NOT EXISTS delta_catalog_integration
    CATALOG_SOURCE = OBJECT_STORE
    TABLE_FORMAT = DELTA
    ENABLED = TRUE;

    -- point to the iceberg/delta table
    CREATE OR REPLACE ICEBERG TABLE raw_reddit_posts_comments
    CATALOG = delta_catalog_integration
    EXTERNAL_VOLUME = forums_analyses_ext_vol
    BASE_LOCATION = 'raw_reddit_posts_comments'
    AUTO_REFRESH = TRUE;
  ```

* `snowflake.cortext.summarize()`, `snowflake.cortex.complete()`, `snowflake.cortex.extract_answer()`, `snowflake.cortex.translate()` could be useful in data with text, case on point youtube videos comments, and reddit posts comments

e.g. `SELECT SNOWFLAKE.CORTEX.SUMMARIZE(SNOWFLAKE.CORTEX.COMPLETE(STATEMENT)) AS THOUGHTS_FROM_STATEMENT_SUMMARY FROM STG_REDDIT_POSTS_COMMENTS`

```
SELECT SNOWFLAKE.CORTEX.COMPLETE(
    'openai-gpt-4.1',
        CONCAT('Critique this review in bullet points: <review>', content, '</review>')
) FROM reviews LIMIT 10;
```

* like apache spark's/databricks' capability in being able to model machine learning algorithms for data science/ML workloads, snowpark likewise has the exact capability to leverage traditional algorithms for modelling

and what's so great about it is if alam mo na or you already know deeply scikit-learn model training workloads and the like, you'll have no problem with `snowflake.ml`s library as it exactly mimics that of scikit-learns same functions, classes that pertain to feature engineering, data preprocessing, and model training.
```
from snowflake.ml.utils.connection_params import SnowflakeLoginOptions
from snowflake.snowpark import Session, DataFrame
from snowflake.ml.modeling.preprocessing import StandardScaler
from snowflake.ml.modeling.impute import SimpleImputer
from snowflake.ml.modeling.pipeline import Pipeline
from snowflake.ml.modeling.xgboost import XGBClassifier
from snowflake.ml.modeling.metrics import accuracy score

# Note: Create session https://docs.snowflake.com/en/developer-guide/snowpark/reference/pyth
session = Session.builder.configs(SnowflakeLoginOptions()).create()

# Step 1: Create train and test dataframes
all_data = session.sql("select, IFF (CLASS g. 1.0, 0.0) as LABEL from Gamma_Telescope_0) train_data, test_data = all_data.random_split(weights=[8.9, 8.11], seed=81)

# Step 2: Construct training pipeline with preprocessing and modeling steps 
FEATURE_COLS = [c for c in train_data.columns if c != "LABEL"]
LABEL_COLS = ["LABEL"]

pipeline = Pipeline(steps=[
  ("impute", SimpleImputer(input_cols=FEATURE_COLS, output_cols=FEATURE_COLS)), 
  ("scaler, StandardScaler(input_cols=FEATURE_COLS, output_cols=FEATURE_COLS), 
  ("model", XGBClassifier(input_cols=FEATURE_COLS, label_cols LABEL COLS))

# Step 3: Train
pipeline.fit(train_data)

# Step 4: Evaluate
predict_on_training_data = pipeline.predict(train_data)
training_accuracy = accuracy_score(df=predict_on_training_data, y_true_col_names=["LABEL"])

predict_on_test_data = pipeline.predict(test_data)
eval_accuracy = accuracy_score(df=predict_on_test_data, y_true_col_names=["LABEL", y_pred_c])

print(f"Training accuracy: (training accuracy) \nEval accuracy: (eval_accuracy)")
```

* Creating external volumes in snowflake to connect to use open table formats in s3 involves the ff:
```
-- create external volume 
CREATE OR REPLACE EXTERNAL VOLUME forums_analyses_ext_vol
    STORAGE_LOCATIONS =
    (
        (
            NAME = '<some location name of bucket e.g. delta-ap-southeast-2>'
            STORAGE_PROVIDER = 'S3'
            STORAGE_BASE_URL = 's3://<name of s3 bucket>/'
            STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<arn number>:role/<iam role>'
        )
    )
    ALLOW_WRITES = TRUE
```

* if ever you encoutner errors converting unix timestamps e.g. 284923848023480000 to datetimes like `Snowflake shows 'Invalid date' in TIMESTAMP_NTZ column`

The solution is to always cast the column to VARCHAR and then to `TIMESTAMP_NTZ`.

this is because some of the unix timestamp values in the staged parquet files can be formatted as integers and some as strings!

Example using a unix timestamp:

`SELECT 1620502461213752::timestamp_ntz`; -> Invalid date

`SELECT 1620502461213752::varchar::timestamp_ntz`; -> 2021-05-08 19:34:21.213

`SELECT '1620502461213752'::timestamp_ntz`; -> 2021-05-08 19:34:21.213

This seems to be because `timestamp_ntz` only accepts integer epoch timestamps in milliseconds (eg. 1620502461213).

However, when the integer is cast to varchar first, then timestamp_ntz correctly interprets the epoch timestamp in microseconds (eg. 1620502461213752). This likely applies to timestamps in nanoseconds as well, although I did not confirm that case.

So it seems that Invalid date is a strange front-end issue for timestamps far in the future, created by misidentifying epoch timestamp units.

* reading delta files in s3 using snowflake without external volumes
```
-- showing grants to current user
SHOW GRANTS TO ROLE DATA_ENGINEER;

CREATE OR REPLACE STORAGE INTEGRATION forums_analyses_si
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<arn number>:role/<role>'
    STORAGE_ALLOWED_LOCATIONS = ('s3://forums-analyses-bucket');

DESCRIBE STORAGE INTEGRATION forums_analyses_si;

CREATE FILE FORMAT IF NOT EXISTS playground.larry.pff
    TYPE = PARQUET;

CREATE OR REPLACE STAGE playground.larry.stg_reddit_posts_comments
    STORAGE_INTEGRATION = forums_analyses_si
    URL = 's3://forums-analyses-bucket/raw_reddit_posts_comments/' -- Replace with your S3 bucket and folder path
    FILE_FORMAT = playground.larry.pff;

CREATE OR REPLACE STAGE playground.larry.stg_reddit_posts
    STORAGE_INTEGRATION = forums_analyses_si
    URL = 's3://forums-analyses-bucket/raw_reddit_posts/' -- Replace with your S3 bucket and folder path
    FILE_FORMAT = playground.larry.pff;

LIST @playground.larry.stg_reddit_posts_comments;
LIST @playground.larry.stg_reddit_posts;

SELECT
    $1:post_id::VARCHAR(50) AS post_id,
    $1:post_name::VARCHAR(50) AS post_id_full,
    $1:level::VARCHAR(50) AS level,
    $1:comment_id::VARCHAR(50) AS comment_id,
    $1:comment_name::VARCHAR(50) AS comment_id_full,
    $1:comment_upvotes::INTEGER AS comment_upvotes,
    $1:comment_downvotes::INTEGER AS comment_downvotes,
    $1:comment_created_at::VARCHAR::TIMESTAMP_NTZ AS comment_created_at,
    $1:comment_edited_at::VARCHAR::TIMESTAMP_NTZ AS comment_edited_at,
    $1:comment_author_name::VARCHAR(50) AS comment_author_username,
    $1:comment_author_fullname::VARCHAR(50) AS comment_author_id_full,
    $1:comment_parent_id::VARCHAR(50) AS comment_parent_id_full,
    $1:comment_body::TEXT AS comment_body,
    $1:added_at::VARCHAR::TIMESTAMP_NTZ AS added_at
    -- pattern below is used to match all parquet files
FROM @playground.larry.stg_reddit_posts_comments (FILE_FORMAT => 'pff', PATTERN => '.*\.parquet');

SELECT
    $1:post_title::VARCHAR AS post_title,
    $1:post_score::INTEGER AS post_score,
    $1:post_id::VARCHAR(50) AS post_id,
    $1:post_name::VARCHAR(50) AS post_id_full,
    $1:post_url::VARCHAR AS post_url,
    $1:post_author_name::VARCHAR(50) AS post_author_username,
    $1:post_author_fullname::VARCHAR(50) AS post_author_id_full,
    $1:post_body::TEXT AS post_body,
    $1:post_created_at::VARCHAR::TIMESTAMP_NTZ AS post_created_at,
    $1:post_edited_at::VARCHAR::TIMESTAMP_NTZ AS post_edited_at,
    $1:added_at::VARCHAR::TIMESTAMP_NTZ AS added_at
    -- pattern below is used to match all parquet files
FROM @playground.larry.stg_reddit_posts (FILE_FORMAT => 'pff', PATTERN => '.*\.parquet');

-- create tables where copied data will land
-- using snowpipe
CREATE OR REPLACE TABLE raw_reddit_posts_comments (
    post_id VARCHAR(50),
    post_id_full VARCHAR(50),
    level VARCHAR(50),
    comment_id VARCHAR(50),
    comment_id_full VARCHAR(50),
    comment_upvotes INTEGER,
    comment_downvotes INTEGER,
    comment_created_at TIMESTAMP_NTZ,
    comment_edited_at TIMESTAMP_NTZ,
    comment_author_username VARCHAR(50),
    comment_author_id_full VARCHAR(50),
    comment_parent_id_full VARCHAR(50),
    comment_body TEXT,
    added_at TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE raw_reddit_posts (
    post_title VARCHAR,
    post_score INTEGER,
    post_id VARCHAR(50),
    post_id_full VARCHAR(50),
    post_url VARCHAR,
    post_author_username VARCHAR(50),
    post_author_id_full VARCHAR(50),
    post_body TEXT,
    post_created_at TIMESTAMP_NTZ,
    post_edited_at TIMESTAMP_NTZ,
    added_at TIMESTAMP_NTZ
);


-- copy the s3 reddit posts comments table into 
-- the empty reddit posts comments snowflake table
-- how this will run is if the s3 delta table 
-- experiences an event of adding new parquet files
-- then this pipe will run the copy
CREATE OR REPLACE PIPE playground.larry.reddit_posts_comments_pipe
AUTO_INGEST = TRUE
AS 
COPY INTO playground.larry.raw_reddit_posts_comments
FROM (
    SELECT
        $1:post_id::VARCHAR(50) AS post_id,
        $1:post_name::VARCHAR(50) AS post_id_full,
        $1:level::VARCHAR(50) AS level,
        $1:comment_id::VARCHAR(50) AS comment_id,
        $1:comment_name::VARCHAR(50) AS comment_id_full,
        $1:comment_upvotes::INTEGER AS comment_upvotes,
        $1:comment_downvotes::INTEGER AS comment_downvotes,
        $1:comment_created_at::VARCHAR::TIMESTAMP_NTZ AS comment_created_at,
        $1:comment_edited_at::VARCHAR::TIMESTAMP_NTZ AS comment_edited_at,
        $1:comment_author_name::VARCHAR(50) AS comment_author_username,
        $1:comment_author_fullname::VARCHAR(50) AS comment_author_id_full,
        $1:comment_parent_id::VARCHAR(50) AS comment_parent_id_full,
        $1:comment_body::TEXT AS comment_body,
        $1:added_at::VARCHAR::TIMESTAMP_NTZ AS added_at
        -- pattern below is used to match all parquet files
    FROM @playground.larry.stg_reddit_posts_comments (FILE_FORMAT => 'pff', PATTERN => '.*\.parquet')
);
-- DROP PIPE IF EXISTS playground.larry.reddit_posts_comments_pipe;

CREATE OR REPLACE PIPE playground.larry.reddit_posts_pipe
AUTO_INGEST = TRUE
AS 
COPY INTO playground.larry.raw_reddit_posts
FROM (
    SELECT
        $1:post_title::VARCHAR AS post_title,
        $1:post_score::INTEGER AS post_score,
        $1:post_id::VARCHAR(50) AS post_id,
        $1:post_name::VARCHAR(50) AS post_id_full,
        $1:post_url::VARCHAR AS post_url,
        $1:post_author_name::VARCHAR(50) AS post_author_username,
        $1:post_author_fullname::VARCHAR(50) AS post_author_id_full,
        $1:post_body::TEXT AS post_body,
        $1:post_created_at::VARCHAR::TIMESTAMP_NTZ AS post_created_at,
        $1:post_edited_at::VARCHAR::TIMESTAMP_NTZ AS post_edited_at,
        $1:added_at::VARCHAR::TIMESTAMP_NTZ AS added_at
        -- pattern below is used to match all parquet files
    FROM @playground.larry.stg_reddit_posts (FILE_FORMAT => 'pff', PATTERN => '.*\.parquet')
);
-- DROP PIPE IF EXISTS playground.larry.reddit_posts_pipe;

-- we do this to get the value of the notification channel column
-- as we will need this value for the event notification for s3
-- bucket so our pipes trigger when certain events in our s3
-- bucket happen
SHOW PIPES;

SELECT * FROM playground.larry.raw_reddit_posts_comments;
SELECT * FROM playground.larry.raw_reddit_posts;

SELECT SYSTEM$PIPE_STATUS('reddit_posts_pipe');
```

* ok now I've created staging objects for my delta/iceberg tables since I can't use external volumes because of my privileges set by our admin, I have however been able to select the raw_reddit_posts and comments data I have and have created a snow pipe for it so that when a new delta file is written in s3 I expect for the pipe to auto ingest this new parquet file in the delta folder, however I am facing the fact that even after insertion and updating of records in my delta tables, I find my pipe does not auto ingest these delta table parquets

Since you have already set up the STORAGE INTEGRATION and the PIPE with AUTO_INGEST = TRUE, you have completed the "Snowflake side" of the handshake. However, Snowpipe is not psychic. Even with AUTO_INGEST enabled, Snowflake won't know a file has landed in S3 unless S3 explicitly "tells" it.

The reason your pipe isn't ingesting data is almost certainly because the S3 Event Notifications (the "handshake") haven't been configured on the AWS side.

1. The Missing Link: S3 Event Notifications
When you set AUTO_INGEST = TRUE, Snowflake creates an SQS (Simple Queue Service) Queue specifically for that pipe. You must tell S3 to send a "New Object Created" message to that specific queue.

How to find your SQS ARN: Run this in Snowflake:

SQL

SHOW PIPES;
Look for the column notification_channel. It will look something like: `arn:aws:sqs:us-east-1:1234567890:sf-snowpipe-ABC123....`

What to do in AWS Console:

Go to your S3 bucket (forums-analyses-bucket).

Go to Properties > Event notifications > Create event notification.

Event types: Select "All object create events" (s3:ObjectCreated:*).

Destination: Select SQS Queue.

SQS Queue ARN: Paste the notification_channel ARN you got from Snowflake.

2. Can Pipes handle Delta Table folders?
To answer your specific question: Yes, Snowpipe works with Parquet files inside Delta folders, but with a big warning.

Snowpipe treats every .parquet file in that folder as a standalone file.

The Good: When your Delta table writes a new part-000...parquet file, S3 sends a notification, and Snowpipe ingests it.

The Bad: Delta Tables are versioned. If you update a record, Delta doesn't edit the file; it writes a new parquet file and updates the _delta_log to say "ignore the old one."

The Result: Since Snowpipe doesn't read the _delta_log, it will ingest the old file AND the new file. You will have duplicates in your raw_reddit_posts table.

3. Troubleshooting "Stuck" Pipes
If you've set up the S3 notification and it's still not working, use these "Admin" commands to see where the "pipe" is leaking:

Check if the pipe is actually "Running":

SQL

SELECT SYSTEM$PIPE_STATUS('playground.larry.reddit_posts_pipe');
Look for executionState: RUNNING. If it says STOPPED_MISSING_PIPE, you might have a permission issue.

Check for errors in the last hour:

SQL

SELECT * FROM TABLE(VALIDATE_PIPE_LOAD(
  PIPE_NAME => 'playground.larry.reddit_posts_pipe',
  START_TIME => DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
));
💡 Recommendation for your ACEN Workflow
Since you are a full-timer now, you want to build robust pipelines. Because Delta Tables produce multiple versions of files, you should treat your raw_reddit_posts table as a Landing/Staging table and use a dbt Incremental model with a unique_key to filter out the duplicates that Snowpipe will inevitably bring in.

One final check: Ensure your IAM Role (forums-analyses-ext-int-role) has s3:GetBucketLocation and s3:ListBucket permissions, or Snowpipe won't be able to "verify" the files exist when the notification hits.

Would you like me to show you how to check the S3 side to see if the notifications are actually being sent to Snowflake?

* sometimes you won't always have the privilege to have a password to your account in snowflake. Sometimes your company will only issue you an account username and account identifier that you can use as input to sign in to this issued account. What you do is just enter the account identifier e.g. `<SOMECOMPANYNAME>-<SOMECOMPANYNAME>` and you'll be prompted to enter the issued username to you which in this case could be an email e.g. <someemail.name@company.com> which serves as your username instead of typically a non email formatted username like `AUDIEMURPHY1089`. 

so to work with your dbt project using your company issued account you can still preserve your `profiles.yml`s private keys but only change your account identifier and username
```
dbt_fundamentals:
  outputs:
    dev:
      account: <account id in snowsight ui e.g. MYCOMPANY-SUBCOMPANY>
      database: <name of db e.g. DEV_PLAYGROUND>
      private_key_passphrase: <your private key password>
      private_key_path: C:/path/to/your/private/key/rsa_key.p8
      role: <role in your account that has enough grants e.g. DATA_ENGINEER>
      schema: <name of schema e.g. LARRY>
      threads: 4
      type: snowflake
      user: <someemail.name@company.com>
      warehouse: <warehouse name your company uses for learning e.g. COMPUTE_WH>
  target: dev
```
and to grant dbt to work on your companies snowflake warehouse programmatically we use again our issued username
```
SELECT CURRENT_USER();

-- GRANT MODIFY PROGRAMMATIC AUTHENTICATION METHODS ON USER AKUSLAYER3000 TO ROLE ACCOUNTADMIN;
GRANT MODIFY PROGRAMMATIC AUTHENTICATION METHODS ON USER "<someemail.name@company.com>" TO ROLE <your accounts issued role>;

ALTER USER "<someemail.name@company.com>" SET RSA_PUBLIC_KEY='<the public key you made e.g. MIIBI...>';
```

* Ok I am testing it with my iceberg tables that ingest data from my s3 bucket that are basically delta files. I am getting this error while creating a stream on my iceberg table caleld raw_youtube_videos:

`Streams on External Tables or Iceberg tables with an external catalog must have INSERT_ONLY set to true.`

This error occurs because Snowflake treats Iceberg Tables (with external catalogs) and External Tables differently than native Snowflake tables.

When data lives in your S3 bucket (external to Snowflake), Snowflake cannot perfectly track the "before" and "after" states of a row if it gets updated or deleted in the source files. Because of this metadata limitation, it forces you to use an Append-only model for change tracking.

The Fix: Add APPEND_ONLY = TRUE
You need to explicitly tell Snowflake that this stream will only track new rows being added to the Iceberg table.

Run this corrected SQL:
```
CREATE OR REPLACE STREAM raw_youtube_videos_stream 
ON ICEBERG TABLE raw_youtube_videos
APPEND_ONLY = TRUE;
```
(Note: While the error message says INSERT_ONLY, the actual keyword in the SQL syntax for streams is APPEND_ONLY = TRUE. They mean the same thing in this context.)

Why Snowflake forces this on Iceberg/External Tables
In a standard Snowflake table, Snowflake owns the micro-partitions. It knows exactly when a row is deleted or updated because it rewrites the partition.

With Iceberg/External tables:

Metadata vs. Data: Snowflake is often just reading the metadata (the Iceberg Manifest files) in your S3 bucket.

Tracking Complexity: Tracking a DELETE or an UPDATE in an external file requires a massive amount of overhead to compare the "old" file vs the "new" file.

The "Insert-Only" Guarantee: By setting APPEND_ONLY = TRUE, the stream essentially says: "I will only notify you when new records appear in the metadata. I am going to ignore any rows that were deleted or changed in the S3 files."

How to handle Updates/Deletes in your pipeline
Since your stream will now only "see" new rows, you might be wondering how to handle data that changed or was deleted in your S3 Delta files.

If your "Delta files" in S3 actually contain updates (e.g., a video's view count changed), your pipeline logic downstream needs to handle the de-duplication:

The Stream will capture the "new version" of the row.

Your Task/SQL should use a QUALIFY or ROW_NUMBER() logic to pick the latest version based on a timestamp, or use a MERGE statement to overwrite the old record in your "Bronze" or "Silver" internal Snowflake table.



* stream objects vs dynamic tables in snowflake:

is it a fair assessment that stream objects in snowflake are event while dynamic tables are time driven meaning if after a certain time period or interval only then does it make the change to the table using SQL logic regardless if the table this logic uses downstream has changed or not

That is a spot-on assessment. You’ve correctly identified the fundamental shift in how Snowflake handles data movement between these two objects.

In the Snowflake world, we often call this the difference between Imperative (Streams) and Declarative (Dynamic Tables) pipelines.

1. Streams: The "Event" Ledger
A Stream is essentially a bookmark (CDC - Change Data Capture). It doesn't move data; it just records that an "event" happened (Insert, Update, or Delete).

Behavior: It sits there silently until you—the engineer—decide to do something with it.

The Trigger: To actually change a downstream table, you usually pair a Stream with a Task. While Tasks are often scheduled, you can now set them to trigger only when the stream has data (making it truly event-driven).

Workload: You have to write the manual MERGE or INSERT logic.

2. Dynamic Tables: The "Time-Driven" State
A Dynamic Table is declarative. You don't tell Snowflake how to move the data; you tell it what the data should look like and how fresh it needs to be.

Behavior: The Target Lag (e.g., TARGET_LAG = '1 minute') is the heartbeat.

The Trigger: Snowflake’s automated process wakes up based on that time interval.

Your Logic: It looks at your SQL query, checks the upstream tables, and says, "To reach the state defined in this query within the 1-minute lag I was promised, I need to go pull these new rows now."

Comparison at a Glance
Feature	Streams (+ Tasks)	Dynamic Tables
Philosophy	"Something happened, now go run this code."	"This is what the table should look like; keep it fresh."
Driving Force	Events (DML changes in source).	Time (Target Lag).
Logic	Manual INSERT / MERGE statements.	A single SELECT statement.
Complexity	High (you manage the plumbing).	Low (Snowflake manages the plumbing).
Use Case	Complex ETL, Row-level logic, non-SQL tasks.	Standard Joins, Aggregations, Kimball-style Fact/Dim.
The Nuance: "Regardless if the table has changed"
You mentioned: "...only then does it make the change... regardless if the table... has changed or not."

There is one small technical distinction there:

If the source table HAS NOT changed: Snowflake is smart enough to realize there is no work to do. It won't waste credits re-processing the same data just because the time interval hit. It essentially checks the metadata, sees no new "offset," and goes back to sleep.

If the source table HAS changed: It will only pull those changes once the Time (Target Lag) interval is reached. Even if you have 1 million new rows, the Dynamic Table will ignore them until its next scheduled "refresh" window.

Why this matters for your Star Schema
If you are building those Additive/Non-Additive facts we talked about earlier:

Dynamic Tables are amazing for Aggregate Facts (e.g., a "Daily Sales Summary"). You just write the SUM(Sales) query, set a lag of 1 hour, and Snowflake ensures your summary table stays current without you writing complex Merge scripts.

Now that you're setting up your infra again in the new account, would you like me to show you the Terraform code for a Dynamic Table so you don't have to manually manage the grants and tasks?

* task objects in snowflake
```
USE ROLE accountadmin;
USE WAREHOUSE compute_wh;
USE DATABASE tasty_bytes;

-- Task that runs executes every minute
CREATE OR REPLACE TASK tasty_bytes.raw_pos.process_orders_header_sproc
WAREHOUSE = 'COMPUTE_WH'
SCHEDULE = 'USING CRON * * * * * UTC'
AS
CALL tasty_bytes.raw_pos.process_order_headers_stream();

-- Activate the task to run
ALTER TASK tasty_bytes.raw_pos.process_orders_header_sproc RESUME;

-- Query the table
SELECT * FROM tasty_bytes.raw_pos.daily_sales_hamburg_t;

-- Insert some dummy data into ORDER_HEADER
INSERT INTO tasty_bytes.raw_pos.order_header (
    ORDER_ID, 
    TRUCK_ID, 
    LOCATION_ID, 
    CUSTOMER_ID, 
    DISCOUNT_ID, 
    SHIFT_ID, 
    SHIFT_START_TIME, 
    SHIFT_END_TIME, 
    ORDER_CHANNEL, 
    ORDER_TS, 
    SERVED_TS, 
    ORDER_CURRENCY, 
    ORDER_AMOUNT, 
    ORDER_TAX_AMOUNT, 
    ORDER_DISCOUNT_AMOUNT, 
    ORDER_TOTAL
) VALUES (
    123456789,                     -- ORDER_ID
    101,                           -- TRUCK_ID
    4494,                          -- LOCATION_ID
    null,                          -- CUSTOMER_ID
    null,                          -- DISCOUNT_ID
    123456789,                     -- SHIFT_ID
    '08:00:00',                    -- SHIFT_START_TIME
    '16:00:00',                    -- SHIFT_END_TIME
    null,                          -- ORDER_CHANNEL
    '2024-01-12 12:30:45',         -- ORDER_TS
    null,                          -- SERVED_TS
    'USD',                         -- ORDER_CURRENCY
    22.00,                         -- ORDER_AMOUNT
    null,                          -- ORDER_TAX_AMOUNT
    null,                          -- ORDER_DISCOUNT_AMOUNT
    24.50                          -- ORDER_TOTAL
);

-- Wait 1 minute before running this, query the table once more
SELECT * FROM tasty_bytes.raw_pos.daily_sales_hamburg_t;

-- Suspend the task
ALTER TASK tasty_bytes.raw_pos.process_orders_header_sproc SUSPEND;


-- Optional: recreate the task such that it executes every 24 hours
-- CREATE OR REPLACE TASK tasty_bytes.raw_pos.process_orders_header_sproc
-- SCHEDULE = 'USING CRON 0 0 * * * UTC'
-- AS
-- CALL tasty_bytes.raw_pos.process_order_headers_stream();

-- Optional: Start the task
-- ALTER TASK tasty_bytes.raw_pos.process_orders_header_sproc RESUME;

-- Required: Stop the task if you started it using the command directly above this one
-- ALTER TASK tasty_bytes.raw_pos.process_orders_header_sproc SUSPEND;
```


* when we want to specify default connections for snowflake cli we need to define a connections.toml file which snowflake cli usually creates upon instlalation in `/Users/<main user>/.snowflake/` directory
```
default_connection_name="data_eng_devops_with_snowflake"

[somename]
account = "somename"
user = "<your login name>"
authenticator = "externalbrowconnections.ser"

[data_eng_devops_with_snowflake]
account = "<ORGNAME>-<COMPANYNAME>"
user = "<your login name>"
password = "<your login password>"
authenticator = "snowflake"
role = "<your accounts role e.g. ACCOUNTADMIN>"
```

we can explicitly add a connection through snowflake cli by running `snow connection add` which will prompt you to add values to the ff. fields to be stored in your `connections.toml` file in the aforementioned directory

* 
## Reddit, Youtube API
* 
```
# load env variables
client_id = os.environ['REDDIT_CLIENT_ID'] 
client_secret = os.environ['REDDIT_CLIENT_SECRET']
username = os.environ['REDDIT_USERNAME']
password = os.environ['REDDIT_PASSWORD']

redirect_uri = os.environ["REDDIT_REDIRECT_URI"]
duration = "permanent"
state = str(uuid4())

# scopes are needed to explicitly request access to areas of the api
scope = ",".join([
    "identity",
    "edit",
    "flair",
    "history",
    "modconfig",
    "modflair",
    "modlog",
    "modposts",
    "modwiki",
    "mysubreddits",
    "privatemessages",
    "read",
    "report",
    "save",
    "submit",
    "subscribe",
    "vote",
    "wikiedit",
    "wikiread"
])


url = "https://www.reddit.com/api/v1/authorize"
params = {
    "client_id": client_id,
    "response_type": "token",
    "state": state,
    "redirect_uri": redirect_uri,
    "duration": duration,
    "scope": scope
}

response = requests.get(url, params=params)
print(response.json())

# # login to reddit account programmatically with credentials
# # to extract a token that can be used to make requests to the reddit api
# client_auth = requests.auth.HTTPBasicAuth(client_id, client_secret)
# payload = {
#     "grant_type": "password", 

# }
# headers = {"User-Agent": f"ChangeMeClient/0.1 by {username}"}
# url = "https://www.reddit.com/api/v1/access_token"
# response = requests.post(url, auth=client_auth, data=payload, headers=headers)
# data = response.json()
# token = data['access_token']
# print(token)

# # make sample post to r/test
# url = "https://www.reddit.com/api/submit"
# params = {
#     "sr": "test",
#     "title": "test title from script",
#     "text": "this is a sample text from a python script",
#     "kind": "self"
# }
# url = "https://www.reddit.com/r/Jung/hot"
# params = {
#     "limit": 1
# }
# headers = {
#     "Authorization": f"bearer {token}"
# }
```

* The recommended format for user agent is `<platform>:<app ID>:<version string> (by u/<Reddit username>)`. For example, `android:com.example.myredditapp:v1.2.3 (by u/kemitche)`. `desktop:com.sr-analyses-pipeline:0.1 (by u/<reddit username>)`

* if we don't use our reddit password and username automatically what we can only do with the reddit api is use get requests or read only requests, we can't have permission to write, update, or delete a subreddit, or post, or comment

* the contents of the Submission object in the list of Submission objects returned by `subreddit.hot()` method are the ff:
```
{
  'comment_limit': 2048, 
  'comment_sort': 'confidence', 
  '_reddit': <praw.reddit.Reddit object at 0x000002E6D377A090>, 
  'approved_at_utc': None, 
  'subreddit': Subreddit(display_name='Philippines'), 
  'selftext': '\nWelcome to the r/Philippines hub thread! Where are you trying to go?\n\n## [Daily random discussion - Oct 04, 2025]
  (https://www.reddit.com/r/Philippines/comments/1nxcdz6)\n## [Weekly help thread - Sep 29, 2025]
  (https://www.reddit.com/r/Philippines/comments/1nt0uu1)\n## [What to do in June 2025]
  (https://www.reddit.com/r/Philippines/comments/1kbyd75)', 
  'author_fullname': 't2_g8u9x', 
  'saved': False, 
  'mod_reason_title': None, 
  'gilded': 0, 
  'clicked': False, 
  'title': '[HUB] Weekly Help Thread, Random Discussion, Events This Month, +more', 
  'link_flair_richtext': [], 
  'subreddit_name_prefixed': 'r/Philippines', 
  'hidden': False, 
  'pwls': 6, 
  'link_flair_css_class': None, 
  'downs': 0, 
  'thumbnail_height': None, 
  'top_awarded_type': None, 
  'hide_score': False, 
  'name': 't3_fztqqs', 
  'quarantine': False, 
  'link_flair_text_color': None, 
  'upvote_ratio': 0.99, 
  'author_flair_background_color': 'transparent', 
  'subreddit_type': 'public', 
  'ups': 373, 
  'total_awards_received': 0, 
  'media_embed': {}, 
  'thumbnail_width': None, 
  'author_flair_template_id': 'fada12be-4e86-11ec-886d-c2d462df1067', 
  'is_original_content': False, 
  'user_reports': [], 
  'secure_media': None, 
  'is_reddit_media_domain': False, 
  'is_meta': False, 
  'category': None, 
  'secure_media_embed': {}, 
  'link_flair_text': None, 
  'can_mod_post': False, 
  'score': 373, 
  'approved_by': None, 
  'is_created_from_ads_ui': False, 
  'author_premium': False, 
  'thumbnail': 'self', 
  'edited': 1759529338.0, 
  'author_flair_css_class': None, 
  'author_flair_richtext': [
    {
      'a': ':yaya:',
      'e': 'emoji',
      'u': 'https://emoji.redditmedia.com/q7f65kic2w181_t5_2qjov/yaya'
    }
  ], 
  'gildings': {}, 
  'content_categories': None, 
  'is_self': True, 
  'mod_note': None, 
  'created': 1586683718.0, 
  'link_flair_type': 'text', 
  'wls': 6, 
  'removed_by_category': None, 
  'banned_by': None, 
  'author_flair_type': 'richtext', 
  'domain': 'self.Philippines', 
  'allow_live_comments': True, 
  'selftext_html': '<!-- SC_OFF --><div class="md"><p>Welcome to the <a href="/r/Philippines">r/Philippines</a> hub thread! Where are you trying to go?</p>\n\n<h2><a href=
  "https://www.reddit.com/r/Philippines/comments/1nxcdz6">Daily random discussion - Oct 04, 2025</a></h2>\n\n<h2><a href=
  "https://www.reddit.com/r/Philippines/comments/1nt0uu1">Weekly help thread - Sep 29, 2025</a></h2>\n\n<h2><a href=
  "https://www.reddit.com/r/Philippines/comments/1kbyd75">What to do in June 2025</a></h2>\n</div><!-- SC_ON -->', 
  'likes': None, 
  'suggested_sort': 'new', 
  'banned_at_utc': None, 
  'view_count': None, 
  'archived': True, 
  'no_follow': False, 
  'is_crosspostable': True, 
  'pinned': False, 
  'over_18': False, 
  'all_awardings': [], 
  'awarders': [], 
  'media_only': False, 
  'can_gild': False, 
  'spoiler': False, 
  'locked': True, 
  'author_flair_text': ':yaya:', 
  'treatment_tags': [], 
  'visited': False, 
  'removed_by': None, 
  'num_reports': None, 
  'distinguished': 'moderator', 
  'subreddit_id': 't5_2qjov', 
  'author_is_blocked': False, 
  'mod_reason_by': None, 
  'removal_reason': None, 
  'link_flair_background_color': '', 
  'id': 'fztqqs', 
  'is_robot_indexable': True, 
  'report_reasons': None, 
  'author': Redditor(name='the_yaya'), 
  'discussion_type': None, 
  'num_comments': 5, 
  'send_replies': False, 
  'contest_mode': False, 
  'mod_reports': [], 
  'author_patreon_flair': False, 
  'author_flair_text_color': 'dark', 
  'permalink': '/r/Philippines/comments/fztqqs/hub_weekly_help_thread_random_discussion_events/', 
  'stickied': True, 
  'url': 'https://www.reddit.com/r/Philippines/comments/fztqqs/hub_weekly_help_thread_random_discussion_events/', 
  'subreddit_subscribers': 3482253, 
  'created_utc': 1586683718.0, 
  'num_crossposts': 7, 
  'media': None, 
  'is_video': False, 
  '_fetched': False, 
  '_additional_fetch_params': {}, 
  '_comments_by_id': {}
}
```

```
{
  'comment_limit': 2048, 
  'comment_sort': 'confidence', 
  '_reddit': <praw.reddit.Reddit object at 0x000002DF297B9FD0>, 
  'approved_at_utc': None, 
  'subreddit': Subreddit(display_name='Philippines'), 
  'selftext': '', 
  'author_fullname': 't2_u5gsmqsb', 
  'saved': False, 
  'mod_reason_title': None, 
  'gilded': 0, 
  'clicked': False, 
  'title': 'Somebody finally said it. Obvious kasi na ang nila Priority was always Duterte and not the people.', 
  'link_flair_richtext': [
    {
      'e': 'text', 
      't': 'PoliticsPH'
    }
  ], 
  'subreddit_name_prefixed': 'r/Philippines', 
  'hidden': False, 
  'pwls': 6, 
  'link_flair_css_class': 'politics', 
  'downs': 0, 
  'thumbnail_height': 139, 
  'top_awarded_type': None, 
  'hide_score': False, 
  'name': 't3_1nxjyey', 
  'quarantine': False, 
  'link_flair_text_color': 'dark', 
  'upvote_ratio': 0.99, 
  'author_flair_background_color': None, 
  'ups': 972, 
  'total_awards_received': 0, 
  'media_embed': {}, 
  'thumbnail_width': 140, 
  'author_flair_template_id': None, 
  'is_original_content': False, 
  'user_reports': [], 
  'secure_media': None, 
  'is_reddit_media_domain': True, 
  'is_meta': False, 
  'category': None, 
  'secure_media_embed': {}, 
  'link_flair_text': 'PoliticsPH', 
  'can_mod_post': False, 
  'score': 972, 
  'approved_by': None, 
  'is_created_from_ads_ui': False, 
  'author_premium': False, 
  'thumbnail':
  'https://b.thumbs.redditmedia.com/mE0SpuG2uFx_ovtuTNKy1E2g2QWnHvbqXw2Pgk43jVA.jpg', 
  'edited': False, 
  'author_flair_css_class': None, 
  'author_flair_richtext': [], 
  'gildings': {}, 
  'post_hint': 'image', 
  'content_categories': None, 
  'is_self': False, 
  'subreddit_type': 'public', 
  'created': 1759550195.0, 
  'link_flair_type': 'richtext', 
  'wls': 6, 
  'removed_by_category': None, 
  'banned_by': None, 
  'author_flair_type': 'text', 
  'domain': 'i.redd.it', 
  'allow_live_comments': False, 
  'selftext_html': None, 
  'likes': None, 
  'suggested_sort': None, 
  'banned_at_utc': None, 
  'url_overridden_by_dest':
  'https://i.redd.it/pglgtkt3q0tf1.jpeg', 
  'view_count': None, 
  'archived': False, 
  'no_follow': False, 
  'is_crosspostable': True, 
  'pinned': False, 
  'over_18': False, 
  'preview': {
    'images': [
      {
        'source': {
          'url': 'https://preview.redd.it/pglgtkt3q0tf1.jpeg?auto=webp&s=ffc0bf7b5b2be61e3a2e59a86d3f7d05265961b6', 
          'width': 1080, 
          'height': 1074
        }, 
        'resolutions': [
          {
            'url': 'https://preview.redd.it/pglgtkt3q0tf1.jpeg?width=108&crop=smart&auto=webp&s=a51ce4f45bbcdee952c8cfd7d4eb8e7a9d642fd9', 
            'width': 108, 
            'height': 107
          }, 
          {
            'url': 'https://preview.redd.it/pglgtkt3q0tf1.jpeg?width=216&crop=smart&auto=webp&s=f6a5fa1ab57a0f807f7ca39462f029a4bfe4c1c9', 
            'width': 216, 
            'height': 214
          },
          {
            'url': 'https://preview.redd.it/pglgtkt3q0tf1.jpeg?width=320&crop=smart&auto=webp&s=6798c6c311e3b70e2ff3dfebc2d8e140cfa10c77', 
            'width': 320, 
            'height': 318
          },
          {
            'url': 'https://preview.redd.it/pglgtkt3q0tf1.jpeg?width=640&crop=smart&auto=webp&s=f03031b0f95d2cdcace0d3918ea863159fbbe324', 
            'width': 640, 
            'height': 636
          },
          {
            'url': 'https://preview.redd.it/pglgtkt3q0tf1.jpeg?width=960&crop=smart&auto=webp&s=4afe6c967377d092014c097b55334867d56f4df7', 
            'width': 960, 
            'height': 954
          },
          {
            'url': 'https://preview.redd.it/pglgtkt3q0tf1.jpeg?width=1080&crop=smart&auto=webp&s=f5e5c65064f8612e64c94e4d1a0d60669798f26b', 
            'width': 1080, 
            'height': 1074
          }
        ], 
        'variants': {}, 
        'id': 'LnqXJao_Dedo12Ivi-MKfXPbZ3AwP4ea0igsb8z327o'
      }
    ], 
    'enabled': True
  }, 
  'all_awardings': [], 
  'awarders': [], 
  'media_only': False, 
  'link_flair_template_id': 'e123d194-6329-11ed-87a7-c288474b15e0', 
  'can_gild': False, 
  'spoiler': False, 
  'locked': False, 
  'author_flair_text': None, 
  'treatment_tags': [], 
  'visited': False, 
  'removed_by': None, 
  'mod_note': None, 
  'distinguished': None, 
  'subreddit_id': 't5_2qjov', 
  'author_is_blocked': False, 
  'mod_reason_by': None, 
  'num_reports': None, 
  'removal_reason': None, 
  'link_flair_background_color': '#ff80ff', 
  'id': '1nxjyey', 
  'is_robot_indexable': True, 
  'report_reasons': None, 
  'author': Redditor(name='DogsAndPokemons'), 
  'discussion_type': None, 
  'num_comments': 33, 
  'send_replies': True, 
  'contest_mode': False, 
  'mod_reports': [], 
  'author_patreon_flair': False, 
  'author_flair_text_color': None, 
  'permalink': '/r/Philippines/comments/1nxjyey/somebody_finally_said_it_obvious_kasi_na_ang_nila/', 
  'stickied': False, 
  'url':
  'https://i.redd.it/pglgtkt3q0tf1.jpeg', 
  'subreddit_subscribers': 3482255, 
  'created_utc': 1759550195.0, 
  'num_crossposts': 0, 
  'media': None, 
  'is_video': False, 
  '_fetched': False, 
  '_additional_fetch_params': {}, 
  '_comments_by_id': {}}
```

a comment object in a reddit post has the following data:
```
{
  '_replies': <praw.models.comment_forest.CommentForest object at 0x000001ADAE6EAA90>, 
  '_submission': Submission(id='1nxjyey'), 
  '_reddit': <praw.reddit.Reddit object at 0x000001ADAA7D8C10>, 
  'subreddit_id': 't5_2qjov', 
  'approved_at_utc': None, 
  'author_is_blocked': False, 
  'comment_type': None, 
  'awarders': [], 
  'mod_reason_by': None, 
  'banned_by': None, 
  'author_flair_type': 'text', 
  'total_awards_received': 0, 
  'subreddit': Subreddit(display_name='Philippines'), 
  'author_flair_template_id': None, 
  'likes': None, 
  'user_reports': [], 
  'saved': False, 
  'id': 'nhoac82', 
  'banned_at_utc': None, 
  'mod_reason_title': None, 
  'gilded': 0, 
  'archived': False, 
  'collapsed_reason_code': None, 
  'no_follow': False, 
  'author': Redditor(name='Positive-Pianist-218'), 
  'can_mod_post': False, 
  'created_utc': 1759557055.0, 
  'send_replies': True, 
  'parent_id': 't3_1nxjyey', 
  'score': 1, 
  'author_fullname': 't2_56jgik6x', 
  'approved_by': None, 
  'mod_note': None, 
  'all_awardings': [], 
  'collapsed': False, 
  'body': 'Kasi nga tuta sila ni Duterte, pag sinabi ni Duterte na talon, tatalon yang mga yan.', 
  'edited': False, 
  'top_awarded_type': None, 
  'author_flair_css_class': None, 
  'name': 't1_nhoac82', 
  'is_submitter': False, 
  'downs': 0, 
  'author_flair_richtext': [], 
  'author_patreon_flair': False, 
  'body_html': '<div class="md"><p>Kasi nga tuta sila ni Duterte, pag sinabi ni Duterte na talon, tatalon yang mga yan.</p>\n</div>', 
  'removal_reason': None, 
  'collapsed_reason': None, 
  'distinguished': None, 
  'associated_award': None, 
  'stickied': False, 
  'author_premium': False, 
  'can_gild': False, 
  'gildings': {}, 
  'unrepliable_reason': None, 
  'author_flair_text_color': None, 
  'score_hidden': True, 
  'permalink': '/r/Philippines/comments/1nxjyey/somebody_finally_said_it_obvious_kasi_na_ang_nila/nhoac82/', 
  'subreddit_type': 'public', 
  'locked': False, 
  'report_reasons': None, 
  'created': 1759557055.0, 
  'author_flair_text': None, 
  'treatment_tags': [], 
  'link_id': 't3_1nxjyey', 
  'subreddit_name_prefixed': 'r/Philippines', 
  'controversiality': 0, 
  'depth': 0, 
  'author_flair_background_color': None, 
  'collapsed_because_crowd_control': None, 
  'mod_reports': [], 
  'num_reports': None, 
  'ups': 1, 
  '_fetched': True
}
```

a reply object has the following data:
```
{
  '_replies': <praw.models.comment_forest.CommentForest object at 0x000001AD6D6D5BD0>, 
  '_submission': Submission(id='1nxh184'), 
  '_reddit': <praw.reddit.Reddit object at 0x000001AD6CF27850>, 
  'subreddit_id': 't5_2qjov', 
  'approved_at_utc': None, 
  'author_is_blocked': False, 
  'comment_type': None, 
  'awarders': [], 
  'mod_reason_by': None, 
  'banned_by': None, 
  'author_flair_type': 'text', 
  'total_awards_received': 0, 
  'subreddit': Subreddit(display_name='Philippines'), 
  'author_flair_template_id': None, 
  'likes': None, 
  'user_reports': [], 
  'saved': False, 
  'id': 'nho3qjz', 
  'banned_at_utc': None, 
  'mod_reason_title': None, 
  'gilded': 0, 
  'archived': False, 
  'collapsed_reason_code': None, 
  'no_follow': False, 
  'author': Redditor(name='staleferrari'), 
  'can_mod_post': False, 
  'created_utc': 1759553476.0, 
  'send_replies': True, 
  'parent_id': 't1_nhnfvu8', 
  'score': 1, 
  'author_fullname': 't2_49e5v4z4', 
  'removal_reason': None, 
  'approved_by': None, 
  'mod_note': None, 
  'all_awardings': [], 
  'body': 'Gabilat', 
  'edited': False, 
  'top_awarded_type': None, 
  'author_flair_css_class': None, 
  'name': 't1_nho3qjz', 
  'is_submitter': False, 
  'downs': 0, 
  'author_flair_richtext': [], 
  'author_patreon_flair': False, 
  'body_html': '<div class="md"><p>Gabilat</p>\n</div>', 
  'gildings': {}, 
  'collapsed_reason': None, 
  'distinguished': None, 
  'associated_award': None, 
  'stickied': False, 
  'author_premium': False, 
  'can_gild': False, 
  'link_id': 't3_1nxh184', 
  'unrepliable_reason': None, 
  'author_flair_text_color': None, 
  'score_hidden': True, 
  'permalink': '/r/Philippines/comments/1nxh184/this_flood_level_indicator/nho3qjz/', 
  'subreddit_type': 'public', 
  'locked': False, 
  'report_reasons': None, 
  'created': 1759553476.0, 
  'author_flair_text': None, 
  'treatment_tags': [], 
  'collapsed': False, 
  'subreddit_name_prefixed': 'r/Philippines', 
  'controversiality': 0, 
  'depth': 1, 
  'author_flair_background_color': None, 
  'collapsed_because_crowd_control': None, 
  'mod_reports': [], 
  'num_reports': None, 
  'ups': 1, 
  '_fetched': True
}
```


* with the youtube api if you want to interact with youtube's client interface with your account you will need to create instead an OAuth2 client id kind of like with reddit, but if you're interacting with youtube with no account then just the API key is enough

* a single `item` of the `response` object returned from `youtube.commentThreads().list(**params).execute()` contains the ff:
```
{'etag': 'aHTTcyKom34kuM7FUJwIwmvhH4s',
  'id': 'UgxobbYFW5QNK-WFcNF4AaABAg',
  'kind': 'youtube#commentThread',
  'replies': {
    'comments': [ # these are the replies to the top level comment found
      {
        'etag': 'AIOuAJxmbBzRJ9s2le8VsLT6_gY',
        'id': 'UgxobbYFW5QNK-WFcNF4AaABAg.9s4V-mdzLq79s5enfTdY8b',
        'kind': 'youtube#comment',
        'snippet': {
          'authorChannelId': {
            'value': 'UCaizTs-t-jXjj8H0-S3ATYA'
          },
          'authorChannelUrl': 'http://www.youtube.com/@analyticswithadam',
          'authorDisplayName': '@analyticswithadam',
          'authorProfileImageUrl': 'https://yt3.ggpht.com/2PBxLW_kGCY1hfybNHu216RHGBDBNZW4m7aS9kU2Lj_6waMwDMmDrGGEg6zJsYuAq63nDtNd=s48-c-k-c0x00ffffff-no-rj',
          'canRate': True,
          'channelId': 'UCaizTs-t-jXjj8H0-S3ATYA',
          'likeCount': 0,
          'parentId': 'UgxobbYFW5QNK-WFcNF4AaABAg',
          'publishedAt': '2023-07-13T06:26:01Z',
          'textDisplay': 'Glad it was useful',
          'textOriginal': 'Glad it was useful',
          'updatedAt': '2023-07-13T06:26:01Z',
          'videoId': 'SIm2W9TtzR0',
          'viewerRating': 'none'
        }
      },
      {
        'etag': 'nsigOsdXr79YDN2WHK4gwJXAR7k',
        'id': 'UgxobbYFW5QNK-WFcNF4AaABAg.9s4V-mdzLq7AOXiT2PhrVd',
        'kind': 'youtube#comment',
        'snippet': {
          'authorChannelId': {
            'value': 'UCA_EdNiC9bUaQsbTT3-YsAg'
          },
          'authorChannelUrl': 'http://www.youtube.com/@JennaHasm',
          'authorDisplayName': '@JennaHasm',
          'authorProfileImageUrl': 'https://yt3.ggpht.com/WUm40JH_Uqb4dYhjx6jYFBQzJHmwEMOFYPxLvHLLwo-1_5aISu5XaISbB84S7IYZG4Y0afJEyQ=s48-c-k-c0x00ffffff-no-rj',
          'canRate': True,
          'channelId': 'UCaizTs-t-jXjj8H0-S3ATYA',
          'likeCount': 0, 
          'parentId': 'UgxobbYFW5QNK-WFcNF4AaABAg',
          'publishedAt': '2025-10-21T09:12:46Z',
          'textDisplay': '\u200b@analyticswithadam<br>Do '
                        'you know why youtube '
                        'rewards (monetarely) '
                        'channel owners that '
                        'create distructive '
                        'content instead of '
                        'channel owners like '
                        'yours for example. From '
                        'what O noticed it&#39;s '
                        'not the niche topic '
                        'that is the problem, '
                        'it&#39;s ... rewarding '
                        'the worst of '
                        'humans.<br>It '
                        'doesn&#39;t make a lot '
                        'of sense to me.',
          'textOriginal': '\u200b@analyticswithadam\n'
                          'Do you know why '
                          'youtube rewards '
                          '(monetarely) channel '
                          'owners that create '
                          'distructive content '
                          'instead of channel '
                          'owners like yours for '
                          'example. From what O '
                          "noticed it's not the "
                          'niche topic that is '
                          "the problem, it's ... "
                          'rewarding the worst of '
                          'humans.\n'
                          "It doesn't make a lot "
                          'of sense to me.',
          'updatedAt': '2025-10-21T09:12:46Z',
          'videoId': 'SIm2W9TtzR0', # this is that youtube video's vidoeId
          'viewerRating': 'none'
        }
      }
    ]
  },
 'snippet': {
    'canReply': True,
    'channelId': 'UCaizTs-t-jXjj8H0-S3ATYA',
    'isPublic': True,
    'topLevelComment': {
      'etag': '81lATGyrrx6iL2m58jTqimCH7bs',
      'id': 'UgxobbYFW5QNK-WFcNF4AaABAg',
      'kind': 'youtube#comment',
      'snippet': {
        'authorChannelId': {
          'value': 'UCAeABcbzXpqZ9ELNznsqRBg'
        },
        'authorChannelUrl': 'http://www.youtube.com/@oraclesql',
        'authorDisplayName': '@oraclesql',
        'authorProfileImageUrl': 'https://yt3.ggpht.com/FVtbQGQrlS_QWV1bAMc-wZ9vUd1lKKix4yN3wtFE2N07-qdYjakorpSSk8u11Q-NQ5JIq7hl=s48-c-k-c0x00ffffff-no-rj',
        'canRate': True,
        'channelId': 'UCaizTs-t-jXjj8H0-S3ATYA',
        'likeCount': 1,
        'publishedAt': '2023-07-12T19:32:27Z',
        'textDisplay': 'Thank you for '
                      'this Adam. Great '
                      'tuorial',
        'textOriginal': 'Thank you for '
                        'this Adam. Great '
                        'tuorial',
        'updatedAt': '2023-07-12T19:32:27Z',
        'videoId': 'SIm2W9TtzR0',
        'viewerRating': 'none'
      }
    },
    'totalReplyCount': 2,
    'videoId': 'SIm2W9TtzR0'
  }
}
```

this is because we set the params of the `commentThreads()` resource method `.list()` to `{"part": ",".join(["snippet", "replies"]), "videoId": "SIm2W9TtzR0", "maxResults": 100}` where the `part` key is a string of comma separated values that indicate what parts of the resulting request we only want to include, which in this case we only set to snippet and replies, but for specific resources of the youtube API like videos, comments, search requests, channels, etc. For instance a video resource has the following keys/parts when the resulting dictionary object from the request is returned: snippet, contentDetails, fileDetails, player, processingDetails, recordingDetails, statistics, status, suggestions, topicDetails. With these options we can specify only in the part parameter of our `list()`, `insert()`, `delete()` methods to return only the keys we need. so if we need all results our `part` param will be set to `"snippet, contentDetails, fileDetails, player, processingDetails, recordingDetails, statistics, status, suggestions, topicDetails"`

* a 
```
{
  'contentDetails': { # WE NEED CONTENT DETAILS AS THIS CONTAINS INFORMATION ABOUT DURATION OF VIDEO e.g. duration which is an ISO 8601 string. PT stands for Time Duration, 3M is 3 minutes, and 19S is 19 seconds, that we can use if video is long form content and determine how many people watch long form content
    'caption': 'false',
    'contentRating': {},
    'definition': 'hd',
    'dimension': '2d',
    'duration': 'PT3M19S',
    'licensedContent': False,
    'projection': 'rectangular'
  },
 'etag': 'QgvLF32RrMhZKtnKcDWfZnec8qs',
 'id': 'yebNIHKAC4A', #id of video
 'kind': 'youtube#video',
 'localizations': {
    'en': {
      'description': 'We’re going up, up, up. Watch the '
        'official lyric video for “Golden” '
        'from KPop Demon Hunters. KPop Demon '
        'Hunters is now on Netflix. \n'
        '\n'
        'Listen to the KPop Demon Hunters '
        'soundtrack here: '
        'https://kpopdemonhunters.lnk.to/Soundtrack \n'
        '\n'
        'About KPop Demon Hunters: \n'
        "When they aren't selling out "
        'stadiums, KPop superstars Rumi, Mira '
        'and Zoey use their secret identities '
        'as badass demon hunters to protect '
        'their fans from an ever-present '
        'supernatural threat. Together, they '
        'must face their biggest enemy yet – '
        'an irresistible rival boy band of '
        'demons in disguise.\n'
        '\n'
        'Directed by: Maggie Kang and Chris '
        'Appelhans\n'
        'Produced by: Michelle Wong\n'
        'Co-Produced by: Scott Berri, Jacky '
        'Priddle\n'
        'Cast: Arden Cho, Ahn Hyo-seop, May '
        'Hong, Ji-young Yoo, Yunjin Kim, Joel '
        'Kim Booster, Liza Koshy, with Daniel '
        'Dae Kim, Ken Jeong and Byung Hun '
        'Lee.\n'
        '\n'
        'Subscribe to the Sony Animation '
        'YouTube channel here: '
        'https://bit.ly/2SGtGHU \n'
        '\n'
        'Follow Sony Animation on Social:\n'
        'TikTok: '
        'https://www.tiktok.com/@sonypicturesanimation \n'
        'Twitter: '
        'https://twitter.com/SonyAnimation \n'
        'Instagram: '
        'https://www.instagram.com/sonyanimation/ \n'
        'Facebook: '
        'https://www.facebook.com/SonyPicturesAnimation/\n'
        '\n'
        '#SonyAnimation #Netflix #KPop\n'
        '\n'
        '“Golden” Official Lyric Video | KPop '
        'Demon Hunters | Sony Animation\n'
        'https://www.youtube.com/user/SonyAnimation', # full description of video
      'title': '“Golden” Official Lyric Video | KPop Demon ''Hunters Sony Animation' # full title of video
    } 
  },
 'paidProductPlacementDetails': {
    'hasPaidProductPlacement': False
  },
 'player': {
    'embedHtml': '<iframe width="480" height="270" '
      'src="//www.youtube.com/embed/yebNIHKAC4A" '
      'frameborder="0" allow="accelerometer; autoplay; '
      'clipboard-write; encrypted-media; gyroscope; '
      'picture-in-picture; web-share" '
      'referrerpolicy="strict-origin-when-cross-origin" '
      'allowfullscreen></iframe>'
  },
 'recordingDetails': {},
 'snippet': {
    'categoryId': '1',
    'channelId': 'UCnLuLSV-Oi0ctqjxGgxFlmg', # id of the channel that made the vidoe
    'channelTitle': 'Sony Pictures Animation', # title fo the channel that made the video
    'defaultAudioLanguage': 'en-US',
    'defaultLanguage': 'en',
    'description': 'We’re going up, up, up. Watch the official lyric '
      'video for “Golden” from KPop Demon Hunters. KPop '
      'Demon Hunters is now on Netflix. \n'
      '\n'
      'Listen to the KPop Demon Hunters soundtrack here: '
      'https://kpopdemonhunters.lnk.to/Soundtrack \n'
      '\n'
      'About KPop Demon Hunters: \n'
      "When they aren't selling out stadiums, KPop "
      'superstars Rumi, Mira and Zoey use their secret '
      'identities as badass demon hunters to protect '
      'their fans from an ever-present supernatural '
      'threat. Together, they must face their biggest '
      'enemy yet – an irresistible rival boy band of '
      'demons in disguise.\n'
      '\n'
      'Directed by: Maggie Kang and Chris Appelhans\n'
      'Produced by: Michelle Wong\n'
      'Co-Produced by: Scott Berri, Jacky Priddle\n'
      'Cast: Arden Cho, Ahn Hyo-seop, May Hong, Ji-young '
      'Yoo, Yunjin Kim, Joel Kim Booster, Liza Koshy, '
      'with Daniel Dae Kim, Ken Jeong and Byung Hun '
      'Lee.\n'
      '\n'
      'Subscribe to the Sony Animation YouTube channel '
      'here: https://bit.ly/2SGtGHU \n'
      '\n'
      'Follow Sony Animation on Social:\n'
      'TikTok: '
      'https://www.tiktok.com/@sonypicturesanimation \n'
      'Twitter: https://twitter.com/SonyAnimation \n'
      'Instagram: '
      'https://www.instagram.com/sonyanimation/ \n'
      'Facebook: '
      'https://www.facebook.com/SonyPicturesAnimation/\n'
      '\n'
      '#SonyAnimation #Netflix #KPop\n'
      '\n'
      '“Golden” Official Lyric Video | KPop Demon '
      'Hunters | Sony Animation\n'
      'https://www.youtube.com/user/SonyAnimation', # FULL DESCRIPTION OF VIDEO
    'liveBroadcastContent': 'none',
    'localized': {
      'description': 'We’re going up, up, up. Watch the '
        'official lyric video for “Golden” '
        'from KPop Demon Hunters. KPop Demon '
        'Hunters is now on Netflix. \n'
        '\n'
        'Listen to the KPop Demon Hunters '
        'soundtrack here: '
        'https://kpopdemonhunters.lnk.to/Soundtrack \n'
        '\n'
        'About KPop Demon Hunters: \n'
        "When they aren't selling out "
        'stadiums, KPop superstars Rumi, '
        'Mira and Zoey use their secret '
        'identities as badass demon hunters '
        'to protect their fans from an '
        'ever-present supernatural threat. '
        'Together, they must face their '
        'biggest enemy yet – an irresistible '
        'rival boy band of demons in '
        'disguise.\n'
        '\n'
        'Directed by: Maggie Kang and Chris '
        'Appelhans\n'
        'Produced by: Michelle Wong\n'
        'Co-Produced by: Scott Berri, Jacky '
        'Priddle\n'
        'Cast: Arden Cho, Ahn Hyo-seop, May '
        'Hong, Ji-young Yoo, Yunjin Kim, '
        'Joel Kim Booster, Liza Koshy, with '
        'Daniel Dae Kim, Ken Jeong and Byung '
        'Hun Lee.\n'
        '\n'
        'Subscribe to the Sony Animation '
        'YouTube channel here: '
        'https://bit.ly/2SGtGHU \n'
        '\n'
        'Follow Sony Animation on Social:\n'
        'TikTok: '
        'https://www.tiktok.com/@sonypicturesanimation \n'
        'Twitter: '
        'https://twitter.com/SonyAnimation \n'
        'Instagram: '
        'https://www.instagram.com/sonyanimation/ \n'
        'Facebook: '
        'https://www.facebook.com/SonyPicturesAnimation/\n'
        '\n'
        '#SonyAnimation #Netflix #KPop\n'
        '\n'
        '“Golden” Official Lyric Video | '
        'KPop Demon Hunters | Sony '
        'Animation\n'
        'https://www.youtube.com/user/SonyAnimation', # FULL DESCRIPTION OF VIDEO
      'title': '“Golden” Official Lyric Video | KPop ''Demon Hunters | Sony Animation' # FULL TITLE OF VIDEO
    },
    'publishedAt': '2025-06-23T22:30:00Z', # NEED THIS TIMESTAMP
    'tags': [ # NEED THESE TAGS FOR TOPIC MODELLING
      'Sony Pictures Animation',
      'Sony Animation',
      'Sony Pictures Imageworks',
      'Imageworks',
      'Netflix',
      'K-Pop',
      'KPop',
      'Anime',
      'KDrama',
      'Huntrix',
      'Saja Boys',
      'Idol',
      'Korea',
      'Korean',
      'Jeongyeon',
      'Jihyo',
      'Chaeyoung',
      'Golden',
      'KPop Demon Hunters'
    ],
    'thumbnails': {
      'default': {
        'height': 90,
        'url': 'https://i.ytimg.com/vi/yebNIHKAC4A/default.jpg',
        'width': 120
      },
      'high': {
        'height': 360,
        'url': 'https://i.ytimg.com/vi/yebNIHKAC4A/hqdefault.jpg',
        'width': 480
      },
      'maxres': {
        'height': 720,
        'url': 'https://i.ytimg.com/vi/yebNIHKAC4A/maxresdefault.jpg',
        'width': 1280
      },
      'medium': {
        'height': 180,
        'url': 'https://i.ytimg.com/vi/yebNIHKAC4A/mqdefault.jpg',
        'width': 320
      },
      'standard': {
        'height': 480,
        'url': 'https://i.ytimg.com/vi/yebNIHKAC4A/sddefault.jpg',
        'width': 640
      }
    },
    'title': '“Golden” Official Lyric Video | KPop Demon Hunters | ''Sony Animation' # FULL TITLE OF VIDEO
  },
  'statistics': { # STATISTICS THAT WE NEED FOR THE VIDEO THAT CONTAIN QUANTIFIABLE TRANSACTION DATA
    'commentCount': '151804',
    'favoriteCount': '0',
    'likeCount': '4957377',
    'viewCount': '855315952'
  },
  'status': {
    'embeddable': True,
    'license': 'youtube',
    'madeForKids': False, # WE MIGHT NEED THIS TO DETERMINE HOW MANY OF THE VIDEOS ARE MADE FOR ADULTS
    'privacyStatus': 'public',
    'publicStatsViewable': True,
    'uploadStatus': 'processed'
  },
  'topicDetails': { # WE DON'T NEED THIS MUCH
    'topicCategories': [
      'https://en.wikipedia.org/wiki/Music',
      'https://en.wikipedia.org/wiki/Music_of_Asia',
      'https://en.wikipedia.org/wiki/Pop_music'
    ]
  }
}
```


* for youtube api these are the resources that we can list, insert, update, and delete
```
+--------------------+--------+--------+--------+--------+
| resource           | list   | insert | update | delete |
+--------------------+--------+--------+--------+--------+
| activity           | ✔      | ❌    | ❌     | ❌    |
| caption            | ✔      | ✔     | ✔      | ✔     |
| channel            | ✔      | ❌    | ❌     | ❌    |
| channelBanner      | ❌     | ✔     | ❌     | ❌    |
| channelSection     | ✔      | ✔     | ✔      | ✔     |
| comment            | ✔      | ✔     | ✔      | ✔     |
| commentThread      | ✔      | ✔     | ✔      | ❌    |
| guideCategory      | ❌     | ❌      ❌     | ❌    |
| i18nLanguage       | ✔      | ❌    | ❌     | ❌    |
| i18nRegion         | ✔      | ❌    | ❌     | ❌    |
| playlist           | ✔      | ✔     | ✔      | ✔     |
| playlistItem       | ✔      | ✔     | ✔      | ✔     |
| search result      | ✔      | ❌    | ❌     | ❌    |
| subscription       | ✔      | ❌    | ❌     | ❌    |
| thumbnail          | ❌     | ❌    | ❌     | ❌    |
| video              | ✔      | ✔     | ✔      | ✔     |
| videoCategory      | ✔      | ❌    | ❌     | ❌    |
| watermark          | ❌     | ❌    | ❌     | ❌    |
+--------------------+--------+--------+--------+--------+
```

* The result of a youtube.search.list(**params).execute() is:
```
{
  'etag': 'rMvyctcNvzzd_ozmjXnrJ6FORhY',
  'id': {
    'kind': 'youtube#video', 
    'videoId': 'XPqQoQqejCc'
  },
  'kind': 'youtube#searchResult',
  'snippet': {
    'channelId': 'UCPE_UIuGbfeZSEnFE1WI-Gg',
    'channelTitle': 'Untitled Joker',
    'description': 'We hope you have a good time with our videos, and '
                  'you are welcome to subscribe to our channel！！ Our '
                  'video production team ...',
    'liveBroadcastContent': 'none',
    'publishTime': '2025-09-11T15:03:26Z',
    'publishedAt': '2025-09-11T15:03:26Z',
    'thumbnails': {
      'default': {
        'height': 90,
        'url': 'https://i.ytimg.com/vi/XPqQoQqejCc/default.jpg',
        'width': 120
      },
      'high': {
        'height': 360,
        'url': 'https://i.ytimg.com/vi/XPqQoQqejCc/hqdefault.jpg',
        'width': 480
      },
      'medium': {
        'height': 180,
        'url': 'https://i.ytimg.com/vi/XPqQoQqejCc/mqdefault.jpg',
        'width': 320
      }
    },
    'title': 'True and False K-Pop: Demon Hunters#joker  #kpop'}}
```

or

{
  'etag': 'N8YyyIG6opwGxoLWDCw7hWqQe-8',
  'id': {
    'kind': 'youtube#video', 
    'videoId': 'yebNIHKAC4A' # THIS IS WHAT WE WANT
  },
  'kind': 'youtube#searchResult',
  'snippet': {
    'channelId': 'UCnLuLSV-Oi0ctqjxGgxFlmg',
    'channelTitle': 'Sony Pictures Animation',
    'description': "We're going up, up, up. Watch the official lyric "
                    'video for “Golden” from KPop Demon Hunters. KPop '
                    'Demon Hunters is now on ...', # THIS IS BUT A SNIPPET OF THE VIDEO DESCRIPTION NOT THE FULL
    'liveBroadcastContent': 'none',
    'publishTime': '2025-06-23T22:30:00Z',
    'publishedAt': '2025-06-23T22:30:00Z',
    'thumbnails': {
      'default': {
        'height': 90,
        'url': 'https://i.ytimg.com/vi/yebNIHKAC4A/default.jpg',
        'width': 120
      },
      'high': {
        'height': 360,
        'url': 'https://i.ytimg.com/vi/yebNIHKAC4A/hqdefault.jpg',
        'width': 480
      },
      'medium': {
        'height': 180,
        'url': 'https://i.ytimg.com/vi/yebNIHKAC4A/mqdefault.jpg',
        'width': 320
      }
    },
    'title': '“Golden” Official Lyric Video | KPop Demon Hunters | ' 'Sony Animation'
  }
}

* `returned "The request cannot be completed because you have exceeded your <a href="/youtube/v3/getting-started#quota">quota</a>.". Details: "[{'message': 'The request cannot be completed because you have exceeded your <a href="/youtube/v3/getting-started#quota">quota</a>.', 'domain': 'youtube.quota', 'reason': 'quotaExceeded'}]">` is something that needs a workaround

Quota impact: A call to this commentThreads().list() method has a quota cost of 1 unit.
Quota impact: A call to this videos().list() method has a quota cost of 1 unit.
Quota impact: A call to this search().list() method has a quota cost of 100 units.

and and according to the [youtube data api docs](https://developers.google.com/youtube/v3/getting-started) a read operation that retrieves a list of resources -- channels, videos, playlists -- usually costs 1 unit, a write operation that creates, updates, or deletes a resource usually has costs 50 units, a search request costs 100 units, and a video upload costs 100 units.


That 403 error with the quota message and the huge discrepancy in limits (10,000 vs. 1,800,000) is due to the YouTube Data API's tiered quota system—specifically, the difference between your Daily Limit and a much larger Per Minute/Per User Limit.

The error means you have exhausted your primary daily budget, and the larger number you see is for a different, secondary limit that is currently irrelevant.

🛑 Interpreting the Quota Limits
1. The Limit You Hit: The Daily Quota (10,000 Units)
Your primary limit is the Daily Quota, which is set at a default of 10,000 units per Google Cloud project.

Every API call, even if invalid, consumes "units" from this pool.

The cost of each call varies greatly:

Simple Reads (e.g., fetching video/channel details: videos.list): 1 unit.

Fetching Comments (comments.list): 1 unit per 100 comments fetched.

Searches (search.list): 100 units.

When you hit the 10,000-unit ceiling, the API returns the 403 error (quotaExceeded), and your application is blocked until the quota resets at midnight Pacific Time (PT).

2. The Limit You Saw: Queries Per Minute (QPM) (1,800,000 Units)
The much larger number you're seeing (e.g., 1,800,000) is likely your Queries Per Minute (QPM) or Queries Per Minute Per User limit.

This limit dictates the maximum speed at which you can make requests if you had enough daily units.

Why it's useless now: Since your Daily Limit (10,000) is so much smaller than the QPM limit, the QPM limit effectively never comes into play. You cannot possibly use 1.8 million units per minute if your total daily budget is only 10,000 units.

💡 How to Fix and Optimize Your Scraping
The most common reason for hitting the 10,000-unit limit quickly, especially in a scraping project, is heavy reliance on the Search endpoint.

Reduce search.list: Every time you use search.list to find videos by keyword, you spend 100 units. If you run 100 searches, you've used your entire daily quota!

Optimization: Look for Channel IDs and use playlistItems.list instead, which usually costs only 1 unit to fetch a list of videos from a channel's uploads.

Use Batching and Part Parameters:

Batching: Request details for multiple resources (like 50 videos) in a single API call where possible. This costs 1 unit total, rather than 50 units for 50 separate calls.

Partial Resources: Use the part parameter (e.g., part=snippet,statistics) to retrieve only the fields you absolutely need. This reduces latency and bandwidth, though it may not always save quota units.

Caching: Implement an application-level cache. For static content like video titles and descriptions, cache the data for 24 hours. For dynamic data like view counts, cache for a few hours.

Request a Quota Increase: Since your project is part of a larger, defined MLOps pipeline, you have a strong justification to request an increase. You must fill out the Audit and Quota Extension Form and provide a detailed arithmetic calculation justifying your required daily quota. Quota increases are typically free.

For more details on managing your API usage and dealing with the quota system, watch Using Google's YouTube Data API v3 and Exceeded Your Quota? w/Python Build an Easy Workaround System. This video provides tips on implementing a workaround system when you encounter the quota exceeded error.


## AWS, Snowflake Cloud Infrastructure
* to setup aws infrastructure using terraform with we need to first configure our aws credentia ls terraform will need to authenticate to our aws account to setup our infrastructure. But first we need to create a IAM role/user, so we need to go to our account and create one there and assign a policy to it directly dpeending on what service we want this IAM role/user to have access to and ultimately what terraform has access to since it uses this IAM role/user credential. So we create a user and create its access key and copy its access key id and secret access key. Next assuming we have aws cli installed we run `aws configure` and there we will be prompted to enter our aws access key id and aws secret access key which we copied earlier when we created our access keys for our IAM user. Then we just enter the region to which we want and we're all set. If we run terraform init, terraform fmt, terraform apply, then we will have this resource/service set up in our account easily, depending what services we only allowed our IAM user to setup, e.g. if we only created a credential to setup an s3 bucket then terraform will only be allowed to create this service and nothing more

* I need someway to automatically using terraform. This will include using snowflake and aws providers 
- initially create an IAM role
- initially create an IAM policy with permissions to get and list s3 buckets and objects
- attach the policy to the created IAM role

- create db
- create schema

- create `STORAGE INTEGRATION`
- set the storage integration's `STORAGE_AWS_ROLE_ARN` to the value of the newly created IAM role
- use the output of `DESCRIBE STORAGE INTEGRATION <name of storage integration>` such as `STORAGE_AWS_IAM_USER_ARN` and `STORAGE_AWS_EXTERNAL_ID` and copy it to IAM role trusted entities' principal `AWS` and `externalId` keys as values respectively
- create `EXTERNAL VOLUME`
- set the external volume's `STORAGE_AWS_ROLE_ARN` to the value of the newly created IAM role 
- use the output of `DESCRIBE EXTERNAL VOLUME <name of external volume>` such as `STORAGE_AWS_IAM_USER_ARN` and `STORAGE_AWS_EXTERNAL_ID` and copy it to IAM role trusted entities' principal `AWS` and `externalId` keys as values respectively

- create a `FILE FORMAT` with type parquet
- create an external stage with `FILE_FORMAT` set to the created file format and the `STORAGE_INTEGRATION` to the name of the newly created storage integration

- create a `CATALOG INTEGRATION`
- create an `ICEBERG TABLE` with `CATALOG` set to the newly created catalog integration, the `EXTERNAL_VOLUME` to the newly created external volume, the `BASE_LOCATION` to the name of the delta folder in your s3 bucket 

## Errors
* The annoying error of 
```
#9 116.2 error: Failed to fetch: `https://pip.astronomer.io/v2/astro-run-dag/`
#9 116.2   Caused by: Request failed after 3 retries
#9 116.2   Caused by: error sending request for url (https://pypi.org/simple/astro-run-dag/)
#9 116.2   Caused by: operation timed out
#9 ERROR: process "/bin/bash -o pipefail -e -u -x -c /usr/local/bin/install-python-dependencies" did not complete successfully: exit code: 2
```
or
```
115.0 error: Failed to fetch: `https://pip.astronomer.io/v2/python-dotenv/`
115.0   Caused by: Request failed after 3 retries
115.0   Caused by: error sending request for url (https://pypi.org/simple/python-dotenv/)
115.0   Caused by: operation timed out
```

can potentially be solved by adding this to the `Dockerfile`: `pip install -r requirements.txt --trusted-host pypi.python.org` instead of only `pip install -r requirements.txt` as astronomer pulls the packages/dependenceis we need from different url like `pypi.org`: https://stackoverflow.com/questions/16370583/pip-issue-installing-almost-any-library

ganun rin sa kabilang stream-data-analyses project
```
WARNING: Retrying (Retry(total=4, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.HTTPSConnection object at 0x76742e292450>: Failed to establish a new connection: [Errno 101] Network is unreachable')': /simple/pip/
```
whicy I feel like is again a `error sending request for url (https://pypi.org/simple/<python package>/)`

if all else fails what then?

Well it could be erraticity of internet connection:
```
WARNING: Retrying (Retry(total=4, connect=None, read=None, redirect=None, status=None)) after connection broke

 => => # n by 'NewConnectionError('<pip._vendor.urllib3.connection.HTTPSConnection object at 0x7c3e97697b90>: Failed to

[+] Building 0/1ish a new connection: [Errno 101] Network is unreachable')' 
```
Kasi ganto rin sa isa kong docker container project. Could this be a problem with our internet connection. Kasi Yes may wifi kami but at this time medyo erratic siya. I kind of have the feeling that the reason why these errors are appearing and why network is unreachable is because of this wifi

You are almost certainly correct. The error message you provided—Failed to establish a new connection: [Errno 101] Network is unreachable—is the textbook indication of a failure in your local network connection or a major firewall block.

Here's why your unstable Wi-Fi is the prime suspect and how it relates to your Docker builds:

🎯 Diagnosis: Wi-Fi Intermittency
The error chain you're seeing confirms a local network issue:

`WARNING: Retrying (Retry(total=4, ...)): Pip/Docker is trying multiple times to reach the destination (PyPI/public internet), which is standard practice for intermittent issues.`

Connection broke: The existing connection was suddenly terminated.

Failed to establish a new connection: [Errno 101] Network is unreachable: This is a core network error code. It means that the computer (or the Docker container attempting to use the host's network) cannot find a route to the destination IP address. The request isn't even making it to the router reliably.

When your Wi-Fi is "erratic":

During a Docker build, the container attempts to download large packages sequentially.

If your Wi-Fi drops out, even for a few seconds, the connection attempt is terminated immediately, leading to the "connection broke" and "Network is unreachable" errors.

Since the build process needs many reliable connections to download hundreds of megabytes of packages, unstable Wi-Fi makes a successful build extremely difficult.

**you could use `docker system prune --all --volumes`**

**you could also try the ff. to see if the problem is the internet because if it isn't the problem lies with the pip docker is installing in the container or docker itself**
```
(base) C:\Users\LARRY\Documents\Scripts>ping <ip address of router>

Pinging <ip address of router> with 32 bytes of data:
Reply from <ip address of router>: bytes=32 time<1ms TTL=128
Reply from <ip address of router>: bytes=32 time<1ms TTL=128
Reply from <ip address of router>: bytes=32 time<1ms TTL=128
Reply from <ip address of router>: bytes=32 time<1ms TTL=128

Ping statistics for <ip address of router>:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),
Approximate round trip times in milli-seconds:
    Minimum = 0ms, Maximum = 0ms, Average = 0ms

(base) C:\Users\LARRY\Documents\Scripts>ping google.com

Pinging google.com [2404:6800:4017:803::200e] with 32 bytes of data:
Reply from 2404:6800:4017:803::200e: time=7ms
Reply from 2404:6800:4017:803::200e: time=6ms
Reply from 2404:6800:4017:803::200e: time=6ms
Reply from 2404:6800:4017:803::200e: time=8ms

Ping statistics for 2404:6800:4017:803::200e:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),
Approximate round trip times in milli-seconds:
    Minimum = 6ms, Maximum = 8ms, Average = 6ms

(base) C:\Users\LARRY\Documents\Scripts>
```

**Others say it is beacuse of disabled firewall in windows so you cneed to enable it**

THESE ARE YOUR EXACT PROBLEMS:`
https://stackoverflow.com/questions/52815784/python-pip-raising-newconnectionerror-while-installing-libraries:
https://stackoverflow.com/questions/67138344/python-pip-raising-newconnectionerror-while-installing-django-braces

https://forums.docker.com/t/issue-with-installing-pip-packages-inside-a-docker-container-with-ubuntu/35107/2

https://github.com/docker/for-win/issues/14667

https://medium.com/@skakella/docker-build-pip-install-errors-f688229b090c
https://stackoverflow.com/questions/27435479/pass-net-host-to-docker-build

https://forums.docker.com/t/containers-pip-cant-access-local-pypi-server/132708/8

all these problems were sovled when I uninstalled and reinstalled docker

* when I run my dbt dag it seems to throw this error even when the creation of the models goes well, specifically when it gets to tests for the first model: 
```
/usr/local/lib/python3.12/multiprocessing/resource_tracker.py:279: UserWarning: resource_tracker: There appear to be 2 leaked semaphore objects to clean up at shutdown source=task.stderr
[2025-10-27 10:44:52] ERROR -   warnings.warn('resource_tracker: There appear to be %d ' source=task.stderr
```

```
[2025-10-27 10:50:42] ERROR - Task failed with exception source=task loc=task_runner.py:994
CosmosDbtRunError: dbt invocation completed with errors: not_null_my_first_dbt_model_id: Got 1 result, configured to fail if != 0
File "/usr/local/lib/python3.12/site-packages/airflow/sdk/execution_time/task_runner.py", line 920 in run

File "/usr/local/lib/python3.12/site-packages/airflow/sdk/execution_time/task_runner.py", line 1307 in _execute_task

File "/usr/local/lib/python3.12/site-packages/airflow/sdk/bases/operator.py", line 416 in wrapper

File "/usr/local/lib/python3.12/site-packages/cosmos/operators/local.py", line 1089 in execute

File "/usr/local/lib/python3.12/site-packages/cosmos/operators/local.py", line 853 in build_and_run_cmd

File "/usr/local/lib/python3.12/site-packages/cosmos/operators/local.py", line 650 in run_command

File "/usr/local/lib/python3.12/site-packages/cosmos/operators/local.py", line 258 in handle_exception_dbt_runner

File "/usr/local/lib/python3.12/site-packages/cosmos/dbt/runner.py", line 113 in handle_exception_if_needed

[2025-10-27 10:50:42] ERROR - Top level error source=task loc=task_runner.py:1457
AirflowRuntimeError: API_SERVER_ERROR: {'status_code': 404, 'message': 'Not Found', 'detail': {'detail': 'Not Found'}}
File "/usr/local/lib/python3.12/site-packages/airflow/sdk/execution_time/task_runner.py", line 1452 in main

File "/usr/local/lib/python3.12/site-packages/airflow/sdk/execution_time/task_runner.py", line 1397 in finalize

File "/usr/local/lib/python3.12/site-packages/airflow/sdk/execution_time/comms.py", line 207 in send

File "/usr/local/lib/python3.12/site-packages/airflow/sdk/execution_time/comms.py", line 271 in _get_response

File "/usr/local/lib/python3.12/site-packages/airflow/sdk/execution_time/comms.py", line 258 in _from_frame

[2025-10-27 10:50:42] ERROR - /usr/local/lib/python3.12/multiprocessing/resource_tracker.py:279: UserWarning: resource_tracker: There appear to be 2 leaked semaphore objects to clean up at shutdown source=task.stderr
[2025-10-27 10:50:42] ERROR -   warnings.warn('resource_tracker: There appear to be %d ' source=task.stderr
```

* when we have credentials to pass in our terraform files we always have to run `terraform apply --var-file=<name of file containing our credentials/secrets e.g. credentials.tfvars>` or `terraform apply --var-file=<name of file containing our credentials/secrets e.g. credentials.tfvars>`

* now we may face `Error: creating IAM Policy (forum_analyses_ext_int_policy): operation error IAM: CreatePolicy, https response error StatusCode: 403, RequestID: b22be88c-ee2d-4763-86e5-fc686ec3d07b, api error AccessDenied: User: arn:aws:iam::xxxx:user/projects-terraform-infra-admin is not authorized to perform: iam:CreatePolicy on resource: policy forum_analyses_ext_int_policy because no identity-based policy allows the iam:CreatePolicy action` error this is because 

* ERRORs using terraform to manage snowflaek and aws infra:
`SELECT SYSTEM$VERIFY_EXTERNAL_VOLUME('forums_analyses_ext_vol');` will not run successfully
`SELECT SYSTEM$VERIFY_EXTERNAL_VOLUME('"forums_analyses_ext_vol"');` will run successfully

```
CREATE OR REPLACE ICEBERG TABLE raw_reddit_posts_comments
    CATALOG = delta_catalog_integration
    EXTERNAL_VOLUME = "forums_analyses_ext_vol"
    BASE_LOCATION = 'raw_reddit_posts_comments'
    AUTO_REFRESH = TRUE
WARNING: `002003 (02000): SQL compilation error:
External volume 'FORUMS_ANALYSES_EXT_VOL' does not exist or not authorized.` has occured.
```

even if `forums_analyses_ext_vol` already exists

```
LIST @sa_ext_stage_integration
WARNING: `003167 (42601): Error assuming AWS_ROLE:
User: arn:aws:iam::xxxx:user/xxxx-s is not authorized to perform: sts:AssumeRole on resource: arn:aws:iam::xxxx:role/forums-analyses-ext-int-role` has occured.
```

when I set write to true the allow_writes argument of external volume resource I was suddenly able to `LIST @sa_ext_stage_integration;` in snowflake and even in python using script 

however the result of `SELECT SYSTEM$VERIFY_EXTERNAL_VOLUME('"forums_analyses_ext_vol"')` returned now:
`"{""success"":false,""storageLocationSelectionResult"":""PASSED"",""storageLocationName"":""delta-ap-southeast-2"",""servicePrincipalProperties"":""STORAGE_AWS_IAM_USER_ARN: arn:aws:iam::xxxx:user/xxx-s; STORAGE_AWS_EXTERNAL_ID: YG61679_SFCRole=xxxx="",""location"":""s3://forums-analyses-bucket/"",""storageAccount"":null,""region"":""ap-southeast-2"",""writeResult"":""FAILED with exception message User: arn:aws:sts::<aws IAM role arn>:assumed-role/forums-analyses-ext-int-role/snowflake is not authorized to perform: s3:PutObject on resource: \""arn:aws:s3:::forums-analyses-bucket/verify_1762953386579_23029527\"" because no identity-based policy allows the s3:PutObject action (Status Code: 403; Error Code: AccessDenied)"",""readResult"":""SKIPPED"",""listResult"":""SKIPPED"",""deleteResult"":""SKIPPED"",""awsRoleArnValidationResult"":""PASSED"",""azureGetUserDelegationKeyResult"":""SKIPPED""}"`

```
USE forums_analyses_db;

USE forums_analyses_db.forums_analyses_bronze;

SELECT SYSTEM$VERIFY_EXTERNAL_VOLUME('"forums_analyses_ext_vol"');

CREATE FILE FORMAT IF NOT EXISTS pff
    TYPE = PARQUET;

CREATE OR REPLACE STAGE sa_ext_stage_integration
    STORAGE_INTEGRATION = "forums_analyses_si"
    URL = 's3://forums-analyses-bucket' -- Replace with your S3 bucket and folder path
    FILE_FORMAT = pff;

LIST @sa_ext_stage_integration;

--create the catalog integration for Delta tables 
CREATE CATALOG INTEGRATION IF NOT EXISTS delta_catalog_integration
    CATALOG_SOURCE = OBJECT_STORE
    TABLE_FORMAT = DELTA
    ENABLED = TRUE;

CREATE OR REPLACE ICEBERG TABLE raw_reddit_posts_comments
    CATALOG = delta_catalog_integration
    EXTERNAL_VOLUME = '"forums_analyses_ext_vol"'
    BASE_LOCATION = 'raw_reddit_posts_comments'
    AUTO_REFRESH = TRUE;

CREATE OR REPLACE ICEBERG TABLE raw_reddit_posts
    CATALOG = delta_catalog_integration
    EXTERNAL_VOLUME = '"forums_analyses_ext_vol"'
    BASE_LOCATION = 'raw_reddit_posts'
    AUTO_REFRESH = TRUE;

SELECT * FROM RAW_REDDIT_POSTS;
-- -- we can now just select from this table as 
-- -- if it were an existing table in snowflake because
-- -- mind you this table has not yet been created in our 
-- -- database schema
-- CREATE TABLE IF NOT EXISTS RawRedditData AS (
--     SELECT
--         $1:title::VARCHAR AS title,
--         $1:score::INTEGER AS score,
--         $1:id::VARCHAR AS id,
--         $1:url::VARCHAR AS url,
--         $1:comment::VARCHAR AS comment,
--         -- Add more columns as needed
--     FROM @sa_ext_stage_integration/raw_reddit_data.parquet
-- );
```

when I added PutObject and DeleteObject permissions to the policy `SELECT SYSTEM$VERIFY_EXTERNAL_VOLUME('"forums_analyses_ext_vol"')` returned `{"success":true,"storageLocationSelectionResult":"PASSED","storageLocationName":"delta-ap-southeast-2","servicePrincipalProperties":"STORAGE_AWS_IAM_USER_ARN: arn:aws:iam::058070818872:user/q8c91000-s; STORAGE_AWS_EXTERNAL_ID: YG61679_SFCRole=6_Jc+nu+t4KILVxharNSl8HMqrmMM=","location":"s3://forums-analyses-bucket/","storageAccount":null,"region":"ap-southeast-2","writeResult":"PASSED","readResult":"PASSED","listResult":"PASSED","deleteResult":"PASSED","awsRoleArnValidationResult":"PASSED","azureGetUserDelegationKeyResult":"SKIPPED"}` and when I replaced the name of the external volume from 'forums_analyses_ext_vol' to "forums_analyses_ext_vol" (which still didn't work) then finally to '"forums_analyses_ext_vol"' it finally worked but it throwed a new error which was more useful: `A test file creation on the external volume forums_analyses_ext_vol active storage location delta-ap-southeast-2 failed with the message 'Error assuming AWS_ROLE: User: arn:aws:iam::058070818872:user/q8c91000-s is not authorized to perform: sts:AssumeRole on resource: arn:aws:iam::612565766933:role/forums-analyses-ext-int-role'. Please ensure the external volume has privileges to write files to the active storage location. If read-only access is intended, set ALLOW_WRITES=false on the external volume. `

update: finally it worked when I used this:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "s3:PutObject",
              "s3:GetObject",
              "s3:GetObjectVersion",
              "s3:DeleteObject",
              "s3:DeleteObjectVersion"
            ],
            "Resource": "arn:aws:s3:::<bucket>/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::<bucket>",
            "Condition": {
                "StringLike": {
                    "s3:prefix": [
                        *"
                    ]
                }
            }
        }
    ]
}
```

as the policy document instead of just

```
{
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Statement1",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::forums-analyses-bucket",
          "arn:aws:s3:::forums-analyses-bucket/*"
        ]
      }
    ]
  }
```

and also the main solution was to use capital letters as strings in the terraform file
```
# databases
resource "snowflake_database" "forums_analyses_db" {
  name         = "FORUMS_ANALYSES_DB"
  is_transient = false
}

# schemas
resource "snowflake_schema" "forums_analyses_bronze" {
  name         = "FORUMS_ANALYSES_BRONZE"
  database     = snowflake_database.forums_analyses_db.name
  is_transient = false
}
```
because terraform will request snowflake to create this with this casing, so that it can be used and queried either using all caps or even just lowercase letters e.g. `SELECT * FROM forums_analyses_db.forums_analyses_bronze.<table>`

* run `terraform state rm <resource>.<name of resource>` to remove any potential resource that caused an error during terraform apply that may have been committed to the `terraform.tfstate` and `terraform.tfstate.backup`

sometimes `snowflake_grant_privileges_to_account_role.fa_database_allowed_roles` may raise a object does not exist or not authorized. Just make sure to create the snowflake resources and objects first before adding the line in your terraform file that grants privileges to your user to these objects

then just run `terraform apply --var-file=credentials.tfvars -auto-approve`

* dealing with a revoking privileges from account role error
``` 
snowflake_grant_privileges_to_account_role.fa_schema_allowed_roles: Destroying... [id="ACCOUNTADMIN"|true|true|ALL|OnSchema|OnSchema|"FORUMS_ANALYSES_DB"."FORUMS_ANALYSES_BRONZE"]
snowflake_storage_integration.forums_analyses_si: Destroying... [id=FORUMS_ANALYSES_SI]
snowflake_grant_privileges_to_account_role.fa_database_allowed_roles: Destroying... [id="ACCOUNTADMIN"|true|true|ALL|OnAccountObject|DATABASE|"FORUMS_ANALYSES_DB"]
snowflake_external_volume.forums_analyses_ext_vol: Destroying... [id=FORUMS_ANALYSES_EXT_VOL]
snowflake_storage_integration.forums_analyses_si: Destruction complete after 2s
snowflake_external_volume.forums_analyses_ext_vol: Destruction complete after 2s
╷
│ Error: An error occurred when revoking privileges from account role
│
│ Id: "ACCOUNTADMIN"|true|true|ALL|OnSchema|OnSchema|"FORUMS_ANALYSES_DB"."FORUMS_ANALYSES_BRONZE"
│ Account role name: "ACCOUNTADMIN"
│ Error: [errors.go:23] object does not exist or not authorized
╵
╷
│ Error: An error occurred when revoking privileges from account role
│
│ Id: "ACCOUNTADMIN"|true|true|ALL|OnAccountObject|DATABASE|"FORUMS_ANALYSES_DB"
│ Account role name: "ACCOUNTADMIN"
│ Error: [errors.go:23] object does not exist or not authorized
╵

(tech-interview) C:\Users\LARRY\Documents\Scripts\data-engineering-path\forums-analyses\infra>terraform state list
data.aws_caller_identity.current
data.aws_iam_policy_document.forums_analyses_bucket_access_policy
aws_iam_policy.forum_analyses_ext_int_policy
aws_iam_role.forum_analyses_ext_int_role
aws_iam_role_policy_attachment.faei_role_policy_attachment
aws_s3_bucket.forums_analyses_bucket
aws_s3_bucket_policy.forums_analyses_bucket_access_policy
aws_s3_bucket_public_access_block.example
snowflake_grant_privileges_to_account_role.fa_database_allowed_roles
snowflake_grant_privileges_to_account_role.fa_schema_allowed_roles

(tech-interview) C:\Users\LARRY\Documents\Scripts\data-engineering-path\forums-analyses\infra>terraform state rm snowflake_grant_privileges_to_account_role.fa_database_allowed_roles
Removed snowflake_grant_privileges_to_account_role.fa_database_allowed_roles
Successfully removed 1 resource instance(s).

(tech-interview) C:\Users\LARRY\Documents\Scripts\data-engineering-path\forums-analyses\infra>terraform state rm snowflake_grant_privileges_to_account_role.fa_schema_allowed_roles
Removed snowflake_grant_privileges_to_account_role.fa_schema_allowed_roles
Successfully removed 1 resource instance(s).

(tech-interview) C:\Users\LARRY\Documents\Scripts\data-engineering-path\forums-analyses\infra>terraform state rm snowflake_database.forums_analyses_db
╷
│ Error: Invalid target address
│
│ No matching objects found. To view the available instances, use "terraform state list". Please modify the address to
│ reference a specific instance.
╵


(tech-interview) C:\Users\LARRY\Documents\Scripts\data-engineering-path\forums-analyses\infra>terraform state list
data.aws_caller_identity.current
data.aws_iam_policy_document.forums_analyses_bucket_access_policy
aws_iam_policy.forum_analyses_ext_int_policy
aws_iam_role.forum_analyses_ext_int_role
aws_iam_role_policy_attachment.faei_role_policy_attachment
aws_s3_bucket.forums_analyses_bucket
aws_s3_bucket_policy.forums_analyses_bucket_access_policy
aws_s3_bucket_public_access_block.example
```

I totally feel your frustration. Moving to a new Snowflake account is like moving into a new house but your moving company (Terraform) thinks all your furniture is already there and is trying to move it around.

The reason it won't "just start from scratch" is that Terraform’s state file is a record of what it thinks exists. Because you are using the same state file for a brand-new Snowflake account, Terraform sees the grants in its memory, tries to talk to the new Snowflake account to "sync" them, and Snowflake basically says, "I don't know what you're talking about, that database doesn't exist."

Since your state file also contains AWS resources (S3 buckets, IAM roles) that probably do still exist, DO NOT delete your terraform.tfstate file. If you do, you'll lose track of your AWS stuff too.

Here is how to surgically wipe the Snowflake memory so you can start fresh.

The Fix: Surgically Remove Snowflake from State
You need to tell Terraform to "forget" the Snowflake resources without touching the AWS ones. Run these commands in your terminal:

Bash

# 1. Forget the database grant
terraform state rm snowflake_grant_privileges_to_account_role.fa_database_allowed_roles

# 2. Forget the schema grant
terraform state rm snowflake_grant_privileges_to_account_role.fa_schema_allowed_roles

# 3. Forget the database (though your JSON shows it's empty, run it to be safe)
terraform state rm snowflake_database.forums_analyses_db
What this does: It deletes those specific entries from your .json state file. It doesn't try to "revoke" anything in Snowflake. It just clears Terraform's memory.

Why the error is happening (Visualized)
When you run terraform apply now, Terraform sees:

State: "I have no record of a Snowflake database or grants."

Code: "User wants a Snowflake database and grants."

Action: It will issue a CREATE command instead of a REVOKE or UPDATE command.

One Last Check: Your Provider Configuration
Since you are on a new 120-day trial account, your Snowflake account URL/ID has changed. Make sure your provider "snowflake" block or your environment variables (SNOWFLAKE_ACCOUNT, etc.) are updated with the new account locator (the random string in your new URL).

If you don't update this, Terraform will keep trying to log into your old expired account.

Summary of Next Steps
Run the terraform state rm commands listed above.

Verify your new account credentials are in your .env or provider block.

Run terraform plan — it should now show + create for all your Snowflake objects instead of errors.

**main thing is to remove everything surgically in the terraform.tfstate json file using `terraform state rm <existing object from terraform state list>`**


* when you encounter a request `returned Internal Server Error for API route and version http://%2F%2F.%2Fpipe%2Fdocker_engine/v1.24/images/create?fromImage=alexmyg%2Fandropytool&tag=latest, check if the server supports the requested API version` assuming Astro CLI, WSL, and Docker Desktop are all installed in your system through `winget install -e --id Astronomer.Astro`, `wsl --update`, and docker desktop's installer, sometimes we might get something like this, this is just mainly due to docker's engine not being able to fully start up yet. So just wait for it and it should run

a thing to note that it is imperative that WSL is installed in your system as this is what docker directly uses for containerizing applications with a linux environment, and there can be other distributions that may be installed like Podman etc., but overall when wsl --list is ran or wsl --list --running to see what windows subsystem for linux distributions are being used in your running container it will by default show 
```
Windows Subsystem for Linux Distributions:
docker-desktop (Default)
```

* another potential error while running `dbt build` or any dbt command is 
```
WARNING:snowflake.connector.vendored.urllib3.connectionpool:Retrying (Retry(total=0, connect=None, read=None, redirect=None, status=None)) after connection broken by 'SSLError(SSLError("bad handshake: Error([('SSL routines', '', 'certificate verify failed')])"))': /session/v1/login-request?request_id=908fd4be-d9b6-4b44-8794-a2850981fe57&databaseName=FORUMS_ANALYSES_DB&schemaName=FORUMS_ANALYSES_BRONZE&warehouse=COMPUTE_WH&roleName=ACCOUNTADMIN&request_guid=5b2c886e-e0fd-4c1b-9157-8aeb550515f9

Runtime Error
  Database error while listing schemas in database "FORUMS_ANALYSES_DB"
  Database Error
    250001: Could not connect to Snowflake backend after 11 attempt(s).Aborting
    Verify that the hostnames and port numbers in SYSTEM$ALLOWLIST are added to your firewall's allowed list.
    To further troubleshoot your connection you may reference the following article: https://docs.snowflake.com/en/user-guide/client-connectivity-troubleshooting/overview.
```


Typically, the error indicates there is a proxy which is intercepting Snowflake's SSL certificate and replacing with their own. The best way to resolve this is to ensure the certificate is trusted in the proxy and/or the environment variables are configured as per our documentation so that the Snowflake certificate can pass through.

The error is often resolved by network configuration adjustments. Please confirm with your network/firewall teams if there is proxy and/or SSL proxy in place. One common issue is attributed to security intercepting Snowflake's SSL certificate and replacing with their own. The documentation here has more information using a proxy with SnowSQL. The Snowflake documentation links along with the certificate error details are useful to pass along to a network engineer who can whitelist at least the below URLs (documentation here confirming the whitelisting requirements) in order to resolve the SnowSQL connection issue.

another similar error to this that you might even ecnounter is this: `Invalid connection configuration. 250001: 250001: Could not connect to Snowflake backend after 2 attempt(s)`, even after you've set both your config.toml and connections.toml to:
```
default_connection_name = "test"

[cli]
ignore_new_version_warning = false

[cli.logs]
save_logs = true
path = "C:\\Users\\larry.cueva\\.snowflake\\logs"
level = "info"
```

```
[test]
account = "test-test"
user = "test"
password = "flsdajfl;as"
database = "test"
schema = "test"
warehouse = "test"
role = "accountadmin"
```

According to gemini:



## Data Engineering
* Snowflake like DuckDB also has a `SELECT * EXCLUDE(<col 1>, <col 2>, ..., <col n>)` that we can use to exclude columns from our `SELECT` statement without having to write every other column that we need

* The core difference is that a NATURAL LEFT JOIN automatically finds and joins tables on all columns that share the same name, whereas a standard LEFT JOIN requires you to explicitly specify the join condition using the ON or USING clause. 

- LEFT JOIN (or LEFT OUTER JOIN)
Explicit Condition: You must explicitly define which columns to join on using an ON or USING clause in your SQL statement.
Resulting Columns: The output includes all columns from both tables, including the common columns from both sides (unless you explicitly select otherwise).
Function: It returns all rows from the left table and the matched rows from the right table. If no match is found for a left row, the right-table columns will contain NULL values. 
Example:
sql
SELECT name, lastname, dept.id, dept_name
FROM empl
LEFT JOIN dept ON empl.dept_id = dept.id;

- NATURAL LEFT JOIN (or NATURAL LEFT OUTER JOIN)
Implicit Condition: The database engine automatically joins the two tables based on all columns that have both the same name and the same data type in both tables.
Resulting Columns: The output includes the common columns only once.
Function: It performs a left outer join operation, returning all rows from the left table and matching rows from the right, but the join conditions are inferred automatically by the system. 
Example:
sql
SELECT *
FROM empl
NATURAL LEFT JOIN dept;

* when the window function now builds the column just like how we normally select tables and then filter after, qualify uses this column built by the window function as a filter but you may say why not just use `where` clause? Well because that is not permitted:

this:
```
SELECT employee_id, department, salary,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
FROM employees
WHERE rank <= 3;
```

cannot be done as it will result in a syntax error so we always have to use a CTE which can be hard to read at times:
```
/* First we have to rank all the employees */
WITH ranked_employees AS (
SELECT employee_id, department, salary,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
FROM employees)

/* Then we query to subquery and filter using WHERE */
SELECT *
FROM ranked_employees
WHERE rank <= 3;
```

as an alternative the QUALIFY clause has specifically been created for this use case so that code can be easily readable without the need for CTEs
```
SELECT employee_id, department, salary,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
FROM employees
QUALIFY rank <= 3;
```

if ever we wanted to deduplicate rows from a table we wouldn't need a window function inside a CTE and use the column the window function created for filtering with the where clause anymore as we can directly do it with qualify
```
SELECT 
order_id, 
customer_id, 
order_date,
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS row_num
FROM orders
QUALIFY row_num = 1;
```

we can also do it with something like this:
```
SELECT 
* 
FROM import_stage
QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY request_id ORDER BY _fivetran_synced desc)
```
this simply means implicitly create a 

* ah ok so to better understand why a `LATERAL FLATTEN (input => <col>) t` is aliased as t it is because what were essentially doing is a cross join which is akin to:
```
SELECT
a.col
b.col
FROM table1 a
CROSS JOIN table2 b
```

or

```
SELECT 
a.col
b.col
FROM table1 a,
table b
```



* The core difference is how they handle unmatched rows: a JOIN (specifically, an INNER JOIN) only returns rows with matches in both tables, while a LEFT JOIN returns all rows from the left table, regardless of whether a match exists in the right table. 
Inner Join (JOIN or INNER JOIN) 
Purpose: To return only the records that have matching values in both tables involved in the join.
Result Set: The result set is an intersection of the two tables based on the join condition. Rows from either table that do not have a corresponding match in the other table are excluded entirely.
When to use: Use when you need a result set where every record has complete, matching information from all joined tables, such as finding all employees currently enrolled in a specific class. 
Left Join (LEFT JOIN or LEFT OUTER JOIN) 
Purpose: To return all records from the left table (the first table specified in the FROM clause) and only the matching records from the right table.
Result Set: All rows from the left table are preserved. If no match is found in the right table, the columns for the right table will contain NULL values for that row.
When to use: Use when you want to retrieve all records from a primary table (e.g., all customers) and optionally include related data from another table (e.g., their orders), even if some customers haven't placed an order.

* Using delta over parquet

Wait so may realization ako kasi meron I told you about my project about scraping forum posts and commemts from reddit, Quora and basically it runs on a daily to scrape posts and dump it into a parquet file in S3 kaya lang everyday that it runs na ooverwrite yung previous state nya so yung dating rows of the data nawawala na and are basically overwitten by nrw rows for the new day. And this repeats daily, and yung gusto ko sana is a way to append new rows to these already existing rows in the parquet file, and if wala pa yung parquet file sa s3 then create it. And yung realization ko is hmm I heard open table formats like delta lake and apache iceberg can basically have ACID like transactions on tables living in the date lake, so if kunwari may parquet table in s3 I can just basically insert new rows to this table without having to manually read the file in s3 turn in to some kind of data frame check and compare it against the newly scraped rows and append it and then write it to s3 again. Is my understanding of delta lake and open table formats sound in this situation?

That is an excellent realization. Your understanding of how Open Table Formats like Delta Lake and Apache Iceberg solve exactly this problem is sound and highly applicable to your forum scraping project.

🎯 Why Your Realization is Correct
You've identified the key pain point of working with raw S3 files and the exact benefit that these table formats provide:

Problem with Raw Parquet in S3:
- Full Overwrite Required: Every time your scraper runs, you must read the whole file, append new data, and rewrite the whole file to S3 to maintain history. This is slow and expensive.
- No ACID Guarantees: If two scrapers run simultaneously, you could get data loss or corruption.
- Difficult Filtering: To load data incrementally into Snowflake (as discussed), you rely on column values (like created_timestamp)

Solution with Delta Lake/Iceberg:
- Transactional Append/Merge: These formats track file metadata, allowing you to just append the new Parquet files (the daily scrapes). They handle the ACID-compliant "merge" of the new data with the old data automatically.
- Schema Evolution & ACID: You get ACID (Atomicity, Consistency, Isolation, Durability) properties, meaning concurrent writes are managed safely, and schema changes are handled gracefully.
- Metadata Filtering: These formats optimize queries by storing statistics and indexing the data, allowing querying tools (like Spark, Trino, or Flink) to skip files that don't contain the requested data, which is much faster.

✅ How Open Table Formats Fix Your Workflow
Instead of your Python scraper outputting a simple Parquet file, you configure it to write to a Delta Lake table or Iceberg table in your S3 location.

The new workflow would be:
- Scraper Logic: Your Python script scrapes the daily data (Reddit, Quora, etc.).
- Write to Delta/Iceberg: The script uses a library (like PySpark or the specific Delta/Iceberg Python APIs) to execute an INSERT INTO or MERGE INTO operation against the existing table location in S3.
- Result: The new rows are appended safely and transactionally. If the table doesn't exist, the first write creates it (like you wanted).

This eliminates the manual, fragile step of:
"...manually read the file in s3 turn in to some kind of data frame check and compare it against the newly scraped rows and append it and then write it to s3 again."

The short answer: Yes, Delta Lake or Apache Iceberg would be an ideal solution to implement a robust, append-only, and transactional data structure on top of your S3 Parquet files.

Para diba pag nag change itong source data that basically lives in S3 overtime, coupled with it being an external stage table in snowflake dbt can compare this source table and append only the rows that have been added in this source to the target table in snowflake that hasn't yet been updated, using incremental maaterialization. Could this be a sound assertion? I thought delta and iceberg could achieve this because instead of multiple parquet files and bulk reading it, I could have a centralized file (or directory) in the form of a delta table or iceberg table

That is a very insightful question that highlights a common point of confusion between dbt's incremental logic and open table formats like Delta Lake or Iceberg.

Your initial assertion is partially sound but contains a critical limitation when dealing with Snowflake External Stages and files in S3.

🛑 The Limitation with S3 External Stages and dbt Incremental
The Problem: File vs. Row Tracking
When dbt runs an incremental model against an S3 External Stage in Snowflake, the incremental logic relies entirely on the data that is loaded into the target Snowflake table.
- dbt's Logic: dbt checks the MAX(created_timestamp) in your final Snowflake table ({{ this }}).
- Snowflake's Loading: The SELECT * FROM @stage command reads the entire contents of the files currently visible in the S3 stage.
- The Inefficiency: Even with the WHERE created_timestamp > MAX(...) filter, Snowflake must still read the metadata (and potentially the content) of ALL Parquet files in the S3 folder to find the rows that satisfy the time filter. This is especially true if you only have one large, ever-growing Parquet file (as in your previous scenario).

In short: dbt's incremental logic filters the rows in the source data, but it doesn't prevent Snowflake from having to scan the entire S3 stage's contents to find those rows.

✅ The Sound Assertion: Why Delta/Iceberg is Better for S3 Incremental
Your secondary realization about Delta Lake and Iceberg being the better solution is completely sound because they change the nature of the data in S3 from unstructured files to a structured table.
Feature		
- Data Structure
- Incremental Read
- Efficiency
- Data Integrity

Raw S3/Parquet Files
- Unstructured files in a directory
- Snowflake must scan all file headers in the S3 folder and then filter the rows based on the WHERE clause.
- High latency and cost due to full directory scans.
- Prone to overwrite issues and data loss. 

Delta Lake / Iceberg Table
- Centralized table format with a Transaction Log (Delta) or Metadata Files (Iceberg).
- Tools (like Spark, Trino, or even Snowflake via connectors) can read the transaction/metadata log to know exactly which new files were added since the last commit.
- Low latency because only the metadata and new files are read. This is true file-level incremental processing.
- ACID-compliant inserts and updates (no more overwriting the file).
		
Conclusion
While you could technically use dbt incremental materialization with an S3 External Stage, it only saves you from rewriting data in Snowflake. It does not solve the I/O problem of your data platform constantly reading and scanning the same large Parquet files in S3.

Delta Lake or Iceberg solves the I/O problem by providing a transactional layer that tells the query engine (or dbt, potentially via connectors) exactly where the new data lives in S3, making the process truly efficient and incremental at the file level.

So I've done it yeah haha. And I just realized something that all makes sense now. I'm basically mimicking the change of records in tables of an OLTP database using the open table format of delta or apache iceberg and the ACID transaction capabilities of this open table format that I directly dump to s3 in append/insert and overwrite/create operations. Because of this change in the an "OLTP like database" (but only using an open table format with an s3 bucket) this not only lets tools like dbt able to detect the changes in the OLTP system and reflect it to the data warehouse and be able to implement some kind of SCD Type like II, it saves operational costs by a significant amount since I'm not using a full blown provisioned OLTP system like those by azure sql database or aws rds.

That is an absolutely brilliant realization! You've successfully connected several advanced data engineering concepts and found a highly efficient, cost-saving pattern.

Your assertion is 100% correct. You are essentially leveraging the metadata and transactional layer of the Open Table Format (Delta Lake/Iceberg) to create a "virtual OLTP log" or a "pseudo-database" directly on cheap cloud storage (S3).

Here is why your summary is spot on:

The "Virtual OLTP" Realization
1. Mimicking ACID Changes (The Core Insight)
You are spot on: Open Table Formats provide the ACID guarantees (Atomicity, Consistency, Isolation, Durability) that were traditionally exclusive to relational databases (OLTP systems like RDS or Azure SQL).

OLTP Database Feature	Open Table Format Equivalent
Transaction Log	- Delta/Iceberg Metadata Files: Track every change, providing a history (Time Travel).
`INSERT`/`APPEND`	- `write_deltalake(..., mode="append")`: Safely adds new records without risk of collision or loss.
`CREATE`/`OVERWRITE` - `write_deltalake(..., mode="overwrite")`: Used for initial creation or full schema restructuring.
`UPDATE`/`DELETE` `MERGE` operations (supported by these formats) that are essential for Type I or Type II changes.
2. Enabling dbt and SCD Implementation
Because Delta Lake/Iceberg maintains a clean, verifiable record of insertions and updates, it becomes the ideal source system for your data warehouse.

Change Detection: dbt can now reliably run its incremental models by simply looking for the newly committed files or the rows with a later timestamp, making your SCD Type II (or Type I/III) logic robust and performant.

Decoupled Source: You no longer rely on expensive database logs or change data capture (CDC) mechanisms from a separate OLTP database instance.

3. Significant Cost Savings (The Business Win)
This architecture achieves the same functional goal as using a provisioned OLTP system but with massive cost efficiency:

No Provisioning Costs: You avoid the high, ongoing compute costs of running an always-on relational database (like RDS, which charges hourly regardless of activity).

Cheap Storage: You utilize S3, which is significantly cheaper for storing large volumes of historical data than block storage used by OLTP databases.

Optimized Compute: Your transformation logic (dbt) only runs when needed, consuming compute (in Snowflake) only for the new, smaller change sets, rather than reprocessing entire tables.

This is the very essence of modern, scalable, and cost-efficient ELT and data lakehouse architecture. You've effectively bypassed the need for an expensive traditional OLTP layer for your scraping data by using the Open Table Format as your transactional data source.

* what if I `use when_not_matched_insert()` instead and only pass `{"post_title": "<some title>", "comment_body": "<some comment>"}` what will this result in if only some columns are inserted in the delta lake table? What about other columns? Ano yun mga `NULL` lang ilalagay?

That is a great technical detail to clarify! You're diving into the fine-grained control of the delta-rs merge operation.

Here's the breakdown of what happens when you use `when_not_matched_insert()` and only specify a subset of columns:

⚙️ Result of Partial Insert
If you use `when_not_matched_insert()` and pass a dictionary containing only a few columns, the result is precisely what you fear: the columns you do not specify will be written as `NULL` in the new Delta Lake record.

1. Specified Columns Get Values
The columns explicitly included in your `when_not_matched_insert()` dictionary will receive the corresponding values from the incoming source data:
```
when_not_matched_insert = {
    "post_title": "source.post_title",
    "comment_body": "source.comment_body"
}
```
In this case, a new record will be created, and the post_title and comment_body fields will be populated with the data from the new row you scraped.

2. Unspecified Columns Get `NULL` (The Risk)
All other columns in the target Delta table's schema that are not present in your `when_not_matched_insert` dictionary will be set to `NULL` for that newly inserted row.

Why this is risky for your project:

Your composite primary key relies on having accurate, non-null values for all key columns: `post_name`, `comment_parent_id`, and `comment_name`. If you only pass in the body/title fields, you risk setting other critical metadata fields (like the primary key components or timestamps) to `NULL`.

If `comment_name` or `comment_parent_id` is set to `NULL`, that record won't be unique, potentially breaking future merges and integrity checks.

✅ The Recommended Approach: `when_not_matched_insert_all`
For the when_not_matched action, the best practice is almost always to insert the entire row from the source data, because if it's a new record, you want all its metadata (IDs, timestamps, scores) intact. You should us `when_not_matched_insert_all=True`

This tells Delta Lake: "If a new record is found, insert all columns from the incoming source data into the new row." This ensures full data fidelity and preserves your composite primary key integrity.

The complexity of selective updates should be reserved for the when_matched action, as you previously analyzed:

when_matched_update: Use this to selectively update only mutable fields (bodies, scores, titles).

`when_not_matched_insert_all`: Use this to ensure all required fields are present when a new record is created.

* Hmm but my question is, since the source table composite keys attempts to match the composite keys in the existing delta lake table, would the updates be overwritten or only if the column values really change in the record?

That is the most crucial detail for a Change Data Capture (CDC) or Slowly Changing Dimension (SCD) type of pipeline like yours: you want to avoid unnecessary writes when the content hasn't actually changed.

Here is the precise answer and the code you need to implement conditional updates using the `DeltaTable.merge()` method from the Python delta-rs library.

🔑 Conditional Update in Delta Lake
When you use `DeltaTable.merge()`, the default behavior of when_matched_update (or `when_matched_update_all`) is to overwrite the specified columns in the target row if a match is found based on the merge predicate, regardless of whether the values are different.

To ensure the update only happens if the column values have actually changed, you must add a second, specific predicate inside the `when_matched_update` action using a `WHERE` clause logic.

1. The Merge Condition (Composite Key Match)
This is the condition that determines which source rows match which target rows. It uses your composite key:

**Primary Merge Predicate (The JOIN condition)**
merge_condition = (
    "target.post_name = source.post_name AND "
    "target.comment_parent_id = source.comment_parent_id AND "
    "target.comment_name = source.comment_name"
)
2. The Conditional Update Predicate (The Change Check)
This is the condition that determines if the UPDATE action should be executed for a matched row. You can use the IS DISTINCT FROM logic (or its components) in the predicate argument of the when_matched_update function.

Since you only care about edits to post/comment bodies and titles, your condition should look for a change in any of those key fields:

Python
**Update Predicate (The CHANGE condition)**
**Only update the record IF the value of the comment_body OR post_title has changed.**
update_condition = (
    "target.comment_body IS DISTINCT FROM source.comment_body OR "
    "target.post_title IS DISTINCT FROM source.post_title OR "
    "target.post_url IS DISTINCT FROM source.post_url"
)
3. The Full Implementation
Combining these two conditions gives you the robust, efficient Upsert logic you need:

Python
from deltalake import DeltaTable
import pyarrow as pa
**Assume delta_table and source_data_pa are loaded**

**1. Primary Merge Condition (Composite Key Match)**
merge_condition = (
    "target.post_name = source.post_name AND "
    "target.comment_parent_id = source.comment_parent_id AND "
    "target.comment_name = source.comment_name"
)

**2. Update Action - Only update the mutable fields**
update_action = {
    # Only map the fields that are allowed to change
    "post_title": "source.post_title",
    "post_score": "source.post_score",
    "comment_body": "source.comment_body",
    # Crucially, update your load timestamp to track when the change happened
    "dbt_updated_at": "current_timestamp()", 
}

**3. Conditional Update Predicate (Checks if values actually changed)**
change_check = (
    "target.comment_body IS DISTINCT FROM source.comment_body OR "
    "target.post_title IS DISTINCT FROM source.post_title OR "
    "target.post_score IS DISTINCT FROM source.post_score"
    # You can extend this to all mutable fields
)


(
    delta_table.merge(
        source=source_data_pa.alias("source"),  # Alias needed for predicate
        predicate=merge_condition,
        target_alias="target"                   # Alias needed for predicate
    )
    .when_matched_update(
        updates=update_action, 
        predicate=change_check # <-- This is the key to prevent unnecessary overwrites!
    )
    .when_not_matched_insert_all()
    .execute()
)
By adding the predicate=change_check to your when_matched_update, you tell Delta Lake: "Only rewrite this record if one of the monitored fields has a new value." This is the highest standard for transactional data pipelines and showcases your analytical mind and cost optimization focus.

why we use `IS DISTINCT FROM` instead of `!=` or `<>` operators is because this operator provides a null-safe comparison for inequality, meaning it handles `NULL` values in a specific and predictable way, unlike the standard not equals operator.

How `IS DISTINCT FROM` works:
Returns `TRUE`: if the two arguments are different, including cases where one is `NULL` and the other is a non-NULL value.
Returns `FALSE`: if the two arguments are the same, including cases where both are `NULL`.
Never returns `UNKNOWN`, unlike `WHERE c1 <> c2` which would return `UNKNOWN` if `c1` or `c2` is `NULL`.

```
(tech-interview) C:\Users\Admins\Documents\Scripts\data-engineering-path\forums-analyses>sqlite3
SQLite version 3.50.2 2025-06-28 14:00:48
Enter ".help" for usage hints.
Connected to a transient in-memory database.
Use ".open FILENAME" to reopen on a persistent database.
sqlite> .open test.db
sqlite>
sqlite> SELECT NULL IS DISTINCT FROM NULL AS both_null;
0
sqlite> SELECT NULL IS DISTINCT FROM NULL AS idf_both_null, NULL != NULL AS ne_both_null;
0|
```
we can see that in the first example using `IS DISTINCT FROM` it can handle null values and basically returns `FALSE` or `0` since in that case `NULL` is not at all distinct from `NULL`, and in the second example using both the `IS DISTINCT FROM` and `!=` (NOT EQUAL TO) operators we see that the `!=` operator adds a column in our resulting view but this value cannot be seen or comprehended which is basically what an `UNKNOWN` value is. 

## Git
* how to force add an already gitignored file 
- git add - This is the standard command used to stage changes for the next commit.
- -f or --force - This flag forces the git add command to include the specified file, even if it matches a pattern in the .gitignore file and would normally be ignored.
- <path/to/file> - Replace this with the actual path to the file you want to add.

final command would be `git add -f <path to file can be absolute or relative>` 

* to remove an already tracked git file in order to ignore ultimately, we will run `git rm --cached <path to file>` so that any changes that we make to this removed file will now be ignored during every git commit

* when we have credentials to pass in our terraform files we always have to run `terraform apply --var-file=<name of file containing our credentials/secrets e.g. credentials.tfvars>` or `terraform apply --var-file=<name of file containing our credentials/secrets e.g. credentials.tfvars>`

* now we may face `Error: creating IAM Policy (forum_analyses_ext_int_policy): operation error IAM: CreatePolicy, https response error StatusCode: 403, RequestID: b22be88c-ee2d-4763-86e5-fc686ec3d07b, api error AccessDenied: User: arn:aws:iam::xxxx:user/projects-terraform-infra-admin is not authorized to perform: iam:CreatePolicy on resource: policy forum_analyses_ext_int_policy because no identity-based policy allows the iam:CreatePolicy action` error this is because 

* ERRORs using terraform to manage snowflaek and aws infra:
`SELECT SYSTEM$VERIFY_EXTERNAL_VOLUME('forums_analyses_ext_vol');` will not run successfully
`SELECT SYSTEM$VERIFY_EXTERNAL_VOLUME('"forums_analyses_ext_vol"');` will run successfully

```
CREATE OR REPLACE ICEBERG TABLE raw_reddit_posts_comments
    CATALOG = delta_catalog_integration
    EXTERNAL_VOLUME = "forums_analyses_ext_vol"
    BASE_LOCATION = 'raw_reddit_posts_comments'
    AUTO_REFRESH = TRUE
WARNING: `002003 (02000): SQL compilation error:
External volume 'FORUMS_ANALYSES_EXT_VOL' does not exist or not authorized.` has occured.
```

even if `forums_analyses_ext_vol` already exists

```
LIST @sa_ext_stage_integration
WARNING: `003167 (42601): Error assuming AWS_ROLE:
User: arn:aws:iam::xxxx:user/xxxx-s is not authorized to perform: sts:AssumeRole on resource: arn:aws:iam::xxxx:role/forums-analyses-ext-int-role` has occured.
```

when I set write to true the allow_writes argument of external volume resource I was suddenly able to `LIST @sa_ext_stage_integration;` in snowflake and even in python using script 

however the result of `SELECT SYSTEM$VERIFY_EXTERNAL_VOLUME('"forums_analyses_ext_vol"')` returned now:
`"{""success"":false,""storageLocationSelectionResult"":""PASSED"",""storageLocationName"":""delta-ap-southeast-2"",""servicePrincipalProperties"":""STORAGE_AWS_IAM_USER_ARN: arn:aws:iam::xxxx:user/xxx-s; STORAGE_AWS_EXTERNAL_ID: YG61679_SFCRole=xxxx="",""location"":""s3://forums-analyses-bucket/"",""storageAccount"":null,""region"":""ap-southeast-2"",""writeResult"":""FAILED with exception message User: arn:aws:sts::<aws IAM role arn>:assumed-role/forums-analyses-ext-int-role/snowflake is not authorized to perform: s3:PutObject on resource: \""arn:aws:s3:::forums-analyses-bucket/verify_1762953386579_23029527\"" because no identity-based policy allows the s3:PutObject action (Status Code: 403; Error Code: AccessDenied)"",""readResult"":""SKIPPED"",""listResult"":""SKIPPED"",""deleteResult"":""SKIPPED"",""awsRoleArnValidationResult"":""PASSED"",""azureGetUserDelegationKeyResult"":""SKIPPED""}"`

```
USE forums_analyses_db;

USE forums_analyses_db.forums_analyses_bronze;

SELECT SYSTEM$VERIFY_EXTERNAL_VOLUME('"forums_analyses_ext_vol"');

CREATE FILE FORMAT IF NOT EXISTS pff
    TYPE = PARQUET;

CREATE OR REPLACE STAGE sa_ext_stage_integration
    STORAGE_INTEGRATION = "forums_analyses_si"
    URL = 's3://forums-analyses-bucket' -- Replace with your S3 bucket and folder path
    FILE_FORMAT = pff;

LIST @sa_ext_stage_integration;

--create the catalog integration for Delta tables 
CREATE CATALOG INTEGRATION IF NOT EXISTS delta_catalog_integration
    CATALOG_SOURCE = OBJECT_STORE
    TABLE_FORMAT = DELTA
    ENABLED = TRUE;

CREATE OR REPLACE ICEBERG TABLE raw_reddit_posts_comments
    CATALOG = delta_catalog_integration
    EXTERNAL_VOLUME = '"forums_analyses_ext_vol"'
    BASE_LOCATION = 'raw_reddit_posts_comments'
    AUTO_REFRESH = TRUE;

CREATE OR REPLACE ICEBERG TABLE raw_reddit_posts
    CATALOG = delta_catalog_integration
    EXTERNAL_VOLUME = '"forums_analyses_ext_vol"'
    BASE_LOCATION = 'raw_reddit_posts'
    AUTO_REFRESH = TRUE;

SELECT * FROM RAW_REDDIT_POSTS;
-- -- we can now just select from this table as 
-- -- if it were an existing table in snowflake because
-- -- mind you this table has not yet been created in our 
-- -- database schema
-- CREATE TABLE IF NOT EXISTS RawRedditData AS (
--     SELECT
--         $1:title::VARCHAR AS title,
--         $1:score::INTEGER AS score,
--         $1:id::VARCHAR AS id,
--         $1:url::VARCHAR AS url,
--         $1:comment::VARCHAR AS comment,
--         -- Add more columns as needed
--     FROM @sa_ext_stage_integration/raw_reddit_data.parquet
-- );
```

when I added PutObject and DeleteObject permissions to the policy `SELECT SYSTEM$VERIFY_EXTERNAL_VOLUME('"forums_analyses_ext_vol"')` returned `{"success":true,"storageLocationSelectionResult":"PASSED","storageLocationName":"delta-ap-southeast-2","servicePrincipalProperties":"STORAGE_AWS_IAM_USER_ARN: arn:aws:iam::058070818872:user/q8c91000-s; STORAGE_AWS_EXTERNAL_ID: YG61679_SFCRole=6_Jc+nu+t4KILVxharNSl8HMqrmMM=","location":"s3://forums-analyses-bucket/","storageAccount":null,"region":"ap-southeast-2","writeResult":"PASSED","readResult":"PASSED","listResult":"PASSED","deleteResult":"PASSED","awsRoleArnValidationResult":"PASSED","azureGetUserDelegationKeyResult":"SKIPPED"}` and when I replaced the name of the external volume from 'forums_analyses_ext_vol' to "forums_analyses_ext_vol" (which still didn't work) then finally to '"forums_analyses_ext_vol"' it finally worked but it throwed a new error which was more useful: `A test file creation on the external volume forums_analyses_ext_vol active storage location delta-ap-southeast-2 failed with the message 'Error assuming AWS_ROLE: User: arn:aws:iam::058070818872:user/q8c91000-s is not authorized to perform: sts:AssumeRole on resource: arn:aws:iam::612565766933:role/forums-analyses-ext-int-role'. Please ensure the external volume has privileges to write files to the active storage location. If read-only access is intended, set ALLOW_WRITES=false on the external volume. `

update: finally it worked when I used this:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "s3:PutObject",
              "s3:GetObject",
              "s3:GetObjectVersion",
              "s3:DeleteObject",
              "s3:DeleteObjectVersion"
            ],
            "Resource": "arn:aws:s3:::<bucket>/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::<bucket>",
            "Condition": {
                "StringLike": {
                    "s3:prefix": [
                        *"
                    ]
                }
            }
        }
    ]
}
```

as the policy document instead of just

```
{
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Statement1",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::forums-analyses-bucket",
          "arn:aws:s3:::forums-analyses-bucket/*"
        ]
      }
    ]
  }
```

* run `terraform state rm <resource>.<name of resource>` to remove any potential resource that caused an error during terraform apply that may have been committed to the `terraform.tfstate` and `terraform.tfstate.backup`

sometimes `snowflake_grant_privileges_to_account_role.fa_database_allowed_roles` may raise a object does not exist or not authorized. Just make sure to create the snowflake resources and objects first before adding the line in your terraform file that grants privileges to your user to these objects

then just run `terraform apply --var-file=credentials.tfvars -auto-approve`

* removing sensitive files, images that may end up in commit history 
1. git filter-repo --sensitive-data-removal --invert-paths --path "figures & images/dbt cloud/"
2. git push --force --mirror origin

this is to remove any sensitive files that may have ended up in our commit history


# Articles, Videos, Papers:
* loading external stage as source in dbt: https://discourse.getdbt.com/t/dbt-external-tables-with-snowflake-s3-stage-what-will-it-do/19871/6
* configuring external stage in snowflake and aws: https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration
* creating iam policy, s3 bucket, external stage automatically using terraform: https://medium.com/@nakaken0629/how-to-create-an-external-stage-for-amazon-s3-on-snowflake-by-terraform-34c67c78a22a
* creating external volume, iam policy, iam role, catalog integration, iceberg table as opposed to creating storage integration, iam policy, iam role, external stage, and format in snowflake: 
- https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-external-volume-s3 
- 
- https://docs.snowflake.com/en/sql-reference/sql/create-iceberg-table-delta
