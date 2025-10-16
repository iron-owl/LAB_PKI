#!/bin/bash
set -e

echo "[INTERMEDIATE-CA] Initializing intermediate CA..."
mkdir -p /root/intermediate/{certs,crl,csr,newcerts,private}
chmod 700 /root/intermediate/private
touch /root/intermediate/index.txt
echo 1000 > /root/intermediate/serial
echo 1000 > /root/intermediate/crlnumber

/usr/sbin/sshd -D &
echo "[INTERMEDIATE-CA] Ready."

tail -f /dev/null

