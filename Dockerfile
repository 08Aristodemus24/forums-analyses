FROM astrocrpublic.azurecr.io/runtime:3.1-2

# copy and install dependencies in airflow container specifically
# in the /opt/airflow directory which is teh airflow home
COPY ./requirements.txt ./

# copy the created private keys and public keys
# so that SnowflakeEncryptedPrivateKeyFilePemProfileMapping
# class can access it
COPY ./rsa_key.p8 ./
COPY ./rsa_key.pub ./

# install dependencies
# and pgrade pip to the latest version
RUN pip install --trusted-host pypi.python.org --trusted-host pypi.org  --upgrade pip
RUN pip install --no-cache-dir --trusted-host pypi.python.org --trusted-host pypi.org -r requirements.txt