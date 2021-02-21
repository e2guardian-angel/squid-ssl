#squid-ssl-x86
======================
This is a docker container made for x86 that contains a squid proxy with SSL bump and ICAP capabilities.
It is based on syakesaba/docker-sslbump-proxy.
I am creating this docker image as part of a content filtering solution with squid and e2guardian as an ICAP service.

Baseimage
======================
debian:stretch

### Quickstart 
```bash
docker run --name squid -d \
  --publish 3128:3128 \
  --volume /path/to/squid/conf:/etc/squid \
  jusschwa/squid-ssl-x86
```

