#!/bin/sh

SQUID_CONF_DIR=${SQUID_DIR}

cp ${SQUID_CONF_DIR}/squid.conf.tmpl ${SQUID_CONF_DIR}/squid.conf.gen
sed -i "s~DNS_IP~$DNS_REVERSE_SERVICE_HOST~g" ${SQUID_CONF_DIR}/squid.conf.gen
mv ${SQUID_CONF_DIR}/squid.conf.gen ${SQUID_CONF_DIR}/squid.conf
