# Techonologies:
* DBT - for transformation logic inside the data warehouse itself

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

# Articles, Videos, Papers:

