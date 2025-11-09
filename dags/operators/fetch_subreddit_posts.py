import os
import praw 
import pyarrow as pa
import pyarrow.parquet as pq
import datetime as dt
import logging
import pprint

from pyarrow.fs import S3FileSystem
from praw.models.comment_forest import CommentForest, MoreComments
from praw.models.reddit.submission import Submission
from praw.models.subreddits import Subreddit
from deltalake import DeltaTable, write_deltalake

from uuid import uuid4
from pathlib import Path
from dotenv import load_dotenv
from argparse import ArgumentParser

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

def extract_posts(subreddit: Subreddit, limit: int, bucket_name, folder_name, object_name, is_local):
    """
    extracts all comments and replies from a given post
    in a subreddit then structured into a pyarrow table
    for later writing to s3 in a delta format
    """

    # collector for comments and replies
    data = []
    for submission in subreddit.hot(limit=limit):
        # print(submission.__dict__)

        # this is a static variable that we will need to append 
        # new comments/replies but also need to be unchanged/immuted
        submission_dict = submission.__dict__
        datum = {
            "post_title": submission_dict.get("title"),
            "post_score": submission_dict.get("score"),
            "post_id": submission_dict.get("id"),
            "post_url": submission_dict.get("url"),
            "post_name": submission_dict.get("name") if submission_dict.get("name") else "[deleted]",
            "post_author_name": submission_dict.get("author").name if submission_dict.get("author") else "[deleted]",
            "post_body": submission_dict.get("selftext"),
            "post_created_at": dt.datetime.fromtimestamp(submission_dict.get("created")),
            "post_edited_at": dt.datetime.fromtimestamp(submission_dict.get("edited")),
            "added_at": dt.datetime.now()
        }
        # print(datum)

        pprint.pprint(datum)
        data.append(datum)

    # convert the list of dictionaries/records to pyarrow table
    post_comments_table = pa.Table.from_pylist(data)
    logger.info(f"posts table shape:{post_comments_table.shape}")



if __name__ == "__main__":
    # python fetch_subreddit_posts.py --bucket_name forums-analyses-bucket --object_name raw_reddit_posts
    # python fetch_subreddit_posts.py --bucket_name ../../include/data --object_name raw_reddit_posts --local
    # parse arguments
    parser = ArgumentParser()
    parser.add_argument("--bucket_name", type=str, default="forums-analyses-bucket", help="represents the name of provisioned bucket in s3")
    parser.add_argument("--object_name", type=str, default="raw_reddit_posts", help="represents the name of provisioned object/filename in s3")
    parser.add_argument("--folder_name", type=str, default="", help="represents the name of folder containing the object/filename in s3 bucket")
    parser.add_argument("--subreddit_name", type=str, default="KpopDemonHunters", help="represents the subreddit to scrape posts comments in")
    parser.add_argument("--limit", type=int, default=1, help="represents the limit to the number of posts to scrape on reddit")
    parser.add_argument("--local", action="store_true", help="represents if the bucket name and object is a local path to the delta file if user decides not to write in s3")
    args = parser.parse_args()

    bucket_name = args.bucket_name
    object_name = args.object_name
    folder_name = args.folder_name
    subreddit_name = args.subreddit_name
    is_local = args.local

    # load env variables
    env_dir = Path('../../').resolve()
    load_dotenv(os.path.join(env_dir, '.env'))
    
    # get env variables
    aws_creds = {
        "access_key": os.environ.get("AWS_ACCESS_KEY_ID"),
        "secret_key": os.environ.get("AWS_SECRET_ACCESS_KEY"),
        "region": os.environ.get("AWS_REGION_NAME"),
    }

    REDDIT_CLIENT_ID = os.environ.get('REDDIT_CLIENT_ID') 
    REDDIT_CLIENT_SECRET = os.environ.get('REDDIT_CLIENT_SECRET')
    REDDIT_USERNAME = os.environ.get('REDDIT_USERNAME')
    REDDIT_PASSWORD = os.environ.get('REDDIT_PASSWORD')
    
    user_agent = f"desktop:com.sr-analyses-pipeline:0.1 (by u/{REDDIT_USERNAME})"

    # connect to reddit client
    reddit = praw.Reddit(
        client_id=REDDIT_CLIENT_ID,
        client_secret=REDDIT_CLIENT_SECRET,
        username=REDDIT_USERNAME,
        password=REDDIT_PASSWORD,
        user_agent=user_agent,
    )

    # look for subreddit to search posts comments in
    subreddit = reddit.subreddit(subreddit_name)

    extract_posts(
        subreddit, 
        limit=args.limit, 
        bucket_name=bucket_name, 
        folder_name=folder_name, 
        object_name=object_name, 
        is_local=is_local
    )

    # write pyarrow table as parquet in s3 bucket
    # https://arrow.apache.org/docs/python/generated/pyarrow.fs.S3FileSystem.html