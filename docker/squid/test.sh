#!/bin/bash

docker run --rm --name=test -e PROXY_HOST=10.0.2.2 --net host -it docker.io/sbueringer/squid:latest