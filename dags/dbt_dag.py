import os

from airflow.decorators import dag
from airflow.configuration import conf
from airflow.operators.bash import BashOperator
from airflow.providers.snowflake.operators.snowflake import SnowflakeSqlApiOperator

from cosmos import DbtDag, DbtTaskGroup, ProjectConfig, ProfileConfig, ExecutionConfig
from cosmos.profiles import SnowflakeUserPasswordProfileMapping, SnowflakeEncryptedPrivateKeyFilePemProfileMapping

from datetime import datetime, timedelta
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
            "database": "FORUMS_ANALYSES_DB",
            "schema": "FORUMS_ANALYSES_BRONZE",
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
    default_args={
        'owner': 'airflow',
        'retries': 3,
        'retry_delay': timedelta(seconds=60),
        'retry_exponential_backoff': True,
    },
    params={"my_name": "dbt_snowflake_dag"},
)
def forums_analyses_dag():
    fetch_raw_reddit_posts_comments = BashOperator(
        task_id="fetch_raw_reddit_posts_comments",
        bash_command=f"python {AIRFLOW_HOME}/operators/fetch_reddit_data.py \
            --bucket_name forums-analyses-bucket \
            --object_name raw_reddit_posts_comments \
            --kind comments \
            --limit 100"
    )

    fetch_raw_reddit_posts = BashOperator(
        task_id="fetch_raw_reddit_posts",
        bash_command=f"python {AIRFLOW_HOME}/operators/fetch_reddit_data.py \
            --bucket_name forums-analyses-bucket \
            --object_name raw_reddit_posts \
            --kind posts \
            --limit 100"
    )

    fetch_raw_youtube_data = BashOperator(
        task_id="fetch_raw_youtube_data",
        bash_command=f"python {AIRFLOW_HOME}/operators/fetch_youtube_data.py \
            --bucket_name forums-analyses-bucket \
            --limit 250"
    )

    # load_data_from_s3 = SnowflakeSqlApiOperator(
    #     task_id="load_data_from_s3",
    #     snowflake_conn_id="fa_snowflake_conn",
    #     sql="/operators/load_data_from_s3.sql",
    #     statement_count=10
    # )

    # transform_data = DbtTaskGroup(
    #     group_id="transform_data",
    #     project_config=ProjectConfig(DBT_PROJECT_PATH),
    #     profile_config=profile_config,
    #     execution_config=ExecutionConfig(dbt_executable_path=DBT_EXE_PATH),
    #     operator_args={
    #         "vars": '{"my_name": {{ params.my_name }} }',
    #     },
    #     default_args={"retries": 2},
    # )

    [
        fetch_raw_reddit_posts_comments, 
        fetch_raw_reddit_posts, 
        fetch_raw_youtube_data
    ] 
    # >> load_data_from_s3
    # load_data_from_s3 >> transform_data

forums_analyses_dag()