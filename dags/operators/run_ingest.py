import os 

import snowflake.connector as sc
import logging

def setup_logging():
    logger = logging.getLogger('SGX_Downloader')
    logger.setLevel(logging.DEBUG) # Catch everything at the logger level

    # 2. Console/Stream Handler (for user feedback)
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO) # Only show INFO, ERROR, CRITICAL
    console_formatter = logging.Formatter('%(levelname)s: %(message)s')
    console_handler.setFormatter(console_formatter)
    logger.addHandler(console_handler)

    return logger

# setup logger
global logger
logger = setup_logging()
logger.info("Script started.") # Will appear on console and file
logger.debug("Attempting to connect with Selenium.") # Will only appear in the file'


if __name__ == "__main__":
    # Establish a connection
    conn_params = {
        'account': os.environ.get("SNOWFLAKE_ACCOUNT_ID"),
        'user': os.environ.get("SNOWFLAKE_LOGIN_NAME"),
        'authenticator': 'SNOWFLAKE_JWT',
        'private_key_file': "/usr/local/airflow/rsa_key.p8",
        'private_key_file_pwd': os.environ.get("PRIVATE_KEY_PASSPHRASE"),
        'warehouse': "COMPUTE_WH",
        'database': "FORUMS_ANALYSES_DB",
        'schema': "FORUMS_ANALYSES_BRONZE"
    }

    conn = sc.connect(**conn_params)
    cursor = conn.cursor()

    # open sql file
    with open('./load_data_from_s3.sql', 'r') as f:
        sql_stmts = f.read().split(";")

    # run sql statements in file
    try:
        for sql_stmt in sql_stmts:
            logger.info(f"running: {sql_stmt}")
            cursor.execute(sql_stmt)

    except Exception as e:
        logger.warning(f"`{e}` has occured.")
        logger.warning(f"{sql_stmt} statement failed in running.")
