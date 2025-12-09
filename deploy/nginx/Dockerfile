FROM nginx:alpine

COPY blog/gladys/public /usr/share/nginx/html

ADD deploy/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
ADD deploy/nginx/nginx.conf /etc/nginx/nginx.conf

COPY deploy/certs/cert.pem /etc/nginx/ssl/cert.pem
COPY deploy/certs/key.pem /etc/nginx/ssl/key.pem
