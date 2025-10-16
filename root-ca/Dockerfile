FROM base-ubuntu-ca:latest

COPY init.sh /opt/init.sh
COPY openssl.cnf /root/ca/openssl.cnf
RUN chmod +x /opt/init.sh

WORKDIR /opt/root-ca
CMD ["/opt/init.sh"]

