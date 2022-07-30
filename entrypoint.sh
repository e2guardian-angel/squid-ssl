#!/bin/bash
# encoding: utf-8

SQUID_USER=squid
export SQUID_DIR=/etc/squid

# For some reason, squid doesn't do DNS resolution for ICAP, etc.
# So we have to use socat to forward these to the correct containers.
if [ $ICAP ]; then
    echo "ICAP service: ${ICAP}"
    until ping -c1 ${ICAP} >/dev/null 2>&1; do :; done
    socat TCP4-LISTEN:1344,fork TCP4:${ICAP}:1344 &
fi

# Autoconfigure
#sh configsquid.sh

SQUID_EXEC=$(which squid)
exec $SQUID_EXEC -f $SQUID_DIR/squid.conf -NYCd 10
