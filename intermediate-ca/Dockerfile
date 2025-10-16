FROM base-ubuntu-ca:latest
COPY init.sh /opt/init.sh
COPY openssl.cnf /root/intermediate/openssl.cnf
RUN chmod +x /opt/init.sh
WORKDIR /opt/intermediate-ca
CMD ["/opt/init.sh"]

