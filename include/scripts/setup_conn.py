from airflow.configuration import conf

import subprocess
import os

def add_airflow_connection(**kwargs):
    conn_id = kwargs.get("conn_id")
    cmd = ["airflow", "connections", "add", conn_id]
    for key, value in kwargs.items():
        if not "conn_id" in key:
            key = key.replace("_", "-")

            if "extra" in key:
                value = str(value).replace("'", '"')
                print(type(value))
            
            # append connection key and its corresponding value
            cmd.append(f"--{key}")
            cmd.append(value)

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        print(f"Successfully added {conn_id} connection")
    else:
        print(f"Failed to add {conn_id} connection: {result.stderr}")

def add_connections(connections: dict):
    for conn_name, conn_kwargs in connections.items():
        print(f"adding {conn_name} connection...")
        add_airflow_connection(**conn_kwargs)

if __name__ == "__main__":
    connections = {
        "snowflake_conn": {
            "conn_id": "fa_snowflake_conn", 
            "conn_type": "snowflake", 
            "conn_login": os.environ.get("SNOWFLAKE_LOGIN_NAME"),
            "conn_password": os.environ.get("PRIVATE_KEY_PASSPHRASE"),
            "conn_extra": {
                "account": os.environ.get("SNOWFLAKE_ACCOUNT_ID"),
                "role": os.environ.get("SNOWFLAKE_ROLE"),
                "private_key_file": "/usr/local/airflow/rsa_key.p8"
            }
        },
    }
    add_connections(connections)