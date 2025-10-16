#!/bin/bash
set -e

echo "[INIT] Generating self-signed certificate for nginx.lab.local..."

mkdir -p /etc/ssl/certs /etc/ssl/private

openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout /etc/ssl/private/www.example.com.key.pem \
  -out /etc/ssl/certs/www.example.com.cert.pem \
  -subj "/C=RU/ST=Test/L=Lab/O=LAB.LOCAL/OU=Training/CN=nginx.lab.local" \
  -days 365

chmod 600 /etc/ssl/private/www.example.com.key.pem
echo "[INIT] Self-signed certificate generated successfully."

