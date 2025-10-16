#!/bin/bash
set -e

# Проверка и генерация сертификата
/usr/local/bin/generate_selfsigned.sh

echo "[INIT] Starting nginx..."
exec nginx -g "daemon off;"

