#!/bin/sh
GUARDIAN_CONF=/opt/guardian/guardian.json
SQUID_CONF_DIR=${SQUID_DIR}
OUTPUT_CERT_PATH=/etc/squid/ssl/tls.crt
OUTPUT_KEY_PATH=/etc/squid/ssl/tls.key

extract_value () {
    echo "${1}" | jq -r .${2}
}

extract_value_compact () {
    extract_value "${CONFIG}" ${1} | jq -c '.[]'
}

if [ -f "${GUARDIAN_CONF}" ]; then
    CONFIG="$(cat $GUARDIAN_CONF)"
    LOCALNET=$(extract_value "${CONFIG}" localNetwork)
    SQUID_CONF_DIR=$(extract_value "${CONFIG}" squidConfigDir)
    SQUID_PORT=$(extract_value "${CONFIG}" proxyPort)
    SSL_BUMP_ENABLED=$(extract_value "${CONFIG}" sslBumpEnabled)
    DNS_IP=$(extract_value "${CONFIG}" dnsIP)

    cp ${SQUID_CONF_DIR}/squid.conf.tmpl ${SQUID_CONF_DIR}/squid.conf.gen

    ACLS=""
    DECRYPT_RULES=""
    HTTP_PORT_LINE=""
    SSL_CONFIG=""
    ICAP_CONFIG=""
    if [ "${SSL_BUMP_ENABLED}" = "true" ]; then
	# Bump enabled logic
	HTTP_PORT_LINE="http_port ${SQUID_PORT} ssl-bump generate-host-certificates=on dynamic_cert_mem_cache_size=4MB cert=${OUTPUT_CERT_PATH} key=${OUTPUT_KEY_PATH}"
	for row in $(extract_value_compact decryptRules); do
	    CATEGORY=$(extract_value "$row" category)
	    DECRYPT=$(extract_value "$row" decrypt)
	    # Define ACL
	    if [ "${CATEGORY}" != "all" ] && [ ! "$(echo ${ACLS} | grep ${CATEGORY} )" ]; then
		ACLS="${ACLS}\nacl ${CATEGORY} external category_helper"
	    fi
	    # Add rule
	    if [ ${DECRYPT} = "true" ]; then
		DECRYPT_RULES="${DECRYPT_RULES}\nssl_bump bump ${CATEGORY}"
	    else
		DECRYPT_RULES="${DECRYPT_RULES}\nssl_bump none ${CATEGORY}"
	    fi
	done
	SSL_CONFIG="sslproxy_cert_error allow all\n"
        SSL_CONFIG="${SSL_CONFIG}sslcrtd_program /usr/lib/squid/security_file_certgen -s /var/lib/squid/ssl_db -M 4MB\n"
        SSL_CONFIG="${SSL_CONFIG}sslcrtd_children 10\n"
        SSL_CONFIG="${SSL_CONFIG}ssl_bump server-first all\n"
	
	ICAP_CONFIG="icap_service_failure_limit -1\n"
	ICAP_CONFIG="${ICAP_CONFIG}icap_enable on\n"
	ICAP_CONFIG="${ICAP_CONFIG}icap_service service_req reqmod_precache bypass=0 icap://127.0.0.1:1344/request\n"
	ICAP_CONFIG="${ICAP_CONFIG}icap_service service_resp respmod_precache bypass=0 icap://127.0.0.1:1344/response\n"
	ICAP_CONFIG="${ICAP_CONFIG}adaptation_access service_req allow all\n"
	ICAP_CONFIG="${ICAP_CONFIG}adaptation_access service_resp allow all\n"
	ICAP_CONFIG="${ICAP_CONFIG}icap_send_client_ip on\n"
	ICAP_CONFIG="${ICAP_CONFIG}icap_send_client_username on\n"
	ICAP_CONFIG="${ICAP_CONFIG}adaptation_masterx_shared_names X-ICAP-E2G\n"
	# TODO: generate certificate/key pair using provided CA
    else
	# Bump disabled logic
	HTTP_PORT_LINE="http_port ${SQUID_PORT}"
    fi
    
    ALLOW_RULES=""
    for row in $(extract_value_compact allowRules); do
	CATEGORY=$(extract_value "$row" category)
	ALLOW=$(extract_value "$row" allow)
	# Define ACL
	if [ "${CATEGORY}" != "all" ] && [ ! "$(echo ${ACLS} | grep ${CATEGORY} )" ]; then
	    ACLS="${ACLS}\nacl ${CATEGORY} external category_helper"
	fi
	# Add rule
	if [ ${ALLOW} = "true" ]; then
	    ALLOW_RULES="${ALLOW_RULES}\nhttp_access allow ${CATEGORY}"
	else
	    ALLOW_RULES="${ALLOW_RULES}\nhttp_access deny ${CATEGORY}"
	fi
    done

    # Do all the replacements
    sed -i "s~SQUIDCONF_LOCALNET_DEFINITION~acl localnet src $LOCALNET~g" ${SQUID_CONF_DIR}/squid.conf.gen
    sed -i "s~SQUIDCONF_ACL_DEFINITIONS~$ACLS~g" ${SQUID_CONF_DIR}/squid.conf.gen
    sed -i "s~SQUIDCONF_ALLOW_RULES~$ALLOW_RULES~g" ${SQUID_CONF_DIR}/squid.conf.gen
    sed -i "s~SQUIDCONF_DECRYPT_RULES~$DECRYPT_RULES~g" ${SQUID_CONF_DIR}/squid.conf.gen
    sed -i "s~SQUIDCONF_SSL_CONFIG~$SSL_CONFIG~g" ${SQUID_CONF_DIR}/squid.conf.gen
    sed -i "s~SQUIDCONF_HTTP_PORT_DEFINITION~$HTTP_PORT_LINE~g" ${SQUID_CONF_DIR}/squid.conf.gen
    sed -i "s~SQUIDCONF_ICAP_CONFIG~$ICAP_CONFIG~g" ${SQUID_CONF_DIR}/squid.conf.gen
    sed -i "s~DNS_IP~$DNS_IP~g" ${SQUID_CONF_DIR}/squid.conf.gen

    # Replace squid.conf
    mv ${SQUID_CONF_DIR}/squid.conf.gen ${SQUID_CONF_DIR}/squid.conf
fi
