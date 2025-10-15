import requests

import os
import praw 
import json

from praw.models.comment_forest import CommentForest, MoreComments

from uuid import uuid4
from pathlib import Path
from dotenv import load_dotenv

from kafka import KafkaProducer

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
            print(f"reply level: {datum.keys()}")

            msg = json.dumps(datum).encode("utf-8") 
            producer.send("subreddit-topic", value=msg)

    return reply_data


if __name__ == "__main__":
    # # load env variables
    # env_dir = Path('./').resolve()
    # load_dotenv(os.path.join(env_dir, '.env'))

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

    subreddit = reddit.subreddit("Philippines")

    # instantiate kafka producer object
    producer = KafkaProducer(
        bootstrap_servers="broker:9092",
        # setting this to 120 seconds 1.2m milliseconds is if it 
        # is taking more than 60 sec to update metadata with the Kafka broker
        # 1200000
        max_block_ms=1200000,
        api_version=(0, 11, 2),
        # auto_create_topics_enable_true=True,
    )

    for submission in subreddit.hot():
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
                print(f"comment level: {datum_copy.keys()}")

                # send data to kafka broker for later ingestion
                # /consumption
                msg = json.dumps(datum_copy).encode("utf-8") 
                producer.send("subreddit-topic", value=msg)
                
                # recursively get all replies of a comment
                get_all_replies(comment.replies, datum)
    

        # {title: <title>, score: <score>, id: <id>, url: <url>, comment: <comment or reply>}

    # flush() is a blocking operation. It will pause the 
    # execution of the calling thread until all previously 
    # sent records have completed their journey, meaning 
    # they have been successfully acknowledged by the Kafka
    # brokers
    producer.flush()