# Techonologies:
* DBT - for transformation logic inside the data warehouse itself
* Snowflake/Motherduck - for data warehousing. I'll use motherduck for testing sql code since snowflake only has a trial of 30 days
* Praw - for extracting reddit data. No need for kakfa here now since data scraping will only happen on a daily basis and will not likely imply a high throughput process like a per second need to scrape data because of the volume of data being posted per second kind of like meta's messenger or any kind of application that receives transactions on a per second basis
* AWS S3/azure data lake - for storing the raw scraped data as parquet in a single staging layer, as idea will be to load this raw parquets as data into the data warehouse and once this raw data is loaded as a table in a data warehouse then we can then do our dbt transformations sequentially
* Apache Airflow - to orchestrate the transformations by dbt sequentially
* Terraform - to setup data lake storage and possibly the data warehouse chosen

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

* to setup aws infrastructure using terraform with we need to first configure our aws credentials terraform will need to authenticate to our aws account to setup our infrastructure. But first we need to create a IAM role/user, so we need to go to our account and create one there and assign a policy to it directly dpeending on what service we want this IAM role/user to have access to and ultimately what terraform has access to since it uses this IAM role/user credential. So we create a user and create its access key and copy its access key id and secret access key. Next assuming we have aws cli insstalled we run aws configure and there we will be prompted to enter our aws access key id and aws secret access key which we copied earlier when we created our access keys for our IAM user. Then we just enter the region to which we want and we're all set. If we run terraform init, terraform fmt, terraform apply, then we will have this resource/service set up in our account easily, depending what services we only allowed our IAM user to setup, e.g. if we only created a credential to setup an s3 bucket then terraform will only be allowed to create this service and nothing more

# Articles, Videos, Papers:

