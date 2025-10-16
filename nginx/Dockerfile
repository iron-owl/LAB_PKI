FROM nginx:stable-alpine

RUN apk add --no-cache bash openssl

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
COPY generate_selfsigned.sh /usr/local/bin/generate_selfsigned.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /usr/local/bin/generate_selfsigned.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
