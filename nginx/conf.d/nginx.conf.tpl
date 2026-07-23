limit_req_zone $binary_remote_addr zone=anti_bot:10m rate=5r/s;
limit_req_status 429;

server {
    listen 80;
    server_name $URL;
    access_log /var/log/nginx/access.log;
    error_log  /var/log/nginx/error.log;

    location /.well-known/acme-challenge/ {
        root /config/www;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name $URL;
    access_log /var/log/nginx/access.log;
    error_log  /var/log/nginx/error.log;

    ssl_certificate     /config/letsencrypt/live/$URL/fullchain.pem;
    ssl_certificate_key /config/letsencrypt/live/$URL/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    location / {
        limit_req zone=anti_bot burst=10 nodelay;
        root /config/www;
        index index.html;
    }
}

server {
    listen 8080;
    server_name localhost;

    location /metrics {
        stub_status on;
        access_log off;
        allow 172.16.0.0/12;
        allow 127.0.0.1;
        deny all;
    }
}