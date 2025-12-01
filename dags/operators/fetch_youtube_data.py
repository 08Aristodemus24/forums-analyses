import requests
import os
import pprint
from dotenv import load_dotenv
from pathlib import Path

from googleapiclient.discovery import build

if __name__ == "__main__":
    # load env variables
    env_dir = Path('../../').resolve()
    load_dotenv(os.path.join(env_dir, '.env'))

    YOUTUBE_API_KEY = os.environ.get("YOUTUBE_API_KEY")

    # # fileDetails, processingDetails, and suggestion parts of a youtube video
    # # can only be accessed by owner of the video, so if you want to access
    # # it you won't but if you do want to access your own videos these parts
    # # can be accessed using OAuth2 credentials
    # params = {
    #     "id": "SIm2W9TtzR0",
    #     "key": YOUTUBE_API_KEY,
    #     "part": ",".join(["snippet",
    #         "contentDetails",
    #         # "fileDetails",
    #         "player",
    #         # "processingDetails",
    #         "recordingDetails",
    #         "statistics",
    #         "status",
    #         # "suggestions",
    #         "topicDetails",])
    # }
    # response = requests.get("https://www.googleapis.com/youtube/v3/videos", params=params)
    # data = response.json()
    # pprint.pprint(data)
    
    youtube = build('youtube', 'v3', developerKey=YOUTUBE_API_KEY)
    params = {
        "part": ",".join(["snippet", "replies"]),
        "videoId": "SIm2W9TtzR0",
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

    # # Print or process the extracted comments
    # for comment in comments:
    #     print(f"Author: {comment['author']}")
    #     print(f"Date: {comment['published_at']}")
    #     print(f"Comment: {comment['text']}")
    #     print(f"Likes: {comment['like_count']}\n")