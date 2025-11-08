import requests

import os
import praw 
import json
import io
import boto3
import pyarrow as pa
import pyarrow.parquet as pq
import datetime
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



def write_parq_to_bucket(aws_creds: dict, df: pa.Table, bucket_name: str, object_name: str, folder_name: str):
    """
    writes a pyarrow dataframe to an s3 bucket in parquet format. 
    What we want here is to check if an existing parquet with reddit
    data already exists in s3, if there is none create a parquet 
    with object id indicating its the first, and if there is already 
    create a parquet with the object id with the highest or max number 
    """

    try:
        # 2. Initialize S3FileSystem
        # You can pass AWS credentials or let it infer from environment variables/config files
        fs = S3FileSystem(**aws_creds)

        # 3. Specify the S3 bucket and object key (path within the bucket)
        parq_path = os.path.join(bucket_name, folder_name, object_name).replace("\\", "/")


        # 4. Write the PyArrow Table to S3
        # Use pq.write_table with the S3FileSystem and the desired path
        pq.write_table(df, parq_path, filesystem=fs)

    except Exception as e:
        logger.error(f"`{e}` has occured")

def write_delta_to_bucket(aws_creds: dict, df: pa.Table, bucket_name: str, object_name: str, folder_name: str, DELTA_PATH: str):
    """
    writes a pyarrow dataframe to an s3 bucket in delta format. 
    What we want here is to check if an existing parquet with reddit
    data already exists in s3, 
    
    As opposed to a scheme where if in s3 there is no current parquet
    and then creating a parquet with object id indicating its the first, 
    and if there is already create a parquet with the object id with 
    the highest or max number, we use a delta lake format  
    """

    # 2. Check if the Delta table already exists
    # The URI points to the S3 bucket and folder where the Delta table lives
    DELTA_DIR, _ = DELTA_PATH.rsplit("/", 1)
    os.makedirs(DELTA_DIR, exist_ok=True)
    if not alt_path:
        DELTA_PATH = os.path.join("s3://", bucket_name, folder_name, object_name).replace("\\", "/")

    try:
        # Table exists, so APPEND the new data
        logger.info(f"Delta table found at {DELTA_PATH}") 
        logger.info(f"Appending new rows...")
        
        write_deltalake(
            DELTA_PATH, 
            df,
            # Use mode="append" to transactionally add new data 
            mode="append",
            storage_options=aws_creds,
            schema_mode="merge",
            predicate="post_id = post_id"
        )
        
    except Exception as e:
        # this runs if no table exists in s3 bucket
        logger.info(f"`{e}` occured during delta update")
        logger.info(f"No Delta table found.")
        logger.info(f"Creating new table with {df.num_rows} rows...")

        # delta table is written in s3 bucket with given
        # credentials and path
        write_deltalake(
            DELTA_PATH, 
            df, 
            # Use overwrite (or error) to create the initial table
            mode="overwrite",
            storage_options=aws_creds 
        )

def get_all_replies(replies, kwargs):
    reply_data = []
    for reply in replies:
        if isinstance(reply, CommentForest):
            # Recursively call the function for the newly fetched reply
            reply_data.extend(get_all_replies(reply.children, kwargs))
        else:
            if isinstance(reply, MoreComments):
                continue
            # print(f"reply id: {reply.id}")
            # print(f"reply author: {reply.author.name if reply.author else '[deleted]'}")
            # print(f"reply body: {reply.body}")
            # print(f"reply parent id: {reply.parent_id}")
            # print(f"reply replies: {get_all_replies(reply.replies) if reply.replies else []}")
            reply_dict = reply.__dict__
            datum = kwargs.copy()
            datum.update({
                "level": "reply",
                # "reply_title": reply_dict.get("title"),
                # "reply_score": reply_dict.get("score"),
                "comment_id": reply_dict.get("id"),
                # "reply_url": reply_dict.get("url"),
                "comment_name": reply_dict.get("name") if reply_dict.get("name") else "[deleted]",
                "comment_upvotes": reply_dict.get("ups"),
                "comment_downvotes": reply_dict.get("downs"),
                "comment_created_at": datetime.datetime.fromtimestamp(reply_dict.get("created")),
                "comment_edited_at": datetime.datetime.fromtimestamp(reply_dict.get("edited")),
                "comment_author_name": reply_dict.get("author").name if reply_dict.get("author") else "[deleted]",
                "comment_author_fullname": reply_dict.get("author_fullname"),
                "comment_parent_id": reply_dict.get("parent_id"),
                "comment_body": reply_dict.get("body"),
            })
            # logger.info(f"reply level: {datum}")
            pprint.pprint(datum)
            reply_data.append(datum)

    return reply_data

def extract_posts_comments(subreddit: Subreddit, limit: int, bucket_name, folder_name, object_name, alt_path):
    """
    extracts all comments and replies from a given post
    in a subreddit then structured into a pyarrow table
    for later writing to s3 in a delta format
    """

    # collector for comments and replies
    data = []
    for submission in subreddit.hot(limit=args.limit):
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
        }
        # print(datum)

        # this is a list of comments
        for i, comment in enumerate(submission.comments):
            if hasattr(comment, "body"):
                comment_dict = comment.__dict__
                datum_copy = datum.copy()
                # datum_copy = {}
                datum_copy.update({
                    "level": "comment",
                    # "comment_title": comment_dict.get("title"),
                    # "comment_score": comment_dict.get("score"),
                    "comment_id": comment_dict.get("id"),
                    # "comment_url": comment_dict.get("url"),
                    "comment_name": comment_dict.get("name") if comment_dict.get("name") else "[deleted]",
                    "comment_upvotes": comment_dict.get("ups"),
                    "comment_downvotes": comment_dict.get("downs"),
                    "comment_created_at": datetime.datetime.fromtimestamp(comment_dict.get("created")),
                    "comment_edited_at": datetime.datetime.fromtimestamp(comment_dict.get("edited")),
                    "comment_author_name": comment_dict.get("author").name if comment_dict.get("author") else "[deleted]",
                    "comment_author_fullname": comment_dict.get("author_fullname"),
                    "comment_parent_id": comment_dict.get("parent_id"),
                    "comment_body": comment_dict.get("body"),
                })
                # logger.info(f"comment level: {datum_copy}")
                pprint.pprint(datum_copy)
                data.append(datum_copy)
                
                # recursively get all replies of a comment
                reply_data = get_all_replies(comment.replies, datum)
                # print(reply_data)
                data.extend(reply_data)

    # convert the list of dictionaries/records to pyarrow table
    post_comments_table = pa.Table.from_pylist(data)
    logger.info(f"post comments and replies table shape:{post_comments_table.shape}")

    write_delta_to_bucket(aws_creds, post_comments_table, bucket_name, object_name, folder_name, alt_path)


if __name__ == "__main__":
    # python fetch_subreddit_posts_comments.py 
    # parse arguments
    parser = ArgumentParser()
    parser.add_argument("--bucket_name", type=str, default="forums-analyses-bucket", help="represents the name of provisioned bucket in s3")
    parser.add_argument("--object_name", type=str, default="raw_reddit_posts_comments", help="represents the name of provisioned object/filename in s3")
    parser.add_argument("--folder_name", type=str, default="", help="represents the name of folder containing the object/filename in s3 bucket")
    parser.add_argument("--subreddit_name", type=str, default="KpopDemonHunters", help="represents the subreddit to scrape posts comments in")
    parser.add_argument("--limit", type=int, default=1, help="represents the limit to the number of posts to scrape on reddit")
    parser.add_argument("--alt_path", type=str, default=None, help="represents the alternative path to the delta file if user decides not to write in s3")
    args = parser.parse_args()

    bucket_name = args.bucket_name
    object_name = args.object_name
    folder_name = args.folder_name
    subreddit_name = args.subreddit_name
    alt_path = args.alt_path

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

    extract_posts_comments(
        subreddit, 
        limit=args.limit, 
        bucket_name=bucket_name, 
        folder_name=folder_name, 
        object_name=object_name, 
        alt_path=alt_path
    )

    # write pyarrow table as parquet in s3 bucket
    # https://arrow.apache.org/docs/python/generated/pyarrow.fs.S3FileSystem.html
    
   
