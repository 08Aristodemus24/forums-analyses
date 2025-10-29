import os

from airflow.decorators import dag
from airflow.configuration import conf
from airflow.operators.bash import BashOperator

from cosmos import DbtDag, DbtTaskGroup, ProjectConfig, ProfileConfig, ExecutionConfig
from cosmos.profiles import SnowflakeUserPasswordProfileMapping, SnowflakeEncryptedPrivateKeyFilePemProfileMapping

from datetime import datetime
from pathlib import Path

DBT_PROJECT_PATH = Path("/usr/local/airflow/dags/forums_analyses")
DBT_EXE_PATH = Path("/usr/local/bin/dbt")

profile_config = ProfileConfig(
    profile_name="default",
    target_name="dev",
    profile_mapping=SnowflakeEncryptedPrivateKeyFilePemProfileMapping(
        conn_id="snowflake_default", 
        profile_args={
            "account": os.environ.get("SNOWFLAKE_ACCOUNT_ID"),
            "user": os.environ.get("SNOWFLAKE_LOGIN_NAME"),
            "role": os.environ.get("SNOWFLAKE_ROLE"),
            "warehouse": "COMPUTE_WH",
            "database": "SUBREDDIT_ANALYSES_DB",
            "schema": "SUBREDDIT_ANALYSES_BRONZE",
            "private_key_path": "/usr/local/airflow/rsa_key.p8",
            "private_key_passphrase": os.environ.get("PRIVATE_KEY_PASSPHRASE")
        },
    )
)

# get airflow folder
AIRFLOW_HOME = conf.get('core', 'dags_folder')

# base dir would be /opt/***/ or /opt/airflow
BASE_DIR = Path(AIRFLOW_HOME).resolve().parent

@dag(
    start_date=datetime(2023, 8, 1),
    schedule=None,
    catchup=False,
    params={"my_name": "dbt_snowflake_dag"},
)
def forums_analyses_dag():
    # fetch_reddit_data = BashOperator(
    #     task_id="extract_signals",
    #     bash_command=f"python {AIRFLOW_HOME}/operators/fetch_reddit_data.py \
    #         --bucket_name subreddit-analyses-bucket \
    #         --object-name raw_reddit_data.parquet"
    # )

    transform_data = DbtTaskGroup(
        group_id="transform_data",
        project_config=ProjectConfig(DBT_PROJECT_PATH),
        profile_config=profile_config,
        execution_config=ExecutionConfig(dbt_executable_path=DBT_EXE_PATH),
        operator_args={
            "vars": '{"my_name": {{ params.my_name }} }',
        },
        default_args={"retries": 2},
    )

    # fetch_reddit_data
    transform_data

forums_analyses_dag()