FROM debian:buster
MAINTAINER Justin Schwartzbeck <justinmschw@gmail.com>

ENV SQUID_USER=proxy
ARG BUILD_DATE
ENV OS debian

RUN apt update && apt install -y wget gnupg gnupg2 gnupg1 socat

# add diladele apt key
RUN wget -qO - http://packages.diladele.com/diladele_pub.asc | apt-key add -

# add repository to the sources list
RUN echo "deb http://squid411.diladele.com/ubuntu/ bionic main" > /etc/apt/sources.list.d/squid411.diladele.com.list

RUN apt-get update

RUN apt-get install -y squid-common
RUN apt-get install -y squid 
RUN apt-get install -y squidclient

# Initialize SSL db
RUN mkdir -p /var/lib/squid
RUN /usr/lib/squid/security_file_certgen -c -s /var/lib/squid/ssl_db -M 4MB
RUN chown -R $SQUID_USER:$SQUID_USER /var/lib/squid

EXPOSE 3128

ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
