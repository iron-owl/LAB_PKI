#!/bin/bash
set -e

echo "[ROOT-CA] Initializing root CA..."
mkdir -p /root/ca/{certs,crl,newcerts,private}
chmod 700 /root/ca/private
touch /root/ca/index.txt
echo 1000 > /root/ca/serial

# Стартуем SSH
/usr/sbin/sshd -D &
echo "[ROOT-CA] Ready."

tail -f /dev/null

