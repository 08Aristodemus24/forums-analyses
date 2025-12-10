import os
import pprint
import logging
import pyarrow as pa
import datetime as dt

from dotenv import load_dotenv
from pathlib import Path
from typing import Callable

from deltalake import DeltaTable, write_deltalake
from googleapiclient.discovery import build
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
logger.debug("Attempting to extract forum data.") # Will only appear in the file'


def write_delta_to_bucket(
    aws_creds: dict, 
    df: pa.Table, 
    bucket_name: str, 
    object_name: str, 
    folder_name: str, 
    is_local: bool, 
    upsert_func: Callable
):
    """
    writes a pyarrow dataframe to an s3 bucket in delta format. 
    What we want here is to check if an existing parquet with reddit
    data already exists in s3, 
    
    As opposed to a scheme where if in s3 there is no current parquet
    and then creating a parquet with object id indicating its the first, 
    and if there is already create a parquet with the object id with 
    the highest or max number, we use a delta lake format  
    """

    try:    
        # if alternative/local path is not provided 
        # modify the delta path if there is no alternative path
        # The URI points to the S3 bucket and folder where the Delta table lives
        DELTA_PATH = os.path.join("s3://", bucket_name, folder_name, object_name).replace("\\", "/") if not is_local else os.path.join(bucket_name, folder_name, object_name).replace("\\", "/")
        
        # create delta table from path and load the
        #  delta table if it already exists
        delta_table = DeltaTable(DELTA_PATH, storage_options=aws_creds) if not is_local else DeltaTable(DELTA_PATH)

        # create a delta directory if it is local
        if not "s3" in DELTA_PATH:
            DELTA_DIR, _ = DELTA_PATH.rsplit("/", 1)
            os.makedirs(DELTA_DIR, exist_ok=True)
        
        # Table exists, so APPEND the new data
        logger.info(f"Delta table found at {DELTA_PATH}") 
        logger.info(f"Inserting new and updated rows...")
        
        # update old records and insert new records 
        upsert_func(delta_table, df)
        
    except Exception as e:
        # this runs if no table exists in s3 bucket
        logger.warning(f"`{e}` occured during delta update")
        logger.warning(f"No Delta table found.")
        logger.info(f"Creating new table with {df.num_rows} rows...")

        # delta table is written in s3 bucket with given
        # credentials and path
        write_deltalake(
            DELTA_PATH, 
            df, 
            # Use overwrite (or error) to create the initial table
            mode="overwrite", 
        )


if __name__ == "__main__":
    # python fetch_youtube_data.py --bucket_name forums-analyses-bucket --object_name raw_youtube_videos_comments --kind comments
    # python fetch_youtube_data.py --bucket_name ../../include/data --object_name raw_youtube_videos_comments --kind comments --local
    # python fetch_youtube_data.py --bucket_name forums-analyses-bucket --object_name raw_youtube_videos --kind videos
    # python fetch_youtube_data.py --bucket_name ../../include/data --object_name raw_youtube_videos --kind videos --local
    # parse arguments
    parser = ArgumentParser()
    parser.add_argument("--bucket_name", type=str, default="forums-analyses-bucket", help="represents the name of provisioned bucket in s3")
    parser.add_argument("--object_name", type=str, default="raw_youtube_videos_comments", help="represents the name of provisioned object/filename in s3")
    parser.add_argument("--folder_name", type=str, default="", help="represents the name of folder containing the object/filename in s3 bucket")
    parser.add_argument("--search_query", type=str, default="Kpop Demon Hunters", help="represents the query of what videos, channels, or playlist to \
                        search in youtube to scrape transcripts, statistics, comments, and replies of youtube videos")
    parser.add_argument("--kind", type=str, default="post", help="represents the kind of data to scrape on youtube can be video statistics, snippets or comments from the video")
    # parser.add_argument
    parser.add_argument("--limit", type=int, default=1, help="represents the limit to the number of pages to keep requesting for results in youtube api")
    parser.add_argument("--local", action="store_true", help="represents if the bucket name and object is a local path to the delta file if user decides not to write in s3")
    args = parser.parse_args()

    # load env variables
    env_dir = Path('../../').resolve()
    load_dotenv(os.path.join(env_dir, '.env'))

    YOUTUBE_API_KEY = os.environ.get("YOUTUBE_API_KEY")

    # # fileDetails, processingDetails, and suggestion parts of a youtube video
    # # can only be accessed by owner of the video, so if you want to access
    # # it you won't but if you do want to access your own videos these parts
    # # can be accessed using OAuth2 credentials

    # youtube url when this is built will be
    # `https://www.youtube.com/watch?v=<video id>` or in 
    # this case `https://www.youtube.com/watch?v=SIm2W9TtzR0`
    youtube = build('youtube', 'v3', developerKey=YOUTUBE_API_KEY)
    
    params = {
        "part": ",".join(["snippet", "replies"]),
        "videoId": "yebNIHKAC4A",
        "maxResults": 100
    }
    comments = []
    next_page_token = None
    request = youtube.commentThreads().list(**params)

    for _ in range(args.limit):
        response = request.execute()
        
        for item in response["items"]:
            pprint.pprint(item)
            
            comments.append({
                "level": "comment",
                "video_id": item.get("snippet")\
                    .get("topLevelComment")\
                    .get("snippet")\
                    .get("videoId"),
                "comment_id": item.get("id"),
                "author_channel_id": item.get("snippet")\
                    .get("topLevelComment")\
                    .get("snippet")\
                    .get("authorChannelId")\
                    .get("value"),
                "channel_id_where_comment_was_made": item.get("snippet")\
                    .get("topLevelComment")\
                    .get("channelId"),
                "parent_comment_id": None,
                "text_original": item.get("snippet")\
                    .get("topLevelComment")\
                    .get("snippet")\
                    .get("textOriginal"),
                "text_display": item.get("snippet")\
                    .get("topLevelComment")\
                    .get("snippet")\
                    .get("textDisplay"),
                "published_at": item.get("snippet")\
                    .get("topLevelComment")\
                    .get("snippet")\
                    .get("publishedAt"),
                "updated_at": item.get("snippet")\
                    .get("topLevelComment")\
                    .get("snippet")\
                    .get("updatedAt"),
                "like_count": item.get("snippet")\
                    .get("topLevelComment")\
                    .get("snippet")\
                    .get("likeCount"),
                "author_display_name": item.get("snippet")\
                    .get("topLevelComment")\
                    .get("snippet")\
                    .get("authorDisplayName"),
                "author_channel_uri": item.get("snippet")\
                    .get("topLevelComment")\
                    .get("snippet")\
                    .get("authorChannelUri"),
            })

            # if replies key does not exist in items then 
            # that means there are no replies to the top 
            # level comment thereby not running the loop
            if item.get("replies"):
                for reply in item.get("replies").get("comments"):
                    comments.append({
                        "level": "reply",
                        "video_id": reply.get("snippet")\
                            .get("videoId"),
                        "comment_id": reply.get("id"),
                        "author_channel_id": reply.get("snippet")\
                            .get("authorChannelId")\
                            .get("value"),
                        "channel_id_where_comment_was_made": reply.get("snippet")\
                            .get("channelId"),
                        "parent_comment_id": reply.get("snippet")\
                            .get("parentId"),
                        "text_original": reply.get("snippet")\
                            .get("textOriginal"),
                        "text_display": reply.get("snippet")\
                            .get("textDisplay"),
                        "published_at": reply.get("snippet")\
                            .get("publishedAt"),
                        "updated_at": reply.get("snippet")\
                            .get("updatedAt"),
                        "like_count": reply.get("snippet")\
                            .get("likeCount"),
                        "author_display_name": reply.get("snippet")\
                            .get("authorDisplayName"),
                        "author_channel_uri": reply.get("snippet")\
                            .get("authorChannelUri"),
                    })

        next_page_token = response.get("nextPageToken")
        if not next_page_token:
            break
    
    pprint.pprint(comments)
    # we will make a search first to retrieve a list of videos
    # query = "Kpop demon hunters"
    # params = {
    #     "part": ",".join(["snippet"]),
    #     "q": query,
    #     "order": "viewCount",
    #     "maxResults": 1,
    #     # can be video, channel, or playlist
    #     # this can be useful if were trying to widen
    #     # pool of data sources,but keep it simple for
    #     # now
    #     "type": "video"
    # }

    # next_page_token = None
    # logger.info(f"beginning search of youtube videos from query {query}.")
    # request = youtube.search().list(**params)

    # video_ids = []
    # for _ in range(args.limit):
    #     response = request.execute()
        
    #     # loop through search results video ids and collect
    #     for item in response["items"]:
    #         id = item.get("id", {})
    #         video_id = id.get("videoId")
    #         video_ids.append(video_id)

    #     next_page_token = response.get("nextPageToken")
    #     if not next_page_token:
    #         break
    
    # # get only the unique video ids as some may be duplicated
    # video_ids = list(set(video_ids))
    # logger.info(f"collected {query} related video ids.")
    
    # params = {
    #     "part": ",".join([
    #         "contentDetails",
    #         # "fileDetails",
    #         "id",
    #         "liveStreamingDetails",
    #         "localizations",
    #         "paidProductPlacementDetails",
    #         "player",
    #         # "processingDetails",
    #         "recordingDetails",
    #         "snippet",
    #         "statistics",
    #         "status",
    #         # "suggestions",
    #         "topicDetails"
    #     ]),
    #     # The id parameter specifies a comma-separated 
    #     # list of the YouTube video ID(s) for the resource(s) 
    #     # that are being retrieved. In a video resource, 
    #     # the id property specifies the video's ID.
    #     "id": ",".join(video_ids) 
    # }
    
    # next_page_token = None
    # logger.info(f"beginning retrieval of youtube videos details from list of video ids.")
    # request = youtube.videos().list(**params)

    # while True:
    #     response = request.execute()
        
    #     for item in response["items"]:
    #         pprint.pprint(item)

    #     next_page_token = response.get("nextPageToken")
    #     if not next_page_token:
    #         break
    
    # # Quota impact: A call to this method has a quota cost of 1 unit.
    # logger.info(f"retrieval of youtube videos details done.")
    
    # # Print or process the extracted comments
    # for comment in comments:
    #     print(f"Author: {comment['author']}")
    #     print(f"Date: {comment['published_at']}")
    #     print(f"Comment: {comment['text']}")
    #     print(f"Likes: {comment['like_count']}\n")