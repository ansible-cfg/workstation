# Introduction

This image can be used as transparent proxy.

# Build

```bash
# if not already done
docker login

squid/build.sh
```

# Run

set environment variables:
* PROXY_HOST
* PROXY_PORT (optional, default=3128)
* PROXY_USER (optional)
* PROXY_PW (optional)

start container
```bash
sudo docker run -net=host -d --name <name> --rm -e PROXY_USER=$PROXY_USER -e PROXY_PW=$PROXY_PW -e PROXY_HOST=$PROXY_HOST docker.io/sbueringer/squid:latest
```
