#!/bin/bash
# encoding: utf-8

SQUID_USER=squid
SQUID_DIR=/etc/squid

# If certificates/config were not provided, create them here.
if [ ! -d $SQUID_DIR/ssl ]; then
    mkdir $SQUID_DIR/ssl
    openssl req -new -newkey rsa:2048 -nodes -days 3650 -x509 -keyout $SQUID_DIR/ssl/bluestar.pem -out $SQUID_DIR/ssl/bluestar.crt\
	    -subj "/C=US/ST=Texas/L=Austin/O=BlueStar/OU=NetworkSecurity/CN=bluestar"
    openssl x509 -in $SQUID_DIR/ssl/bluestar.crt -outform DER -out $SQUID_DIR/ssl/bluestar.der
fi

# For some reason, squid doesn't do DNS resolution for ICAP, etc.
# So we have to use socat to forward these to the correct containers.
if [ $ICAP ]; then
    echo "ICAP service: ${ICAP}"
    until ping -c1 ${ICAP} >/dev/null 2>&1; do :; done
    socat TCP4-LISTEN:1344,fork TCP4:${ICAP}:1344 &
fi

cleanup() {
    iptables -t nat -D OUTPUT -m owner --uid-owner squid -j ACCEPT
}
trap cleanup INT TERM

cleanup

iptables -t nat -A OUTPUT -m owner --uid-owner squid -j ACCEPT

SQUID_EXEC=$(which squid)
exec $SQUID_EXEC -f $SQUID_DIR/squid.conf -NYCd 10
