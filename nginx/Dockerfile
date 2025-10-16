FROM nginx:stable-alpine

RUN apk add --no-cache bash openssl

COPY config/nginx.conf /etc/nginx/conf.d/default.conf
COPY config/index.html /usr/share/nginx/html/index.html
COPY config/generate_selfsigned.sh /usr/local/bin/generate_selfsigned.sh
COPY config/entrypoint.sh /entrypoint.sh

RUN chmod +x /usr/local/bin/generate_selfsigned.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
