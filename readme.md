# Overview

Welcome to Astronomer! This project was generated after you ran 'astro dev init' using the Astronomer CLI. This readme describes the contents of the project, as well as how to run Apache Airflow on your local machine.

# Project Contents

Your Astro project contains the following files and folders:

- dags: This folder contains the Python files for your Airflow DAGs. By default, this directory includes one example DAG:
    - `example_astronauts`: This DAG shows a simple ETL pipeline example that queries the list of astronauts currently in space from the Open Notify API and prints a statement for each astronaut. The DAG uses the TaskFlow API to define tasks in Python, and dynamic task mapping to dynamically print a statement for each astronaut. For more on how this DAG works, see our [Getting started tutorial](https://www.astronomer.io/docs/learn/get-started-with-airflow).
- Dockerfile: This file contains a versioned Astro Runtime Docker image that provides a differentiated Airflow experience. If you want to execute other commands or overrides at runtime, specify them here.
- include: This folder contains any additional files that you want to include as part of your project. It is empty by default.
- packages.txt: Install OS-level packages needed for your project by adding them to this file. It is empty by default.
- requirements.txt: Install Python packages needed for your project by adding them to this file. It is empty by default.
- plugins: Add custom or community plugins for your project to this file. It is empty by default.
- airflow_settings.yaml: Use this local-only file to specify Airflow Connections, Variables, and Pools instead of entering them in the Airflow UI as you develop DAGs in this project.

# Deploy Your Project Locally
Start Airflow on your local machine by running 'astro dev start'.

This command will spin up five Docker containers on your machine, each for a different Airflow component:

- Postgres: Airflow's Metadata Database
- Scheduler: The Airflow component responsible for monitoring and triggering tasks
- DAG Processor: The Airflow component responsible for parsing DAGs
- API Server: The Airflow component responsible for serving the Airflow UI and API
- Triggerer: The Airflow component responsible for triggering deferred tasks

When all five containers are ready the command will open the browser to the Airflow UI at http://localhost:8080/. You should also be able to access your Postgres Database at 'localhost:5432/postgres' with username 'postgres' and password 'postgres'.

Note: If you already have either of the above ports allocated, you can either [stop your existing Docker containers or change the port](https://www.astronomer.io/docs/astro/cli/troubleshoot-locally#ports-are-not-available-for-my-local-airflow-webserver).

# Deploy Your Project to Astronomer
If you have an Astronomer account, pushing code to a Deployment on Astronomer is simple. For deploying instructions, refer to Astronomer documentation: https://www.astronomer.io/docs/astro/deploy-code/

# Business Use Case:
The business use case here was to solve the following problems of:


Potential solutions:


Reasoning:


Outcome:

# Usage:
* navigate to directory with `Dockerfile` and `docker-compose.yaml` file
* make sure that docker is installed within you system
* run `make up` in terminal in the directory where the aforementioned files exist
* once docker containers are running go to `http://localhost:8080`
* sign in with `airflow` and `airflow` as username as password respectively
* trigger the directed acyclic graph (DAG) to run ETL pipeline which will basically automate (orchestrate) running the ff. commands in the background using airflow operators:
- `python ./operators/extract_cdi.py -L https://www.kaggle.com/api/v1/datasets/download/payamamanat/us-chronic-disease-indicators-cdi-2023` to download chronic disease indicators data and transfer to s3
- `python ./operators/extract_us_population_per_state_by_sex_age_race_ho.py` to extract raw population data per state per year. Note this uses selenium rather than beautifulsoup to bypass security of census.gov as downloading files using requests rather than clicking renders the downloaded `.csv` file as inaccessible
- `spark-submit --packages org.apache.hadoop:hadoop-aws:3.3.4,com.amazonaws:aws-java-sdk-bundle:1.11.563,org.apache.httpcomponents:httpcore:4.4.16 transform_us_population_per_state_by_sex_age_race_ho.py --year-range-list 2000-2009 2010-2019 2020-2023`
- `spark-submit --packages org.apache.hadoop:hadoop-aws:3.3.4,com.amazonaws:aws-java-sdk-bundle:1.11.563,org.apache.httpcomponents:httpcore:4.4.16 transform_cdi.py`
- `python ./operators/load_primary_tables.py`
- `python ./operators/update_tables.py`
* when all tasks are successful and pipeline shows all green checks we can visit https://chronic-disease-analyses.vercel.app/ to see the updated dashboard 