FROM base-ubuntu-ca:latest

RUN apt update && apt install -y nginx && \
    mkdir -p /root/share /var/www/html/ocsp

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY nginx.conf /etc/nginx/sites-available/default

RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /root
EXPOSE 8080 2560

CMD ["/usr/local/bin/entrypoint.sh"]
