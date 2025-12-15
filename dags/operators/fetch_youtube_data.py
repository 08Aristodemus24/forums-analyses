import os
import pprint
import logging
import pyarrow as pa
import datetime as dt
import isodate

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

def upsert_videos_comments(delta_table: DeltaTable, df: pa.Table):
    """
    updates old youtube comment records and inserts
    new youtube comment records in the existing delta 
    table using the data in the source table 
    """

    try:
        delta_table.merge(
            df,
            predicate="target.comment_id = source.comment_id",
            source_alias="source",
            target_alias="target",
            merge_schema=True
        ).when_matched_update(
            updates={
                # these are not included as these are the composite keys
                # that are not by good practice supposed to be updated
                "level" : "source.level",
                # "video_id" : "source.video_id",
                # "comment_id" : "source.comment_id",
                "author_channel_id" : "source.author_channel_id",
                "channel_id_where_comment_was_made" : "source.channel_id_where_comment_was_made",
                "parent_comment_id" : "source.parent_comment_id",
                "text_original" : "source.text_original",
                "text_display" : "source.text_display",
                # "published_at" : "source.published_at",
                "updated_at" : "source.updated_at",
                "like_count" : "source.like_count",
                "author_display_name" : "source.author_display_name",
                "author_channel_url" : "source.author_channel_url",

                "added_at": "source.added_at", 
            }, 
            # this tells delta to only update a record if the new record
            # does indeed have changed its column values when compared to the
            # current record
            predicate="""
                (source.level IS DISTINCT FROM target.level) OR    
                (source.author_channel_id IS DISTINCT FROM target.author_channel_id) OR
                (source.channel_id_where_comment_was_made IS DISTINCT FROM target.channel_id_where_comment_was_made) OR
                (source.parent_comment_id IS DISTINCT FROM target.parent_comment_id) OR
                (source.text_original IS DISTINCT FROM target.text_original) OR
                (source.text_display IS DISTINCT FROM target.text_display) OR
                (source.updated_at > target.updated_at) OR
                (source.like_count IS DISTINCT FROM target.like_count) OR
                (source.author_display_name IS DISTINCT FROM target.author_display_name) OR
                (source.author_channel_url IS DISTINCT FROM target.author_channel_url) OR
                
                (source.added_at IS DISTINCT FROM target.added_at)
            """
            
            # (source.video_id IS DISTINCT FROM target.video_id) OR
            # (source.comment_id IS DISTINCT FROM target.comment_id) OR
            # (source.published_at IS DISTINCT FROM target.published_at) OR
        ).when_not_matched_insert_all()\
        .execute()

    except Exception as e:
        # this runs if no table exists in s3 bucket
        logger.warning(f"`{e}` occured during delta upsert")

def upsert_videos(delta_table: DeltaTable, df: pa.Table):
    """
    updates old video records and inserts new video
    records in the existing delta table using the
    data in the source table 
    """

    try:
        delta_table.merge(
            df,
            predicate="target.video_id = source.video_id",
            source_alias="source",
            target_alias="target",
            merge_schema=True
        ).when_matched_update(
            updates={
                # these are not included as these are the composite keys
                # that are not by good practice supposed to be updated
                # "video_id": "source.video_id",
                "duration": "source.duration",
                "channel_id": "source.channel_id",
                "channel_title": "source.channel_title",
                "video_title": "source.video_title",
                "video_description": "source.video_description",
                "video_tags": "source.video_tags",
                "comment_count": "source.comment_count",
                "favorite_count": "source.favorite_count",
                "like_count": "source.like_count",
                "view_count": "source.view_count",
                "made_for_kids": "source.made_for_kids",
                # "published_at": "source.published_at"
                "added_at": "source.added_at", 
            }, 
            # this tells delta to only update a record if the new record
            # does indeed have changed its column values when compared to the
            # current record
            predicate="""
                (source.duration IS DISTINCT FROM target.duration) OR
                (source.channel_id IS DISTINCT FROM target.channel_id) OR
                (source.channel_title IS DISTINCT FROM target.channel_title) OR
                (source.video_title IS DISTINCT FROM target.video_title) OR
                (source.video_description IS DISTINCT FROM target.video_description) OR 
                (source.video_tags IS DISTINCT FROM target.video_tags) OR 
                (source.comment_count IS DISTINCT FROM target.comment_count) OR 
                (source.favorite_count IS DISTINCT FROM target.favorite_count) OR 
                (source.like_count IS DISTINCT FROM target.like_count) OR 
                (source.view_count IS DISTINCT FROM target.view_count) OR
                (source.made_for_kids IS DISTINCT FROM target.made_for_kids) OR
                
                (source.added_at IS DISTINCT FROM target.added_at)
            """
            # "source.published_at IS DISTINCT FROM target.published_at OR"
        ).when_not_matched_insert_all()\
        .execute()

    except Exception as e:
        # this runs if no table exists in s3 bucket
        logger.warning(f"`{e}` occured during delta upsert")

def write_delta_to_bucket(
    aws_creds: dict[str, str], 
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

def search_videos(youtube, query: str, limit: int):
    """
    searches for youtube videos by sending a request '
    to youtube api  
    
    fileDetails, processingDetails, and suggestion parts of a youtube video
    can only be accessed by owner of the video, so if you want to access
    it you won't but if you do want to access your own videos these parts
    can be accessed using OAuth2 credentials
    """

    # we will make a search first to retrieve a list of videos
    params = {
        "part": ",".join(["snippet"]),
        "q": query,
        "order": "viewCount",
        "maxResults": limit,
        # can be video, channel, or playlist
        # this can be useful if were trying to widen
        # pool of data sources,but keep it simple for
        # now
        "type": "video"
    }

    next_page_token = None
    logger.info(f"beginning search of youtube videos from query {query}...")
    request = youtube.search().list(**params)

    video_ids = []
    for _ in range(limit):
        response = request.execute()
        
        # loop through search results video ids and collect
        for item in response["items"]:
            id = item.get("id", {})
            video_id = id.get("videoId")
            video_ids.append(video_id)

        next_page_token = response.get("nextPageToken")
        if not next_page_token:
            break
    
    # get only the unique video ids as some may be duplicated
    video_ids = list(set(video_ids))
    logger.info(f"collected {query} related video ids.")

    return video_ids

def extract_videos(
    youtube, 
    video_ids: list[str], 
    limit: int, 
    aws_creds: dict[str, str], 
    bucket_name: str, 
    folder_name: str, 
    object_name: str, 
    is_local: bool, 
    upsert_func: Callable
):
    """
    Docstring for extract_videos
    
    :param youtube: Description
    :param video_ids: Description
    :param limit: Description
    :param aws_creds: Description
    :param bucket_name: Description
    :param folder_name: Description
    :param object_name: Description
    :param is_local: Description
    :param upsert_func: Description
    """

    params = {
        "part": ",".join([
            "contentDetails", 

            # "fileDetails",
            "id",
            "liveStreamingDetails",

            # we don't this localizations too much 
            # "localizations",

            # we don't this paidProductPlacementDetails too much 
            # "paidProductPlacementDetails",

            # we don't this player too much 
            # "player",

            # "processingDetails",

            # we don't this recordingDetails too much 
            # "recordingDetails",

            "snippet",
            "statistics",
            "status",

            # "suggestions",

            # we don't need topicDetails too much
            "topicDetails"
        ]),
        # The id parameter specifies a comma-separated 
        # list of the YouTube video ID(s) for the resource(s) 
        # that are being retrieved. In a video resource, 
        # the id property specifies the video's ID.
        "id": ",".join(video_ids)
    }
    
    videos = []
    next_page_token = None
    logger.info(f"beginning retrieval of youtube videos details from list of video ids...")
    request = youtube.videos().list(**params)

    while True:
        response = request.execute()
        
        for item in response["items"]:
            # pprint.pprint(item)
            videos.append({
                "video_id": item.get("id"),

                # PT3M19S to time delta is 3m19s
                "duration": item.get("contentDetails")
                    .get("duration"),
                "channel_id": item.get("snippet")\
                    .get("channelId"),
                "channel_title": item.get("snippet")\
                    .get("channelTitle"),
                "video_title": item.get("snippet")\
                    .get("title"),
                "video_description": item.get("snippet")\
                    .get("description"),
                "video_tags": item.get("snippet")\
                    .get("tags"),
                "comment_count": int(item.get("statistics")\
                    .get("commentCount")),
                "favorite_count": int(item.get("statistics")\
                    .get("favoriteCount")),
                "like_count": int(item.get("statistics")\
                    .get("likeCount")),
                "view_count": int(item.get("statistics")
                    .get("viewCount")),
                "made_for_kids": item.get("status")\
                    .get("madeForKids"),

                # 2025-06-23T22:30:00Z
                "published_at": dt.datetime.strptime(item.get("snippet")
                    .get("publishedAt"), "%Y-%m-%dT%H:%M:%SZ"),
                "added_at": dt.datetime.now()
            })

        next_page_token = response.get("nextPageToken")
        if not next_page_token:
            break
    
    # Quota impact: A call to this method has a quota cost of 1 unit.
    logger.info(f"retrieval of youtube videos details done.")
    
    pprint.pprint(videos)
    logger.info(f"videos count: {len(videos)}")

    # convert the list of dictionaries/records to pyarrow 
    # table from scraped data
    videos_table = pa.Table.from_pylist(videos)
    logger.info(f"videos table shape:{videos_table.shape}")

    write_delta_to_bucket(aws_creds, videos_table, bucket_name, object_name, folder_name, is_local, upsert_func)

def extract_videos_comments(
    youtube, 
    video_ids: list[str], 
    limit: int, 
    aws_creds: dict, 
    bucket_name: str, 
    folder_name: str, 
    object_name: str, 
    is_local: bool, 
    upsert_func: Callable
):
    """
    Docstring for extract_videos_comments
    
    :param youtube: Description
    :param video_ids: Description
    :param limit: Description
    :param aws_creds: Description
    :param bucket_name: Description
    :param folder_name: Description
    :param object_name: Description
    :param is_local: Description
    :param upsert_func: Description
    """

    # define comments where all comments in videos will be
    # stored
    comments = []
    for video_id in video_ids:
        params = {
            "part": ",".join(["snippet", "replies"]),
            "videoId": video_id,
            "maxResults": 100
        }
        
        next_page_token = None
        request = youtube.commentThreads().list(**params)

        for _ in range(limit):
            response = request.execute()
            
            for item in response["items"]:
                # append top level comment statistics
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
                        .get("snippet")\
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
                    "author_channel_url": item.get("snippet")\
                        .get("topLevelComment")\
                        .get("snippet")\
                        .get("authorChannelUrl"),
                    "added_at": dt.datetime.now()
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
                            "author_channel_url": reply.get("snippet")\
                                .get("authorChannelUrl"),
                            "added_at": dt.datetime.now()
                        })

            next_page_token = response.get("nextPageToken")
            if not next_page_token:
                break
        
    pprint.pprint(comments)
    logger.info(f"comments count: {len(comments)}")

    # convert the list of dictionaries/records to pyarrow 
    # table from scraped data
    videos_comments_table = pa.Table.from_pylist(comments)
    logger.info(f"videos comments and replies table shape:{videos_comments_table.shape}")

    write_delta_to_bucket(aws_creds, videos_comments_table, bucket_name, object_name, folder_name, is_local, upsert_func)

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
    parser.add_argument("--kind", type=str, default="videos", help="represents the kind of data to scrape on youtube can be video statistics, snippets or comments from the video")
    # parser.add_argument
    parser.add_argument("--limit", type=int, default=1, help="represents the limit to the number of pages to keep requesting for results in youtube api")
    parser.add_argument("--local", action="store_true", help="represents if the bucket name and object is a local path to the delta file if user decides not to write in s3")
    args = parser.parse_args()

    # load env variables
    env_dir = Path('../../').resolve()
    load_dotenv(os.path.join(env_dir, '.env'))

    # get env variables
    aws_creds = {
        "access_key": os.environ.get("AWS_ACCESS_KEY_ID"),
        "secret_key": os.environ.get("AWS_SECRET_ACCESS_KEY"),
        "region": os.environ.get("AWS_REGION_NAME"),
    }
    YOUTUBE_API_KEY = os.environ.get("YOUTUBE_API_KEY")

    # youtube url when this is built will be
    # `https://www.youtube.com/watch?v=<video id>` or in 
    # this case `https://www.youtube.com/watch?v=SIm2W9TtzR0`
    youtube = build('youtube', 'v3', developerKey=YOUTUBE_API_KEY)
    
    # searches videos and returns the list of video ids
    video_ids = search_videos(youtube, args.search_query, args.limit)

    # extracts comments from list of youtube videos
    if args.kind == "comments":
        extract_videos_comments(
            youtube=youtube, 
            video_ids=video_ids, 
            limit=args.limit, 
            aws_creds=aws_creds, 
            bucket_name=args.bucket_name, 
            folder_name=args.folder_name, 
            object_name=args.object_name, 
            is_local=args.local, 
            upsert_func=upsert_videos_comments
        )

    elif args.kind == "videos":
        extract_videos(
            youtube=youtube, 
            video_ids=video_ids, 
            limit=args.limit, 
            aws_creds=aws_creds, 
            bucket_name=args.bucket_name, 
            folder_name=args.folder_name, 
            object_name=args.object_name, 
            is_local=args.local, 
            upsert_func=upsert_videos
        )