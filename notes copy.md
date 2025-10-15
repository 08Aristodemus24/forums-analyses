# Technologies:
## options:
* Azure databricks (Apache Spark)/AWS EMR - for data transformation
* Azure data factory/AWS glue - for data task orchestration
* Azure data lake/AWS S3 - for storing data at each transformation step
* Azure synapse/AWS redshift - for data warehouse
* Apache Kafka - for data streaming
* Terraform - for automating setup of azure services
* Azure event hubs/bus/grid
* Cassandra - no sqk database for analytics

## viable:
* Postgres/supabase (postgres platform) - to store the reddit data
* Azure synapse - for data warehouse to store real time data
* DBT (databuild tool) - for data transformation using jinja and sql
* Apache Kafka - queue for data streaming
* Spark Streaming - transformation tool for streaming data
* claude sonnet 3.8 - agent used for analyzing the stored real time data stored in cassandra or any kind of cloud data warehouse

idea is to run the broker container on a certain server, run the airflow server on a separate server, and run the pipeline to extract and dump the data to the event queue/broker at its server url

# Insights:
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

* Kafka docker images
You've made an excellent analogy, and yes, your understanding is largely correct!

Confluent and Apache Kafka
You are absolutely right. Confluent is essentially a leading provider and steward of Apache Kafka.

Relationship: Confluent was founded by the original creators of Apache Kafka while they were still at LinkedIn. They open-sourced Kafka, and then went on to build Confluent to commercialize and extend Kafka's capabilities.

What Confluent provides:

Managed Service (Confluent Cloud): This is their flagship offering, a fully managed, cloud-native service for Apache Kafka. You don't have to worry about setting up, scaling, patching, or maintaining Kafka clusters; Confluent handles all of that. This is very similar to how you use a managed service in Azure (like Azure Event Hubs) or AWS (like Amazon MSK for Kafka).

Enterprise Distribution (Confluent Platform): They offer an enhanced, production-ready distribution of Kafka that includes additional features, management tools, security enhancements, and connectors that go beyond the open-source Apache Kafka project. You can run this on your own infrastructure.

Development & Contributions: Confluent is a major contributor to the open-source Apache Kafka project, continuously driving its development and adding new features.

Bitnami and Apache Spark
Your analogy with Bitnami is very apt.

Relationship: Bitnami isn't the creator of Apache Spark, but they are a very popular distributor and packager of Apache Spark (and many other open-source applications).

What Bitnami provides: They take the open-source Apache Spark software and create pre-configured, optimized, and easy-to-deploy images (like Docker images, Helm charts for Kubernetes, or virtual machine images). This makes it much simpler for users to get Spark up and running quickly without dealing with complex installation and configuration. They manage the packaging, versioning, and often the security patching of these images.

The Analogy Holds:
The core similarity is that both Confluent and Bitnami provide ways to simplify the deployment, management, and use of complex open-source software (Kafka and Spark, respectively).

Confluent manages Apache Kafka, offering both a fully hosted "Kafka as a Service" (Confluent Cloud) and an enhanced enterprise package (Confluent Platform). They are deeply integrated with the development of Kafka itself.

Bitnami manages Apache Spark by providing pre-built, ready-to-run packages/images, reducing the operational burden of setting it up yourself in various environments like Docker.

So, yes, if Bitnami "manages" the deployment and packaging of Apache Spark, then Confluent definitely "manages" Apache Kafka, and then some, extending into full managed service offerings and enterprise-grade features.

oh so that's why some docker images aren't directly named apache kafka, its always bitnami/kafka, apache/kafka, or the image owned by confluent confluentinc/cp-kafka. I mean judging by the names it would seem more intuitive to pick the apache/kafka image? Why do people use confluentinc/cp-kakfa image frequently rather than the other ones? What's the difference anyway?

You've hit on a really common observation when working with Docker images for popular open-source projects! It can definitely be confusing why there are multiple "official-looking" images.

Let's break down the differences between apache/kafka, bitnami/kafka, and confluentinc/cp-kafka and why confluentinc/cp-kafka is often preferred.

The Different Kafka Docker Images:
apache/kafka (The "Official" Apache Project Image)

Origin: This image is maintained by the Apache Kafka project itself. It's often found in the docker.io/apache namespace.

What it contains: It typically contains the vanilla, bare-bones Apache Kafka broker software (and sometimes ZooKeeper, depending on the version/tag). It's built directly from the Apache Kafka source code.

Purpose: To provide a pure, unmodified Apache Kafka experience.

Usability: Can be a bit more challenging for beginners to set up, especially for multi-broker clusters or when integrating with other tools, as it might require more manual configuration or additional scripts. It's often focused on providing just the core Kafka.

bitnami/kafka (Bitnami's Managed Image)

Origin: Maintained by Bitnami (now part of VMware/Broadcom), a company known for packaging open-source software.

What it contains: This image also contains Apache Kafka, but it's often built with additional optimizations, robust configurations, and sometimes helper scripts to make it easier to deploy and manage in common environments (like Kubernetes using Helm charts). They focus on secure and production-ready defaults.

Purpose: To provide highly opinionated, ready-to-run, and well-maintained images for easy deployment of open-source applications.

Usability: Generally considered more user-friendly for getting started quickly and for production deployments, due to built-in helper scripts and sensible defaults.

confluentinc/cp-kafka (Confluent Platform Kafka Image)

Origin: Maintained by Confluent, the company founded by Kafka's original creators.

What it contains: This image contains the Apache Kafka broker plus components from the Confluent Platform. The Confluent Platform is an enterprise-grade distribution that extends Apache Kafka with additional features like:

Confluent Control Center: A web-based UI for monitoring and managing Kafka.

Schema Registry: Essential for enforcing data schema compatibility in Kafka topics.

Kafka Connect: For building connectors to other systems, often with more robust features or managed connectors.

KSQL (now ksqlDB): A SQL interface for real-time stream processing.

Security features: Enhanced authentication/authorization.

Purpose: To provide a comprehensive, integrated ecosystem around Kafka for enterprise use cases, going beyond just the basic broker.

Usability: Very powerful for building full-fledged Kafka-based data platforms, but it brings the entire Confluent ecosystem, which might be overkill for very simple use cases if you only need the broker.

Why confluentinc/cp-kafka is Frequently Used (and Often Preferred):
Even if you're not paying for Confluent's enterprise support, their Docker images are very popular for several reasons:

Completeness & Ecosystem: For many real-world use cases, you don't just need the Kafka broker; you need Schema Registry, Kafka Connect, and robust monitoring. The confluentinc/cp-kafka images (and others in the confluentinc namespace like cp-schema-registry, cp-kafka-connect) provide a pre-packaged, compatible, and well-tested way to deploy this entire ecosystem. It simplifies setup greatly compared to getting each component separately.

Expertise & Maintenance: Confluent is the commercial entity most deeply involved with Kafka's development. Their images are generally very well-maintained, kept up-to-date with the latest Kafka versions, and often include performance optimizations or critical bug fixes that might take longer to appear in community-maintained "official" images.

Production Readiness: Confluent's focus is on enterprise deployments. Their images are often designed with production best practices in mind, including sensible default configurations, logging, and metrics.

Documentation & Community: Confluent has extensive documentation and a large community around their platform, making it easier to troubleshoot and find examples.

In summary, while apache/kafka gives you the pure open-source core, bitnami/kafka offers a streamlined, well-packaged version of that core. confluentinc/cp-kafka provides the core Kafka broker plus a powerful, integrated suite of tools and features from the Confluent Platform, making it a highly attractive option for developers and organizations building comprehensive data streaming solutions. People choose it because it often saves significant time and effort in integrating and managing the broader Kafka ecosystem.

* You're asking a fantastic question that gets to the heart of real-time data processing and why Kafka is so powerful! Your assumptions are good starting points, but let's refine them.

Batch Processing vs. Streaming Processing (The Core Difference)
Imagine you have a stack of mail:

Batch Processing: Is like waiting for all your mail to arrive at the end of the day or week, then opening it all at once and dealing with it. You process it in big "batches." This is good for things that don't need immediate action, like monthly billing.

Streaming Processing: Is like having a special delivery person who brings each piece of mail to you the second it arrives. You open and deal with it immediately. This is crucial for things that need instant responses, like fraud detection, live dashboards, or real-time recommendations.

How Apache Kafka Works (The "Central Nervous System" for Streaming Data)
Apache Kafka is like a super-efficient, highly reliable "postal service" or "messaging highway" designed specifically for real-time events. It doesn't just call APIs over and over; it acts as a central hub where data is constantly flowing, being sent by some and picked up by others.


Here's how its main parts fit together:

Events/Messages:

This is the smallest unit of data flowing through Kafka. Think of it as a single piece of information, like "User X clicked on Product Y," "Customer Z made a payment," or "Temperature sensor A read 25°C."

Topics (The "Categories" or "Channels"):

Imagine a Kafka system has many different "categories" or "channels" for different types of events. These are called Topics.

For example, you might have a user_clicks topic, a payments topic, or a sensor_readings topic.

When an event happens, it's sent to the relevant topic.

Producers (The "Data Senders"):

These are applications or systems that generate data and send it into Kafka.

They are like the people writing and mailing letters.

Example (Reddit Data): Your Python script reading from the Reddit API would be a Producer. It takes new Reddit posts/comments and "produces" them as events to a reddit_posts topic in Kafka.

Consumers (The "Data Receivers"):

These are applications or systems that read data from Kafka.

They are like the people who pick up mail from their mailbox.

Crucially: Multiple Consumers can read from the same topic independently, at their own pace, without affecting each other. One might be building a dashboard, another might be analyzing sentiment, and another might be storing data in a database.

Example (Transformation): Your Azure Databricks Spark job would be a Consumer. It continuously reads new Reddit posts from the reddit_posts topic to transform them.

Brokers (The "Mail Sorting & Storage Hubs"):

These are the actual servers that make up the Kafka system. A group of Brokers is called a Kafka cluster.

What they do:

When a Producer sends an event to a Topic, the Broker receives it and stores it reliably (writes it to disk). This is key – Kafka doesn't just forward; it stores.

They keep events for a configurable amount of time (e.g., 7 days, 30 days). This means Consumers don't have to be online all the time to catch every event; they can read from where they left off.

They manage which events go to which topics and handle requests from Consumers to read from specific parts of a topic.

They ensure high availability and fault tolerance: if one Broker goes down, others take over.

Why Kafka is Used for Real-Time Streaming (and not just repeatedly calling APIs):
You're right that streaming APIs give out data constantly. Kafka doesn't call an API over and over; it receives data from APIs (via Producers) and acts as a central, high-throughput, fault-tolerant buffer and distribution system.

Decoupling (The Main Reason):

Kafka acts as a buffer and mediator between systems. The Producer (e.g., your Reddit script) doesn't need to know who will use the data or how many systems will consume it. It just "publishes" to a topic.

The Consumers (e.g., Databricks, a dashboard, a database) don't need to know where the data came from. They just "subscribe" to a topic.

This "decoupling" is huge. You can add new Consumers or change existing ones without affecting the Producer, and vice versa. In traditional direct API calls, if the API endpoint or the consuming system changes, everything might break.

Scalability: Kafka can handle millions of events per second. It's built for very high throughput.

Durability: Events are stored on disk by Brokers, so even if a Consumer goes down, it won't miss data; it can pick up from where it left off when it comes back online.

Fault Tolerance: It's designed to be highly available. If a server (Broker) fails, the data is still accessible from other Brokers.

Replayability: Because data is stored for a period, Consumers can "go back in time" and re-process old events if needed (e.g., for testing new logic or recovering from an error).

So, in essence, Kafka is the robust, scalable, and reliable pipeline that ensures real-time data flows smoothly and continuously from where it's generated to wherever it needs to be pro-essed or analyzed, acting as a central, persistent message bus rather than just a repetitive API caller.

so in a sense this is what it looks like: producer (python script calling an API reddit, news, medium) -> kafka broker <- consumer (dash board, apache spark, data warehouse, database). And that a kafka broker consists of multiple topics/categories, and each in category there is an event of the similar category, and that multiple kafka brokers are part of a kafka cluster?

* Your understanding: producer (python script calling an API reddit, news, medium) -> kafka broker <- consumer (dash board, apache spark, data warehouse, database)

Refinement: This flow is spot on! The producer pushes data to the Kafka cluster (which is made of brokers), and consumers pull data from the Kafka cluster.

Your understanding: And that a kafka broker consists of multiple topics/categories, and each in category there is an event of the similar category, and that multiple kafka brokers are part of a kafka cluster?

Refinement on "broker consists of multiple topics/categories": This is the slight nuance. A Kafka cluster consists of multiple brokers. A topic is conceptually a logical category. That topic is then divided into partitions, and these partitions are what are distributed and hosted across the multiple Kafka brokers in the cluster.

So, a single broker doesn't "contain" multiple topics as its internal structure. Instead, a broker hosts some partitions from many different topics.

Think of it this way:

Kafka Cluster: The entire postal service building.

Brokers: Individual sorting rooms within the building.

Topics: Different types of mail (e.g., "Letters," "Packages," "Magazines").

Partitions: Different bins within a sorting room for a specific type of mail (e.g., "Letters for Manila," "Letters for Cebu"). Each sorting room (broker) might have bins for "Letters," "Packages," and "Magazines," but only specific regions.

"each in category there is an event of the similar category": Absolutely correct! All events in a given topic belong to that logical category.

"multiple kafka brokers are part of a kafka cluster": Spot on! This is fundamental to Kafka's scalability and fault tolerance.

So, to summarize your highly accurate refined understanding:

Producer (e.g., Python script fetching from Reddit API) -> Kafka Cluster (made of multiple Brokers) <- Consumer (e.g., Spark for transformation, Dashboard for real-time display, Data Warehouse for storage).

And within that Kafka Cluster, data is organized into various Topics (categories), with each topic having partitions that are distributed and stored across the Brokers. Each event within a topic belongs to that topic's category.

You've got a very solid grasp of the core concepts!

* You're asking a very important question about Kafka's architecture, especially as it's evolving!

What is Apache ZooKeeper?
At its core, Apache ZooKeeper is a distributed coordination service. Think of it as a highly reliable, centralized place where distributed applications (like Kafka) can store and manage their critical configuration information, naming data, and provide distributed synchronization. It's like a highly available, consistent "shared brain" or "directory service" for a cluster of servers.


ZooKeeper's Role for Kafka (Historically and Currently)
Historically, for a long time, ZooKeeper was absolutely mandatory for Apache Kafka. It played several crucial roles:

Broker Discovery and Cluster Membership: Brokers (Kafka servers) would register themselves with ZooKeeper when they started up and unregister when they shut down. ZooKeeper maintained the list of all active brokers in the cluster.

Controller Election: In a Kafka cluster, one broker is designated as the "controller." The controller is responsible for managing the state of the cluster, such as assigning partitions to brokers, managing topic creation/deletion, and handling leader elections for partitions. ZooKeeper was used to elect this controller and to notify other brokers if the controller changed.


Topic and Partition Metadata: Information about topics (e.g., number of partitions, replica factors) and the location of each partition's leader (which broker holds the primary copy for writes) was stored in ZooKeeper.

User Quotas: Information about user access quotas.

Access Control Lists (ACLs): Some Kafka ACLs were managed in ZooKeeper.

Is ZooKeeper Still Required for Kafka?
This is where the big change in Kafka comes in:

Traditionally (Kafka versions up to 3.x, by default): Yes, ZooKeeper was required. If ZooKeeper went down, your Kafka cluster could not elect a new controller, create new topics, or recover properly from certain failures, essentially grinding to a halt. It was often a separate deployment headache.

With KRaft (Kafka Raft Metadata) - The Future: No, ZooKeeper is NOT required.

Starting with Kafka 2.8 (introduced as a preview/early access) and becoming production-ready and the default in Kafka 3.x (specifically from Kafka 3.5 onwards, and fully from 3.7+ as the recommended mode), Kafka has implemented a new consensus protocol called KRaft (Kafka Raft Metadata).

KRaft replaces ZooKeeper's role. The metadata (broker IDs, topic configurations, controller election, etc.) is now stored directly within Kafka brokers themselves using a Raft-based distributed consensus protocol. This eliminates the need for a separate ZooKeeper cluster, simplifying Kafka's architecture, deployment, and management.

In summary:

If you're running older Kafka versions (before 3.x) or using specific deployment tools that still rely on it, then yes, ZooKeeper is required.

For modern Kafka deployments (3.x and newer, especially in KRaft mode), ZooKeeper is no longer needed. This is a significant improvement that many users are migrating towards due to the simplified operational overhead.

* so will I need a kraft image in my docker compose other than confluentinc/cp-server?

No, you generally will NOT need a separate "KRaft image" in your Docker Compose other than confluentinc/cp-server.

Here's why:

confluentinc/cp-server IS the Kafka Broker: The confluentinc/cp-server Docker image is the image for the Kafka broker itself, which means it contains the core Kafka server software.

KRaft Mode is a Configuration, Not a Separate Image: When you run Kafka in KRaft mode, you are essentially configuring the same Kafka broker software to take on additional roles.

Some cp-server instances will be configured as brokers (handling data).

Other cp-server instances will be configured as controllers (handling metadata and cluster coordination, replacing ZooKeeper).

Or, in smaller deployments, a single cp-server instance can be configured to act as both a broker and a controller (a "combined" role).

How it works in Docker Compose for KRaft:

You would define multiple services in your docker-compose.yml, all using the confluentinc/cp-server image. The distinction between them being a controller, broker, or combined is done through their environment variables and command-line arguments.

Example Snippet (simplified, for illustration):

YAML

version: '3.8'
services:
  kafka-controller-1:
    image: confluentinc/cp-server:7.5.0 # Use your desired Kafka version
    hostname: kafka-controller-1
    container_name: kafka-controller-1
    environment:
      KAFKA_NODE_ID: 100 # Unique ID for this node
      KAFKA_PROCESS_ROLES: controller # This node is a controller
      KAFKA_CONTROLLER_QUORUM_VOTERS: '100@kafka-controller-1:9093,101@kafka-controller-2:9093,102@kafka-controller-3:9093'
      KAFKA_SERVER_CLUSTER_ID: 'your-kraft-cluster-id' # Must be same for all nodes
      KAFKA_CONTROLLER_LISTENER_NAMES: 'CONTROLLER'
      KAFKA_LISTENERS: 'PLAINTEXT://kafka-controller-1:9092,CONTROLLER://kafka-controller-1:9093'
      KAFKA_ADVERTISED_LISTENERS: 'PLAINTEXT://localhost:9092' # Or external IP
      # ... other Kafka configs (log dirs, memory etc.)

  kafka-broker-1:
    image: confluentinc/cp-server:7.5.0
    hostname: kafka-broker-1
    container_name: kafka-broker-1
    environment:
      KAFKA_NODE_ID: 103 # Unique ID
      KAFKA_PROCESS_ROLES: broker # This node is a broker
      KAFKA_CONTROLLER_QUORUM_VOTERS: '100@kafka-controller-1:9093,101@kafka-controller-2:9093,102@kafka-controller-3:9093'
      KAFKA_SERVER_CLUSTER_ID: 'your-kraft-cluster-id'
      KAFKA_LISTENERS: 'PLAINTEXT://kafka-broker-1:9092'
      KAFKA_ADVERTISED_LISTENERS: 'PLAINTEXT://localhost:9094' # Or external IP
      # ... other Kafka configs
    depends_on:
      - kafka-controller-1
      - kafka-controller-2 # If you have more controllers
      - kafka-controller-3
Notice how KAFKA_PROCESS_ROLES is the key variable that tells the same confluentinc/cp-server image whether it should primarily be a controller, a broker, or broker,controller (combined).

So, you're on the right track! You'll use the same cp-server image but configure its role for KRaft mode.

* `docker pull confluentinc/<image-name>:<tag>` e.g. `docker pull confluentinc/cp-kafka:latest`
- `cp-kafka` is the Confluent official Docker image for Kafka and includes the Community Version of Kafka
- `cp-server` is a component of Confluent Platform that includes everything in the `cp-kafka` package and additional commercial features that are only available as a part of the `cp-server` package
- `cp-schema-registry` provides a centralized repository for managing and validating schemas for topic message data, and for serialization and deserialization of the data over the network.
- `cp-enterprise-control-center-next-gen` is a self-hosted web-based tool for managing and monitoring key components of Confluent Platform.

basically what we need is the kafka server, kafka schema registry, kafka control center, and zookeeper to manage the meta data of the kafka server

* 
this is maybe why kafka based azure services like azure event hubs exist? Is it also a azure cloud version of apache kafka so we don't have to go through these docker container installation processes anymore?

You're absolutely right in your intuition and connection!

Yes, that's exactly why Kafka-based or Kafka-compatible Azure services like Azure Event Hubs exist, and you're spot on that it's meant to alleviate the burden of managing Kafka clusters yourself.

Here's the clarification:

Azure Event Hubs: The Kafka-like Service

Purpose: Azure Event Hubs is a highly scalable data streaming platform and event ingestion service. Its primary purpose is to take in massive amounts of data from various sources (like your Reddit script) and make it available for multiple consumers.

Kafka-Compatibility: While Event Hubs is not Apache Kafka itself (it's a proprietary Microsoft service), Microsoft engineered it to be Kafka-compatible. This means applications written to produce or consume data from Kafka can often interact directly with Event Hubs using the Kafka API. This is a huge advantage for organizations that want to leverage their existing Kafka knowledge or applications without deploying and managing Kafka themselves.

Azure Event Hubs for Kafka: The "Cloud Kafka" Without Installation

This compatibility means that yes, you can think of it as an Azure cloud version of Apache Kafka in the sense that it provides a similar functional abstraction for producers and consumers.

The biggest benefit is exactly what you pointed out: you don't have to go through the Docker container installation processes, manage ZooKeeper, configure brokers, worry about scaling, patching, or high availability. Microsoft handles all of that for you. It's a fully managed Platform-as-a-Service (PaaS).

In short:

Self-Managed Apache Kafka (with Docker, Kubernetes, VMs): You get full control, but you're responsible for everything (installing, configuring, scaling, patching, monitoring, troubleshooting brokers, ZooKeeper, etc.). This leads to those large image sizes and operational overhead.

Azure Event Hubs (with Kafka compatibility): You get a scalable, reliable event streaming service that behaves like Kafka (from an API perspective), but Azure manages all the underlying infrastructure. You pay for throughput and storage, not for VMs or operational staff.

So, yes, it's very much designed to give you the benefits of a distributed streaming platform without the operational complexities of self-managing Apache Kafka.

so will I still or will I not hvae to configure and install kafka images anymore if I used azure event hubs?

Show thinking
No, if you use Azure Event Hubs, you will NOT have to configure and install Kafka images (like confluentinc/cp-server or bitnami/kafka) anymore.

That's precisely the main benefit of using a managed service like Azure Event Hubs. Azure handles all the underlying infrastructure, server management, scaling, patching, and high availability for you. You simply provision an Event Hubs namespace and start sending and receiving data using the Kafka API, without ever touching a Docker image or a Kafka broker installation.

* whenn we `docker exec -it broker bash` and inside use `printenv` we see the following variables
```
LANG=C.UTF-8
CLUSTER_ID=
HOSTNAME=broker
KAFKA_JMX_PORT=9101
KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1
KAFKA_CONFLUENT_LICENSE_TOPIC_REPLICATION_FACTOR=1
KAFKA_METRIC_REPORTERS=io.confluent.metrics.reporter.ConfluentMetricsReporter
KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS=0
KAFKA_JMX_HOSTNAME=localhost
container=oci
CONFLUENT_METRICS_REPORTER_TOPIC_REPLICAS=1
PWD=/
HOME=/home/appuser
KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://broker:29092,PLAINTEXT_HOST://localhost:9092
KAFKA_CONFLUENT_SCHEMA_REGISTRY_URL=http://schema-registry:8081
KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
CONFLUENT_METRICS_REPORTER_BOOTSTRAP_SERVERS=broker:29092
KAFKA_CONFLUENT_BALANCER_TOPIC_REPLICATION_FACTOR=1
COMPONENT=kafka
KAFKA_BROKER_ID=1
TERM=xterm
KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1
SHLVL=1
KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181
CONFLUENT_METRICS_ENABLE=false
CONFLUENT_SUPPORT_CUSTOMER_ID=anonymous
PATH=/home/appuser/.local/bin:/home/appuser/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1
CUB_CLASSPATH="/usr/share/java/cp-base-new/*"
_=/usr/bin/printenv
OLDPWD=/
```

* 
explain this shell file? 

```
"#!/bin/bash

set -e



if [ -e "/opt/airflow/requirements.txt" ]; then

  $(command python) pip install --upgrade pip

  $(command -v pip) install --user -r requirements.txt

fi



if [ ! -f "/opt/airflow/airflow.db" ]; then

  airflow db init && \

  airflow users create \

    --username admin \

    --firstname admin \

    --lastname admin \

    --role Admin \

    --email admin@example.com \

    --password admin

fi



$(command -v airflow) db upgrade
```


exec airflow webserver" because I'm really trying to learn how to write a docker compose file with airflow biwthout depending on the prewritten docker-compose by airflow, I want to know how the docker compose that uses airflow works also




Show thinking
This shell script is a very common pattern for entrypoint scripts in Docker containers, especially for applications like Apache Airflow. It essentially sets up and initializes the Airflow environment inside the container when it starts.

Understanding this script is a great step towards writing your own Dockerfile and docker-compose.yml for Airflow, as it reveals the essential commands needed to get Airflow running.

Let's break it down line by line:

Bash

#!/bin/bash
#!/bin/bash: This is called a "shebang." It tells the operating system to execute this script using the /bin/bash interpreter (a common Unix shell).

Bash

set -e
set -e: This is a crucial command for robust shell scripting. It means "exit immediately if a command exits with a non-zero status." In simple terms, if any command in the script fails, the script will stop right there instead of continuing and potentially causing more problems. This is important for ensuring a clean setup.

Bash
```
if [ -e "/opt/airflow/requirements.txt" ]; then
  $(command python) pip install --upgrade pip
  $(command -v pip) install --user -r requirements.txt
fi
if [ -e "/opt/airflow/requirements.txt" ]; then ... fi
```
This block checks if a file named requirements.txt exists at the /opt/airflow/ path inside the container.

/opt/airflow/requirements.txt: This file is where you would list any Python libraries (e.g., apache-airflow-providers-mysql, pandas, scikit-learn) that your Airflow DAGs or custom operators need, beyond the core Airflow installation.

`$(command python) pip install --upgrade pip`: This upgrades the pip installer tool itself to its latest version. $(command python) ensures it uses the python executable found in the system's PATH.

`$(command -v pip) install --user -r requirements.txt`: This command installs all the Python packages listed in requirements.txt.

`$(command -v pip)`: Ensures it uses the pip executable found in the system's PATH.

`--user`: Installs packages into the user's home directory within the container, which is a common practice in Docker to avoid needing root privileges for package installation after the image is built.

Purpose: This entire block ensures that any additional Python dependencies required for your Airflow environment (especially for your DAGs) are installed when the container starts up. This is dynamic, allowing you to change requirements.txt without rebuilding the entire Docker image, or to support multiple versions of DAG dependencies.

Bash
```
if [ ! -f "/opt/airflow/airflow.db" ]; then
  airflow db init && \
  airflow users create \
    --username admin \
    --firstname admin \
    --lastname admin \
    --role Admin \
    --email admin@example.com \
    --password admin
fi
```
`if [ ! -f "/opt/airflow/airflow.db" ]; then ... fi`: This block checks if the Airflow metadata database file (airflow.db) does not exist at the /opt/airflow/ path.

`/opt/airflow/airflow.db`: This is the default location for Airflow's SQLite database. SQLite is often used for development or small-scale testing because it's a file-based database and easy to set up.

`! -f`: This is a shell operator meaning "if not a regular file."

`airflow db init`: This Airflow command initializes the metadata database. It creates all the necessary tables (for DAGs, tasks, connections, variables, etc.) that Airflow needs to operate.

`&& \`: The && operator means "execute the next command ONLY if the previous command was successful." The \ is just for line continuation in the script.

`airflow users create ...`: This Airflow command creates an initial admin user for the Airflow UI (webserver). It sets the username, name, role, email, and password. This is essential for you to log into the Airflow Webserver for the first time.

Purpose: This block ensures that if you're running Airflow for the very first time (or in a fresh container without a pre-existing database volume), it automatically sets up the database and creates an admin user. This prevents you from having to manually run these commands.

Bash

`$(command -v airflow) db upgrade`
`$(command -v airflow) db upgrade`: This Airflow command upgrades the schema of the metadata database.

`$(command -v airflow)`: Ensures it uses the airflow executable found in the system's PATH.

Purpose: Airflow's database schema can change between versions. db upgrade ensures that your database tables are updated to match the version of Airflow you are running. This is important for migrations and compatibility, especially when you upgrade Airflow.

Bash

`exec airflow webserver`
`exec airflow webserver`: This is the final and crucial command.

`exec`: This shell command replaces the current shell process with the specified command (airflow webserver) without creating a new process. This is a Docker best practice because it ensures that signals (like SIGTERM when you run docker stop) are directly passed to the airflow webserver process, allowing it to shut down gracefully.

`airflow webserver`: This Airflow command starts the Airflow Webserver, which is the graphical user interface (GUI) you interact with in your browser to monitor DAGs, view logs, configure connections, etc.

Purpose: This is the primary service that this particular Docker container is designed to run.

How This Relates to Docker Compose for Airflow:
When you're building your own Docker Compose file for Airflow, this shell script would typically be set as the ENTRYPOINT or CMD in your Dockerfile for your Airflow webserver service.

Here's a simplified breakdown of how you'd build a custom Docker Compose based on understanding this script:

Dockerfile (for your custom Airflow image):

You'd start with a base image (e.g., apache/airflow:2.x.x-python3.x).

You'd copy this script into the image (e.g., COPY entrypoint.sh /entrypoint.sh).

You'd make the script executable (RUN chmod +x /entrypoint.sh).

You'd set it as the container's entrypoint (ENTRYPOINT ["/entrypoint.sh"]).

You'd also add your requirements.txt to the /opt/airflow/ directory in the Dockerfile.

Dockerfile

# Dockerfile
FROM apache/airflow:2.x.x-python3.x # Or confluentinc/cp-server if you are building an agent from that

# Copy your custom requirements.txt if needed
COPY requirements.txt /opt/airflow/requirements.txt

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the entrypoint to your script
ENTRYPOINT ["/entrypoint.sh"]
docker-compose.yml (to orchestrate services):

You'd define services like webserver, scheduler, and a database (e.g., PostgreSQL or MySQL, not SQLite for production) that your Airflow components will use.

You'd map volumes for DAGs and logs.

You'd pass environment variables (like database connection details) to your Airflow services.

YAML

# docker-compose.yml (simplified example)
version: '3.8'
services:
  postgres:
    image: postgres:13
    environment:
      POSTGRES_USER: airflow
      POSTGRES_PASSWORD: airflow
      POSTGRES_DB: airflow
    ports:
      - "5432:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data # Persist database data

  airflow-webserver:
    build: . # Build from your Dockerfile in the current directory
    command: webserver # This will be executed by your entrypoint.sh
    environment:
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres:5432/airflow # Connect to PostgreSQL
      AIRFLOW__CORE__LOAD_EXAMPLES: 'False' # Don't load example DAGs
      # ... other Airflow environment variables
    ports:
      - "8080:8080"
    volumes:
      - ./dags:/opt/airflow/dags   # Mount your DAGs
      - ./logs:/opt/airflow/logs   # Persist logs
      - ./requirements.txt:/opt/airflow/requirements.txt # Ensure requirements is there for entrypoint script
    depends_on:
      - postgres

  airflow-scheduler:
    build: .
    command: scheduler
    environment:
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres:5432/airflow
      # ...
    volumes:
      - ./dags:/opt/airflow/dags
      - ./logs:/opt/airflow/logs
      - ./requirements.txt:/opt/airflow/requirements.txt
    depends_on:
      - postgres
      - airflow-webserver # Scheduler needs webserver/DB to be ready

volumes:
  pg_data:
By understanding this entrypoint script, you now have a clear picture of the essential steps Airflow needs during startup, which empowers you to configure and troubleshoot your own Dockerized Airflow environments effectively.


that's a nice explanation. What about this? "webserver:

    image: apache/airflow:2.6.0-python3.9

    command: webserver

    entrypoint: ['/opt/airflow/script/entrypoint.sh']

    depends_on:

      - postgres

    environment:

      - LOAD_EX=n

      - EXECUTOR=Sequential

      - AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@postgres:5432/airflow

      - AIRFLOW_WEBSERVER_SECRET_KEY=this_is_a_very_secured_key

    logging:

      options:

        max-size: 10m

        max-file: "3"

    volumes:

      - ./dags:/opt/airflow/dags

      - ./script/entrypoint.sh:/opt/airflow/script/entrypoint.sh

      - ./requirements.txt:/opt/airflow/requirements.txt

    ports:

      - "8080:8080"

    healthcheck:

      test: ['CMD-SHELL', "[ -f /opt/airflow/airflow-webserver.pid ]"]

      interval: 30s

      timeout: 30s

      retries: 3

    networks:

      - confluent



  scheduler:

    image: apache/airflow:2.6.0-python3.9

    depends_on:

      webserver:

        condition: service_healthy

    volumes:

      - ./dags:/opt/airflow/dags

      - ./script/entrypoint.sh:/opt/airflow/script/entrypoint.sh

      - ./requirements.txt:/opt/airflow/requirements.txt

    environment:

      - LOAD_EX=n

      - EXECUTOR=Sequential

      - AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@postgres:5432/airflow

      - AIRFLOW_WEBSERVER_SECRET_KEY=this_is_a_very_secured_key

    command: bash -c "pip install -r ./requirements.txt && airflow db upgrade && airflow scheduler"

    networks:

      - confluent



  postgres:

    image: postgres:14.0

    environment:

      - POSTGRES_USER=airflow

      - POSTGRES_PASSWORD=airflow

      - POSTGRES_DB=airflow

    logging:

      options:

        max-size: 10m

        max-file: "3"

    networks:

      - confluent"




Show thinking
This is a great docker-compose.yml file to analyze, as it demonstrates how multiple services are orchestrated to run a functional Airflow environment. It clearly separates the concerns of each Airflow component.

Let's break down each service definition:

Overall docker-compose.yml Purpose
This file uses Docker Compose to define and run a multi-container Airflow application. It specifies three services: webserver, scheduler, and postgres, and defines how they interact and are configured.

1. webserver Service
This service runs the Airflow UI, which you access in your browser.

image: apache/airflow:2.6.0-python3.9:

Specifies the Docker image to use for this service. It's using an official Apache Airflow image for version 2.6.0 with Python 3.9. This means you don't need a separate Dockerfile for this specific image unless you want to add custom layers on top.

command: webserver:

This is the primary command that will be executed inside the container after the entrypoint script (if one is defined) runs. In this case, it tells the Airflow image to start the web server component.

entrypoint: ['/opt/airflow/script/entrypoint.sh']:

This overrides the default entrypoint of the apache/airflow image. It tells Docker to run your custom entrypoint.sh script (the one we just discussed) before executing the command: webserver.

Why custom entrypoint here? It's common to use a custom entrypoint to perform pre-startup tasks like installing requirements.txt or initializing the database, as you saw in the script.

depends_on: - postgres:

This specifies that the webserver service will not start until the postgres service is running. This helps ensure the database is available when Airflow tries to connect to it.

environment::

These are environment variables passed into the container, which Airflow uses for configuration.

LOAD_EX=n: n likely stands for "no," meaning it tells Airflow not to load the example DAGs that come with the Airflow installation.

EXECUTOR=Sequential: Specifies the Airflow executor. SequentialExecutor is used for local development/testing where tasks run one after another on the same machine. For production, you'd typically use CeleryExecutor (with Redis/RabbitMQ) or KubernetesExecutor.

AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@postgres:5432/airflow: This is the most crucial Airflow environment variable. It defines the connection string to the metadata database.

postgresql+psycopg2: Specifies the database type and Python driver.

airflow:airflow: Username and password.

@postgres:5432/airflow: The hostname (postgres is the service name defined in docker-compose.yml, which resolves to its IP within the Docker network), port, and database name.

AIRFLOW_WEBSERVER_SECRET_KEY=this_is_a_very_secured_key: A secret key used by the webserver for session management and security. Important: In a real production setup, this must be a truly random and securely managed key, not "this_is_a_very_secured_key."

logging::

options: max-size: 10m: Limits the size of a single log file generated by this container to 10 megabytes.

max-file: "3": Keeps a maximum of 3 rotation log files. This helps prevent logs from filling up your disk.

volumes::

These mount local directories/files from your host machine into the container, making them accessible inside.

./dags:/opt/airflow/dags: Mounts your local dags folder (where your DAG Python files are) into the container's /opt/airflow/dags directory. This means any changes you make to your DAGs locally are immediately reflected in the container.

./script/entrypoint.sh:/opt/airflow/script/entrypoint.sh: Mounts your local entrypoint.sh script into the container at the specified path. This ensures your custom script is available and used.

./requirements.txt:/opt/airflow/requirements.txt: Mounts your local requirements.txt file into the container, allowing the entrypoint.sh script to find and install your dependencies.

ports: - "8080:8080":

Maps port 8080 on your host machine to port 8080 inside the container. This allows you to access the Airflow Webserver from your browser at http://localhost:8080.

healthcheck::

Docker Compose uses this to determine if the service is "healthy."

test: ['CMD-SHELL', "[ -f /opt/airflow/airflow-webserver.pid ]"]: This command checks if a file named airflow-webserver.pid exists inside the container. This file is typically created by the Airflow webserver process when it starts successfully, so its presence indicates the webserver is running.

interval: 30s: Check every 30 seconds.

timeout: 30s: Wait up to 30 seconds for the test command to complete.

retries: 3: If the test fails 3 times in a row, mark the service as "unhealthy."

networks: - confluent:

Connects this service to a user-defined Docker network named confluent. This allows services in this network to communicate with each other using their service names (e.g., webserver can connect to postgres).

2. scheduler Service
This service is the heart of Airflow, responsible for monitoring DAGs, triggering tasks, and managing their state.

image: apache/airflow:2.6.0-python3.9: Same Airflow image as the webserver.

depends_on: webserver: condition: service_healthy:

This is a stronger dependency than just depends_on: - webserver. It means the scheduler service will only start if the webserver service is not just running, but has also passed its healthcheck. This ensures the webserver is fully ready, and implicitly, the database connection used by the webserver (and scheduler) is also stable.

volumes:: Same volume mounts as the webserver, which is important because both services need access to the same DAG files and requirements.txt.

environment:: Same Airflow configuration environment variables as the webserver to ensure consistency.

command: bash -c "pip install -r ./requirements.txt && airflow db upgrade && airflow scheduler":

This command is different from the webserver and directly executes a series of commands to set up and run the scheduler.

bash -c "...": Runs the following string as a Bash command.

pip install -r ./requirements.txt: Installs Python dependencies (similar to the entrypoint script).

airflow db upgrade: Upgrades the database schema (similar to the entrypoint script).

airflow scheduler: Starts the Airflow scheduler process.

Why directly in command here? It's common for simpler scheduler setups to put these commands directly in command if there's no complex shared entrypoint script, or if the ENTRYPOINT of the base image is simply airflow. In this specific setup, it looks like the webserver uses a custom entrypoint.sh for its specific startup flow, while the scheduler uses a direct command that performs similar setup steps.

networks: - confluent: Connects to the same network as other services.

3. postgres Service
This service provides the PostgreSQL database for Airflow's metadata.

image: postgres:14.0:

Uses a standard PostgreSQL Docker image version 14.0.

environment::

POSTGRES_USER: airflow: Sets the default database user.

POSTGRES_PASSWORD: airflow: Sets the password for that user.

POSTGRES_DB: airflow: Sets the default database name. These credentials match the SQL_ALCHEMY_CONN string in the Airflow services.

logging:: Same logging options as the webserver.

networks: - confluent: Connects to the same network.

4. networks:
confluent:: This defines a custom bridge network named confluent. All services attached to this network can communicate with each other using their service names as hostnames (e.g., airflow-webserver can talk to postgres using the hostname postgres). This isolates your application's network traffic from other Docker containers on your host.

This docker-compose.yml provides a self-contained, multi-service Airflow environment that handles database setup, dependency installation, and service startup in a robust way for local development or testing.

* ah so each docker image will have its own way on how it can be configured e.g. postgres for instance can be setup with your own user and password by just specifying the environment variables this container will hvae as I assume when the postgres container is started it creates a server from the environment variables we provided e.g.

via dockerfile
```
docker run -d \
	--name some-postgres \
	-e POSTGRES_PASSWORD=mysecretpassword \
	-e PGDATA=/var/lib/postgresql/data/pgdata \
	-v /custom/mount:/var/lib/postgresql/data \
	postgres
```

or via `docker-compose.yaml`

```
services:
  some-postgres:
    image: postgres
    restart: always
    # set shared memory limit when using docker compose
    shm_size: 128mb
    # or set shared memory limit when deploy via swarm stack
    #volumes:
    #  - type: tmpfs
    #    target: /dev/shm
    #    tmpfs:
    #      size: 134217728 # 128*2^20 bytes = 128Mb
    environment:
      POSTGRES_PASSWORD: example
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - /custom/mount:/var/lib/postgresql/data
```

* when the containers namely the kafka zookeeper, schema registry, broker, and control center are finally spun up/started we can visit the control center UI itself representing the kafka brokers topics, producers, and consumers at `http://localhost:9021`

the control center container is just a UI of the kafka brokers itself. Basically confluents apache kafka under the hood already installs and runs the necessary commands like downloading apache kafka itself (`tar -xzf kafka_2.13-4.1.0.tgz`), creates the kafka cluster and the brokers in these clusters, only now we have a UI hosted by the control center container provided by confluent

the way we can create a topic manually assuming apache kafka or the apache kafka that goes with the confluentinc/cp-server image is installed is through the command `bin/kafka-topics.sh --create --topic quickstart-events --bootstrap-server localhost:9092` and we can manually check this if we are indeed in using docker containers by entering the broker container using the confluentinc/cp-server image which essentially the kafka broker itself but can only be operated through command line. So we use this command and we will see that it will be reflected in the UI of the kafka broker which is the control center which allows us to see in a visual representation all the goes on in the kafka broker.

run `bin/kafka-topics.sh --create --topic subreddit-topic --bootstrap-server localhost:9092` or `bin/kafka-topics --create --topic subreddit-topic --bootstrap-server localhost:9092` 

and the way we finally push data into the kafka broker is through kafka's **producer** through the command `bin/kafka-console-producer.sh --topic subreddit-topic --bootstrap-server localhost:9092` (but again we can alternatively do this via the control center UI) 

isipin mo parang malaking data storage yung kafka cluster and its brokers by way of its distributed storage where it is specifically for data that comes in at lightning speed and on a daily basis that unfortunately can't be processed by a simple ETL/ELT pipeline alone, since if this was the case sa una pa lang during extraction and transformation it may be probable na habang nagtrtransform pa lang ng data ay meron na dumadating na bagong data in the pipeline which essentially creates a bottle neck and essentially clogs the pipeline because there is still data being processed and transformed at hand, this is why kafka solves this problem by essentially decoupling this ingestion process by a pipeline and the data coming in on a daily basis at perhaps unmanagable speeds.

and when we want the pipeline to finally ingest data we can just use kafka's consumer which essentially returns us the data momentarily stored in the kafka clusters and brokers through the command `bin/kafka-console-consumer.sh --topic subreddit-topic --bootstrap-server localhost:9092` (but again we can alternatively do this via the control center UI)

when we enter messages or events in the kafka producer via CLI provided that the kafka consumer is running in unison with this producer we will see that as each event is entered the consumer can basically return this value to us, and when we operate this process via a script like a python script we can essentially see the contents or data itself returnned by the kafka consumer and have our ETL/ELT pipeline ingest this data for analyses or machine learning and other big data processes

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

* is it possible to use aws kinesis and python kafka producer and consumer objects together, by specifying the broker endpoint? Does aws kinesis even have a broker endpoint, because I just watched a tutorial on using azure event hub and it can use the endpoint string as the brokers endpoint itself. Is this possible on aws isnted of using aws ec2 to maybe install kafka in it and then have this VMs endpoint be used as the broker endpoint by the python kafka producer and consumers in the scripts that do use these classes? The idea is to either:
- have an aws ec2 virutal machine instance and have kafka be installed there, run the server and use the kafka producer send the data to the endpoint of this virutal machine,

Google Search
It's a great question, and you've pinpointed the key difference between the streaming services offered by AWS and Azure!

Here is the breakdown of why your Azure experience doesn't directly map to Kinesis, and what the correct AWS solution is.

1. AWS Kinesis Data Streams vs. Kafka
The answer to your core question is No, you cannot use a standard Python Kafka producer/consumer (like kafka-python or confluent-kafka-python) to connect to AWS Kinesis Data Streams (KDS) by specifying a broker endpoint.

AWS Kinesis Data Streams (KDS): KDS is a proprietary AWS service that does not natively support the open-source Apache Kafka protocol. It uses its own API, which means standard Kafka client objects are incompatible. Kinesis does not have a "broker endpoint" in the way Kafka clients expect a bootstrap-servers list.

Azure Event Hubs (AEH): Azure Event Hubs is special because it offers an "Event Hubs for Apache Kafka" feature, which means it implements the Kafka protocol. This is what allows you to successfully use a standard Python Kafka client with an AEH endpoint string.

2. The Correct AWS Solution: Amazon MSK
The AWS service that is the direct equivalent of the Kafka-compatible feature in Azure Event Hubs is Amazon Managed Streaming for Apache Kafka (MSK).

Amazon MSK is a fully managed service for Apache Kafka.

It provides a broker endpoint: When you set up an MSK cluster, AWS provides you with a list of bootstrap broker strings (e.g., b-1.yourcluster.xxxx.c3.kafka.us-east-1.amazonaws.com:9092, b-2.yourcluster.xxxx.c3.kafka.us-east-1.amazonaws.com:9092).

It uses the standard Kafka protocol: Because MSK is running native Apache Kafka, you can seamlessly plug these bootstrap broker strings into your existing Python Kafka producer and consumer objects (e.g., setting the bootstrap.servers configuration) without changing your code logic.

In short: Use Amazon MSK, not AWS Kinesis Data Streams.

3. The EC2 Question (Why MSK is Better)
You do not need to install Kafka on an AWS EC2 instance.

EC2 (Self-Managed Kafka): Installing Kafka on EC2 would work, as the EC2 IP would be your broker endpoint. However, this is a self-managed approach, meaning you're responsible for cluster setup, scaling, monitoring, patching, and fault tolerance.

MSK (Managed Kafka): Amazon MSK handles all that operational overhead for you (provisioning, configuration, patching, and fault tolerance across Availability Zones). It is the recommended, simplified, and cloud-native way to run Apache Kafka on AWS, and it directly supports your existing Python Kafka client scripts.



You are correct that Amazon MSK often requires an EC2 instance—but only for client access and not for running the Kafka brokers themselves.

Here is a breakdown of why you still need an EC2, why AWS Kinesis Data Streams (KDS) might be an easier alternative, and a modern way to use MSK without always needing a client EC2.

1. Why MSK Often Needs an EC2 Client 🧠
The reason you see EC2 in MSK tutorials is due to network security:

MSK Cluster Security: For security, MSK clusters are typically deployed within your Amazon VPC (Virtual Private Cloud) and do not have public internet access.

Client Access: To connect to the MSK brokers (producers and consumers), your client application must be within the same VPC or have properly configured network access (like VPC Peering or Transit Gateway).

The Tutorial Standard: The easiest way to demonstrate connecting a Kafka client (like a Python script using the kafka-python library) to the MSK cluster is by launching a simple EC2 instance inside that same VPC and running the script there. This EC2 instance acts as your client machine, not a Kafka broker.

This is a setup requirement, not a Kafka operational requirement. The actual Kafka management is still handled by AWS.

2. Is AWS Kinesis Data Streams (KDS) Easier?
Yes, Kinesis Data Streams (KDS) can be significantly easier for purely AWS-native workloads, especially if you want to avoid dealing with the Kafka protocol and networking setup.

Feature	AWS Kinesis Data Streams (KDS)	Amazon MSK (Managed Apache Kafka)
Protocol	Proprietary AWS API (Boto3 SDK)	Standard Apache Kafka Protocol
Python Client	AWS Boto3 SDK (kinesis client)	Standard Kafka Libraries (kafka-python)
Networking/Security	Public API Endpoint (Access controlled by IAM). No need for VPC client access for some use cases (e.g., Lambda).	VPC-only broker access. Requires careful VPC/Security Group setup for client machines.
Management Overhead	Serverless: Fully managed, scales by adding/removing shards.	Managed Cluster: AWS manages brokers, but you still deal with Kafka configuration (topics, partitions).
Ecosystem	Best for AWS-only services (Lambda, Firehose, S3).	Best for Kafka-native tools and existing open-source Kafka applications.

Export to Sheets
If you are starting from scratch and your consumers are other AWS services (like AWS Lambda or Kinesis Data Firehose), Kinesis is simpler because you don't have to manage network connectivity to a broker endpoint. You just use the official Boto3 SDK for Python to put records into the stream.

3. Modern MSK Solutions (No EC2 Required)
To address the complication of the client EC2 instance, AWS now offers a simpler option:

Amazon MSK Serverless
For MSK Serverless clusters:

You don't need to choose broker types or manually scale; AWS handles it.

More importantly, you can use AWS IAM to control client access. This allows you to integrate seamlessly with other services:

AWS Lambda: A Lambda function can be configured as an event source, acting as a consumer without needing an EC2 instance.

Containers (ECS/EKS): Your producer/consumer applications running in AWS Fargate or EKS containers can connect to MSK using the IAM role attached to the task/pod, simplifying network setup.

Conclusion:

If you must use your existing Python Kafka producer/consumer code with the broker endpoint configuration, you must use Amazon MSK. The EC2 requirement is for client connectivity, which can be mitigated with modern MSK Serverless clusters and IAM-based access.

If your primary goal is the simplest possible streaming solution on AWS, and you are open to using the AWS Boto3 SDK instead of the Kafka libraries, AWS Kinesis Data Streams (KDS) is the easier, fully serverless option with less complex networking.


* Cassandra DB could be a viable option for storing real time data streamed from kafka

Key characteristics of Cassandra include:
NoSQL and Wide-Column Store: Cassandra is a non-relational database, meaning it doesn't use the traditional table-based relational model. Instead, it's a wide-column store, organizing data into keyspaces and tables with flexible schemas.
Distributed Architecture: It employs a peer-to-peer architecture, where every node in a cluster is equal, eliminating single points of failure and enabling horizontal scalability. Data is partitioned and replicated across these nodes.
High Availability and Fault Tolerance: Data replication across multiple nodes and data centers ensures continuous service even during hardware failures or planned downtime.
Linear Scalability: Cassandra can scale horizontally by adding new nodes to the cluster without downtime, and it automatically redistributes data for load balancing.
High Write Throughput: It is optimized for write-intensive workloads, making it suitable for applications requiring high-volume data ingestion, such as logging, metrics, and IoT data.
Cassandra Query Language (CQL): Data management and interaction with Cassandra are performed using CQL, a SQL-like language.
Use Cases: Cassandra is widely used in applications requiring immense scale, high availability, and real-time data processing, including e-commerce, content management, fraud detection, and IoT device management.

* running the python script that dumps the api data into kafka event queue in airflow container does not seem to work and spits out 
```
Traceback (most recent call last):
  File "/opt/airflow/dags/operators/fetch_reddit_data.py", line 98, in <module>
    producer = KafkaProducer(
               ^^^^^^^^^^^^^^
  File "/home/airflow/.local/lib/python3.11/site-packages/kafka/producer/kafka.py", line 481, in __init__
    client = self.config['kafka_client'](
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/airflow/.local/lib/python3.11/site-packages/kafka/client_async.py", line 262, in __init__
    self.config['api_version'] = self.check_version()
                                 ^^^^^^^^^^^^^^^^^^^^
  File "/home/airflow/.local/lib/python3.11/site-packages/kafka/client_async.py", line 1074, in check_version
    raise Errors.NoBrokersAvailable()
kafka.errors.NoBrokersAvailable: NoBrokersAvailable
``` 

# Articles, Videos, Papers:
* using reddit api using python wrapper praw: https://praw.readthedocs.io/en/stable/getting_started/quick_start.html
* creating a client secret and id for reddit api: https://github.com/reddit-archive/reddit/wiki/OAuth2
* examples on using oauth2 for reddit api: https://github.com/reddit-archive/reddit/wiki/OAuth2-Python-Example
* news api for real time news: https://newsapi.org/docs
* public data streaming apis: https://github.com/bytewax/awesome-public-real-time-datasets
* public apis: https://github.com/public-apis/public-apis
* apache kafka by techworldwithnana: https://www.youtube.com/watch?v=Ch5VhJzaoaI&list=PLCBT00GZN_SAzwTS-SuLRM547_4MUHPuM&index=2&pp=gAQBiAQB0gcJCcEJAYcqIYzv
* apache kafka in 6 minutes: https://www.youtube.com/watch?v=Ch5VhJzaoaI&list=PLCBT00GZN_SAzwTS-SuLRM547_4MUHPuM&index=2&pp=gAQBiAQB0gcJCcEJAYcqIYzv
* configuring confluent kafka with docker: https://docs.confluent.io/platform/current/installation/docker/config-reference.html
* unifying kafka article: https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying
* parsing reddit post comments: https://medium.com/@arthurccavalcanti/parsing-reddit-comments-with-praw-f5d6aa221db3
* fetching data from api using python and dumping to kakfa: https://medium.com/@abdulmoizofficial0/fetch-data-from-api-in-real-time-using-apache-kafka-0b780c943b9a