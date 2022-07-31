#!/bin/sh
TMPL_DIR=/tmpl
TMPL_FILE=${TMPL_DIR}/squid.conf.tmpl
SQUID_CONF_DIR=${SQUID_DIR}

if [ -f "${TMPL_FILE}" ]; then
    cp ${TMPL_DIR}/squid.conf.tmpl ${SQUID_CONF_DIR}/squid.conf.gen
    sed -i "s~DNS_IP~$DNS_REVERSE_SERVICE_HOST~g" ${SQUID_CONF_DIR}/squid.conf.gen
    # Replace squid.conf
    mv ${SQUID_CONF_DIR}/squid.conf.gen ${SQUID_CONF_DIR}/squid.conf
fi

