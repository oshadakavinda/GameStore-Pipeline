import requests
import json

games = [
    {
        "name": "Tekken 7",
        "genreId": 1,
        "price": 29.99,
        "releaseDate": "2017-06-02"
    },
    {
        "name": "Street Fighter V",
        "genreId": 1,
        "price": 19.99,
        "releaseDate": "2016-02-16"
    },
    {
        "name": "Final Fantasy XIV",
        "genreId": 2,
        "price": 9.99,
        "releaseDate": "2011-11-18"
    },
    {
        "name": "The Witcher 3: Wild Hunt",
        "genreId": 2,
        "price": 39.99,
        "releaseDate": "2015-05-18"
    },
    # Add other games here...
]

url = "http://13.51.114.181:5274/games"

for game in games:
    response = requests.post(url, headers={"Content-Type": "application/json"}, data=json.dumps(game))
    print(f"Posted {game['name']} - Status: {response.status_code}")
