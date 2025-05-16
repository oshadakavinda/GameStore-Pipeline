#!/bin/bash

cd terraform || { echo "❌ Failed to enter terraform directory"; exit 1; }

# STEP 1: Extract Public IP from Terraform
public_ip=$(terraform output -raw instance_public_ip | tr -d '[:space:]')

if [[ -z "$public_ip" ]]; then
    echo "❌ Error: Could not retrieve public IP from Terraform."
    exit 1
fi

echo "✅ Public IP: $public_ip"

# STEP 2: Define base API URL
API_URL="http://${public_ip}:5274/games"

# STEP 3: Define games to inject (10 games across genres)
games=(
'{"name": "Tekken 7", "genreId": 1, "price": 29.99, "releaseDate": "2017-06-02"}'
'{"name": "Street Fighter V", "genreId": 1, "price": 19.99, "releaseDate": "2016-02-16"}'
'{"name": "Final Fantasy XIV", "genreId": 2, "price": 9.99, "releaseDate": "2011-11-18"}'
'{"name": "The Witcher 3: Wild Hunt", "genreId": 2, "price": 39.99, "releaseDate": "2015-05-18"}'
'{"name": "Cities: Skylines", "genreId": 3, "price": 14.99, "releaseDate": "2015-03-10"}'
'{"name": "SimCity", "genreId": 3, "price": 12.99, "releaseDate": "2013-03-05"}'
'{"name": "Minecraft", "genreId": 4, "price": 26.95, "releaseDate": "2011-11-18"}'
'{"name": "Terraria", "genreId": 4, "price": 9.99, "releaseDate": "2011-05-16"}'
'{"name": "Overwatch", "genreId": 5, "price": 39.99, "releaseDate": "2016-05-24"}'
'{"name": "Valorant", "genreId": 5, "price": 0.00, "releaseDate": "2020-06-02"}'
)

# STEP 4: POST each game
for game in "${games[@]}"; do
    echo "📤 Posting: $game"
    response=$(curl -s -w "%{http_code}" -o /dev/null -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d "$game")

    if [[ "$response" == "201" ]]; then
        echo "✅ Success - Game added."
    else
        echo "❌ Failed with status code: $response"
    fi
    echo "----"
done
