FROM ubuntu:24.04

# Установка SSH и базовых инструментов
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-server sudo vim curl net-tools ca-certificates && \
    mkdir /var/run/sshd && \
    rm -rf /var/lib/apt/lists/*

# Создаём пользователя 'student' с sudo-доступом
RUN useradd -m -s /bin/bash student && \
    echo "student:student" | chpasswd && \
    usermod -aG sudo student

# Копируем базовый SSH конфиг
COPY sshd_config /etc/ssh/sshd_config

# Копируем init-скрипт
COPY init.sh /opt/init.sh
RUN chmod +x /opt/init.sh

# Открываем порт SSH
EXPOSE 22

# Точка входа
CMD ["/opt/init.sh"]

