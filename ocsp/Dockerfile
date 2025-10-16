FROM base-ubuntu-ca:latest
COPY init.sh /opt/init.sh
RUN chmod +x /opt/init.sh
WORKDIR /opt/ocsp
CMD ["/opt/init.sh"]

