#!/bin/bash
set -e

echo "[INIT] Starting SSH service..."

# Правильный запуск без systemd
/usr/sbin/sshd -D &

echo "[INIT] Container ready."

# Не даём контейнеру завершиться
tail -f /dev/null

