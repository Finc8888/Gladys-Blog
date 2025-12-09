# Run this file on server
docker stop caddy-gladys
docker rm caddy-gladys


sudo rm -rf caddy_data/_tls/staging

docker run -d \
    --name caddy-gladys \
    -p 80:80 \
    -p 443:443 \
    -v $(pwd)/public:/usr/share/caddy:ro \
    -v $(pwd)/Caddyfile:/etc/caddy/Caddyfile:ro \
    -v caddy_data:/data \
    caddy:latest
