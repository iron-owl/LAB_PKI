#!/bin/bash
set -e

CA_DIR="/root/share"
CA_CERT="${CA_DIR}/intermediate.cert.pem"
CA_KEY="${CA_DIR}/intermediate.key.pem"
INDEX_FILE="${CA_DIR}/index.txt"
OCSP_PORT=2560

echo "[OCSP] Starting nginx for CRL publication..."
nginx

echo "[OCSP] Starting OCSP responder on port ${OCSP_PORT}..."
openssl ocsp \
  -index "${INDEX_FILE}" \
  -CA "${CA_CERT}" \
  -rkey "${CA_KEY}" \
  -rsigner "${CA_CERT}" \
  -port "${OCSP_PORT}" \
  -text

