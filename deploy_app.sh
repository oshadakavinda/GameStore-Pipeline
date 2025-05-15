
# Create docker-compose.yml
cat > /home/ubuntu/docker-compose.yml <<'DOCKERCOMPOSE'
version: '3'
services:
  backend:
    image: oshadakavinda2/game-store-backend:latest
    ports:
      - "5274:5274"
    environment:
      - ASPNETCORE_URLS=http://0.0.0.0:5274
    volumes:
      - sqlite_data:/app/Data
    restart: always

  frontend:
    image: oshadakavinda2/game-store-frontend:latest
    ports:
      - "5003:8080"
    depends_on:
      - backend
    restart: always

volumes:
  sqlite_data:
DOCKERCOMPOSE

# Fix permissions
sudo chown ubuntu:ubuntu /home/ubuntu/docker-compose.yml

# Deploy the application using Docker Compose
cd /home/ubuntu
sudo docker-compose up -d