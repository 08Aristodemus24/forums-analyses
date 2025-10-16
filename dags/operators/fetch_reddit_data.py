import requests

import os
import praw 
import json
import pyarrow as pa
import pyarrow.parquet as pq

from praw.models.comment_forest import CommentForest, MoreComments

from uuid import uuid4
from pathlib import Path
from dotenv import load_dotenv

# from kafka import KafkaProducer

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

            datum = kwargs.copy()
            datum.update({"comment": reply.body})
            # print(f"reply level: {datum}")
            reply_data.append(datum)

    return reply_data


if __name__ == "__main__":
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
    client_id = os.environ.get('REDDIT_CLIENT_ID') 
    client_secret = os.environ.get('REDDIT_CLIENT_SECRET')
    username = os.environ.get('REDDIT_USERNAME')
    password = os.environ.get('REDDIT_PASSWORD')
    user_agent = f"desktop:com.sr-analyses-pipeline:0.1 (by u/{username})"

    reddit = praw.Reddit(
        client_id=client_id,
        client_secret=client_secret,
        username=username,
        password=password,
        user_agent=user_agent,
    )

    subreddit = reddit.subreddit("KpopDemonhunters")

    # # instantiate kafka producer object
    # producer = KafkaProducer(
    #     bootstrap_servers="broker:9092",
    #     # setting this to 120 seconds 1.2m milliseconds is if it 
    #     # is taking more than 60 sec to update metadata with the Kafka broker
    #     # 1200000
    #     max_block_ms=1200000,
    #     api_version=(0, 11, 2),
    #     # auto_create_topics_enable_true=True,
    # )
    data = []
    for submission in subreddit.hot(limit=5):
        # print(submission.__dict__)

        # this is a static variable that we will need to append 
        # new comments/replies but also need to be unchanged/immuted
        datum = {
            "title": submission.title,
            "score": submission.score,
            "id": submission.id,
            "url": submission.url
        }
        # print(datum)

        # this is a list of comments
        for i, comment in enumerate(submission.comments):
            if hasattr(comment, "body"):
                datum_copy = datum.copy()
                datum_copy.update({"comment": comment.body})
                # print(f"comment level: {datum_copy}")
                data.append(datum_copy)
                
                # recursively get all replies of a comment
                reply_data = get_all_replies(comment.replies, datum)
                # print(reply_data)
                data.extend(reply_data)

    # convert the list of dictionaries/records to pyarrow table
    reddit_posts_table = pa.Table.from_pylist(data)

    # write pyarrow table as parquet in s3 bucket
    # https://arrow.apache.org/docs/python/generated/pyarrow.fs.S3FileSystem.html
    
    # what we want here is to check if an existing parquet with reddit
    # data already exists in s3, if there is none create a parquet with 
    # object id indicating its the first, and if there is already create
    # a parquet with the object id with the highest or max number 
