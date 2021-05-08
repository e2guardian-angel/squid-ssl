FROM alpine:3.12.1 as builder

WORKDIR /tmp

RUN apk update \
  && apk add git build-base automake autoconf libtool curl-dev jsoncpp-dev jsoncpp-static \
  && git clone https://github.com/mrtazz/restclient-cpp.git \
  && cd restclient-cpp \
  && sh autogen.sh \
  && make \
  && make install \
  && cd .. \
  && git clone https://github.com/e2guardian-angel/squid-acl-category-helper.git \
  && cd squid-acl-category-helper \
  && make ip_category_helper \
  && make host_category_helper \
  && mkdir -p /usr/local/bin/squidhelpers \
  && cp ip_category_helper /usr/local/bin/squidhelpers \
  && cp host_category_helper /usr/local/bin/squidhelpers

FROM alpine:3.12.1
MAINTAINER Justin Schwartzbeck <justinmschw@gmail.com>

ENV SQUID_USER=squid

COPY --from=builder /usr/local/bin/squidhelpers /usr/local/bin/squidhelpers

RUN apk update \
  && apk add openssl socat squid libcurl

# Initialize SSL db
RUN mkdir -p /var/lib/squid \
  && /usr/lib/squid/security_file_certgen -c -s /var/lib/squid/ssl_db -M 4MB \
  && chown -R $SQUID_USER:$SQUID_USER /var/lib/squid \
  && rm -rf /var/cache/apk/*

EXPOSE 3128

ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["sh", "/entrypoint.sh"]
