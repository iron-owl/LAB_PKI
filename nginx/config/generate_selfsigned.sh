#!/bin/bash
set -e

TMP_DIR="/tmp/nginx_ssl"
SSL_CERTS="/etc/ssl/certs"
SSL_PRIVATE="/etc/ssl/private"
CN="nginx.lab.local"

KEY_PATH="$SSL_PRIVATE/${CN}.key.pem"
CERT_PATH="$SSL_CERTS/${CN}.cert.pem"

# Проверка на наличие готовых файлов
if [[ -f "$KEY_PATH" && -f "$CERT_PATH" ]]; then
  echo "[INIT] Existing certificate and key found — skipping generation."
  echo "  Key : $KEY_PATH"
  echo "  Cert: $CERT_PATH"
  exit 0
fi

echo "[INIT] Generating temporary self-signed certificate for $CN..."
mkdir -p "$TMP_DIR" "$SSL_CERTS" "$SSL_PRIVATE"

# Генерация приватного ключа
openssl genrsa -out "$TMP_DIR/${CN}.key.pem" 2048
chmod 400 "$TMP_DIR/${CN}.key.pem"

# Генерация CSR
openssl req -new -sha256 \
  -key "$TMP_DIR/${CN}.key.pem" \
  -out "$TMP_DIR/${CN}.csr.pem" \
  -subj "/C=RU/ST=Test/L=Lab/O=LAB.LOCAL/OU=Training/CN=$CN"

# Генерация самоподписанного сертификата
openssl x509 -req -days 365 -sha256 \
  -in "$TMP_DIR/${CN}.csr.pem" \
  -signkey "$TMP_DIR/${CN}.key.pem" \
  -out "$TMP_DIR/${CN}.cert.pem"

# Переносим в защищённые каталоги
cp "$TMP_DIR/${CN}.key.pem" "$KEY_PATH"
cp "$TMP_DIR/${CN}.cert.pem" "$CERT_PATH"

chmod 600 "$KEY_PATH"
chmod 444 "$CERT_PATH"

echo "[INIT] Cleaning up temporary files..."
rm -rf "$TMP_DIR"

echo "[INIT] Self-signed certificate for $CN installed:"
echo "  Key : $KEY_PATH"
echo "  Cert: $CERT_PATH"

