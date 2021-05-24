#squid-ssl
======================
This is a docker container that contains a squid proxy with SSL bump and ICAP capabilities.
It is based on syakesaba/docker-sslbump-proxy.
I am creating this docker image as part of a content filtering solution with squid and e2guardian as an ICAP service.

Baseimage
======================
alpine:3.12.1

```bash
docker run --name squid -d \
  --publish 3128:3128 \
  --volume /path/to/squid/conf:/etc/squid \
  --name squid \
  jusschwa/squid-ssl
```

### For use with e2guardian
```bash
docker network create e2guardian
# Start e2guardian container here

docker run --name squid -d \
  --publish 3128:3128 \
  --env ICAP=e2guardian \
  --network e2guardian \
  --volume /path/to/squid/conf:/etc/squid \
  --name squid \
  jusschwa/squid-ssl
```
In the above example, e2guardian is the name of the docker container.
