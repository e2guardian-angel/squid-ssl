FROM alpine:3.12.1
MAINTAINER Justin Schwartzbeck <justinmschw@gmail.com>

ENV SQUID_USER=squid

RUN apk update && apk add openssl socat squid

# Initialize SSL db
RUN mkdir -p /var/lib/squid
RUN /usr/lib/squid/security_file_certgen -c -s /var/lib/squid/ssl_db -M 4MB
RUN chown -R $SQUID_USER:$SQUID_USER /var/lib/squid
RUN rm -rf /var/cache/apk/*

EXPOSE 3128

ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["sh", "/entrypoint.sh"]
