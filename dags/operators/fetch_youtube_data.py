import requests
import os
import pprint
from dotenv import load_dotenv
from pathlib import Path


if __name__ == "__main__":
    # load env variables
    env_dir = Path('../../').resolve()
    load_dotenv(os.path.join(env_dir, '.env'))

    YOUTUBE_API_KEY = os.environ.get("YOUTUBE_API_KEY")

    params = {
        "id": "SIm2W9TtzR0",
        "key": YOUTUBE_API_KEY,
        "part": "snippet,contentDetails,fileDetails,player,processingDetails,recordingDetails,statistics,status,suggestions,topicDetails"
    }
    response = requests.get("https://www.googleapis.com/youtube/v3/videos", params=params)
    data = response.json()
    
    pprint.pprint(data)