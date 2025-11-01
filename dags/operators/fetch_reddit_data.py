import requests

import os
import praw 
import json
import io
import boto3
import pyarrow as pa
import pyarrow.parquet as pq
import datetime

from pyarrow.fs import S3FileSystem
from praw.models.comment_forest import CommentForest, MoreComments

from uuid import uuid4
from pathlib import Path
from dotenv import load_dotenv
from argparse import ArgumentParser


def get_all_comments(comment_list):
    comments_data = []
    for comment in comment_list:
        if isinstance(comment, MoreComments):
            # Replace MoreComments with actual comments
            # limit=0 expands all MoreComments instances, threshold=0 ensures all are replaced
            comment.replace_more(limit=None, threshold=0) 
            # Recursively call the function for the newly fetched comments
            comments_data.extend(get_all_comments(comment.children))
        else:
            comments_data.append({
                "id": comment.id,
                "author": comment.author.name if comment.author else "[deleted]",
                "body": comment.body,
                "parent_id": comment.parent_id,
                "replies": get_all_comments(comment.replies) if comment.replies else []
            })
    return comments_data

def write_parq_df_to_bucket(aws_creds: dict, df: pa.Table, bucket_name: str, object_name: str, folder_name: str):
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
        table_path = os.path.join(bucket_name, folder_name, object_name).replace("\\", "/")

        # 4. Write the PyArrow Table to S3
        # Use pq.write_table with the S3FileSystem and the desired path
        pq.write_table(df, table_path, filesystem=fs)

    except Exception as e:
        print(f"Error `{e}` has occured")

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
                "ups": reply_dict.get("ups"),
                "downs": reply_dict.get("downs"),
                "created": datetime.datetime.fromtimestamp(reply_dict.get("created")),
                "edited": datetime.datetime.fromtimestamp(reply_dict.get("edited")),
                "author_name": reply_dict.get("author").name if reply_dict.get("author") else "[deleted]",
                "parent_id": reply_dict.get("parent_id"),
                "comment": reply_dict.get("body")
            })
            print(f"reply level: {datum}")
            reply_data.append(datum)

    return reply_data


if __name__ == "__main__":
    # parse arguments
    parser = ArgumentParser()
    parser.add_argument("--bucket_name", type=str, default="subreddit-analyses-bucket", help="represents the name of provisioned bucket in s3")
    parser.add_argument("--object_name", type=str, default="raw_reddit_data.parquet", help="represents the name of provisioned object/filename in s3")
    parser.add_argument("--folder_name", type=str, default="", help="represents the name of folder containing the object/filename in s3 bucket")
    args = parser.parse_args()

    bucket_name = args.bucket_name
    object_name = args.object_name
    folder_name = args.folder_name

    # load env variables
    env_dir = Path('../../').resolve()
    load_dotenv(os.path.join(env_dir, '.env'))

    # http://localhost:65010/reddit_callback
    # https://www.reddit.com/api/v1/authorize?client_id=CLIENT_ID&response_type=TYPE&state=RANDOM_STRING&redirect_uri=URI&duration=DURATION&scope=SCOPE_STRING
    

    # getting an access token to access the reddit api
    # reddit@reddit-VirtualBox:~$ curl -X POST -d 'grant_type=password&username=reddit_bot&password=snoo' --user 'p-jcoLKBynTLew:gko_LXELoV07ZBNUXrvWZfzE3aI' https://www.reddit.com/api/v1/access_token
    # {
    #     "access_token": "J1qK1c18UUGJFAzz9xnH56584l4", 
    #     "expires_in": 3600, 
    #     "scope": "*", 
    #     "token_type": "bearer"
    # }
    

    # equivalent python code to this curl request is the ff.
    
    # load env variables
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

    reddit = praw.Reddit(
        client_id=REDDIT_CLIENT_ID,
        client_secret=REDDIT_CLIENT_SECRET,
        username=REDDIT_USERNAME,
        password=REDDIT_PASSWORD,
        user_agent=user_agent,
    )

    subreddit = reddit.subreddit("KpopDemonhunters")

    data = []
    for submission in subreddit.hot(limit=1):
        # print(submission.__dict__)

        # this is a static variable that we will need to append 
        # new comments/replies but also need to be unchanged/immuted
        submission_dict = submission.__dict__
        datum = {
            "title": submission_dict.get("title"),
            "score": submission_dict.get("score"),
            "id": submission_dict.get("id"),
            "url": submission_dict.get("url"),
            "name": submission_dict.get("name") if submission_dict.get("name") else "[deleted]"
        }
        # print(datum)

        # this is a list of comments
        for i, comment in enumerate(submission.comments):
            if hasattr(comment, "body"):
                datum_copy = datum.copy()
                datum_copy.update({
                    "ups": submission_dict.get("ups"),
                    "downs": submission_dict.get("downs"),
                    "created": datetime.datetime.fromtimestamp(submission_dict.get("created")),
                    "edited": datetime.datetime.fromtimestamp(submission_dict.get("edited")),
                    "author_name": submission_dict.get("author").name if submission_dict.get("author") else "[deleted]",
                    "parent_id": submission_dict.get("parent_id"),
                    "comment": comment.body,
                })
                print(f"comment level: {datum_copy}")
                data.append(datum_copy)
                
                # recursively get all replies of a comment
                reply_data = get_all_replies(comment.replies, datum)
                # print(reply_data)
                data.extend(reply_data)

    # convert the list of dictionaries/records to pyarrow table
    reddit_posts_table = pa.Table.from_pylist(data)
    print(reddit_posts_table.shape)

    write_parq_df_to_bucket(aws_creds, reddit_posts_table, bucket_name, object_name, folder_name)

    # write pyarrow table as parquet in s3 bucket
    # https://arrow.apache.org/docs/python/generated/pyarrow.fs.S3FileSystem.html
    
   
