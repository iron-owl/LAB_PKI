FROM nginx:stable-alpine

RUN apk add --no-cache bash openssl

# Копируем скрипт генерации
COPY config/generate_selfsigned.sh /usr/local/bin/generate_selfsigned.sh
RUN chmod +x /usr/local/bin/generate_selfsigned.sh

# Генерация самоподписанного сертификата при сборке
RUN /usr/local/bin/generate_selfsigned.sh

# Копируем конфиг и html
COPY config/nginx.conf /etc/nginx/conf.d/default.conf
COPY config/index.html /usr/share/nginx/html/index.html

EXPOSE 8080 8443

