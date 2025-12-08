import requests
import os
import pprint
import logging

from dotenv import load_dotenv
from pathlib import Path
from googleapiclient.discovery import build

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



if __name__ == "__main__":
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
        "videoId": "QGsevnbItdU",
        "maxResults": 100
    }
    comments = []
    next_page_token = None
    request = youtube.commentThreads().list(**params)

    while True:
        response = request.execute()
        
        for item in response["items"]:
            pprint.pprint(item)
            comment = item["snippet"]["topLevelComment"]["snippet"]
            comments.append({
                "author": comment["authorDisplayName"],
                "published_at": comment["publishedAt"],
                "text": comment["textDisplay"],
                "like_count": comment["likeCount"]
            })

        next_page_token = response.get("nextPageToken")
        if not next_page_token:
            break
    

    # # we will make a search first to retrieve a list of videos
    # query = "Kpop demon hunters"
    # params = {
    #     "part": ",".join(["snippet"]),
    #     "q": query,
    #     "order": "viewCount",
    #     "maxResults": 50,
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
    # while True:
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
    #         "fileDetails",
    #         "id",
    #         "liveStreamingDetails",
    #         "localizations",
    #         "paidProductPlacementDetails",
    #         "player",
    #         "processingDetails",
    #         "recordingDetails",
    #         "snippet",
    #         "statistics",
    #         "status",
    #         "suggestions",
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