# start containers in detached mode so that after starting
# it doesn't leave containers running in the terminal so that
# subsequent commands can run such as do-sleep and setup-conn
start-containers:
	astro dev start

# timeout for 30 seconds to make sure container
do-sleep:
	timeout 30

# once containers are started and waited for 30 seconds the nex command
# in sequence to run is to run a script inside a running airflow container
# that will setup our airflow connections in the container from our 
# local machine  
setup-conn:
	docker exec forums-analyses_00fc64-api-server-1 python /usr/local/airflow/include/scripts/setup_conn.py

up: start-containers do-sleep 
# setup-conn

down:
	astro dev stop

# there are 4 containers we can basically access
# the (kafka) broker, schema-registry, control-center, 
# and the zookeeper
sh-airflow:
	docker exec -it forums-analyses_00fc64-api-server-1 bash

restart:
	astro dev restart
