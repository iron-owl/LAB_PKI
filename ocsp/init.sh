#!/bin/bash
set -e

echo "[OCSP] Starting OCSP responder service setup..."

# Здесь можно добавить конфигурацию OCSP
/usr/sbin/sshd -D &
echo "[OCSP] Ready."

tail -f /dev/null

