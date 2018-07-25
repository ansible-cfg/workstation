#!/bin/bash

WORKDIR=`echo $0 | sed -e s/build.sh//`
cd ${WORKDIR}

rm -rf dist
mkdir dist

CADDY_VERSION=0.10.10
CADDY_FOLDER=/gopath/src/github.com/mholt/caddy

docker run -e GOOS=linux -e GOARCH=amd64 -e GOPATH=/gopath -e CGO_ENABLED=0 \
           -v $(pwd)/dist:/output \
           -w /output  \
           golang:1.9 \
           sh -c "git clone https://github.com/mholt/caddy -b v$CADDY_VERSION $CADDY_FOLDER; \
                  cd $CADDY_FOLDER; \
                  go get -v -d ./...; \
                  go build -a -installsuffix cgo -v -o /output/caddy $CADDY_FOLDER/caddy/main.go"

docker build -t docker.io/sbueringer/caddy:latest .

if [ "$TRAVIS_BRANCH" == "master" ] && [ ! -z "$DOCKER_USERNAME" ] && [ ! -z $DOCKER_PASSWORD ]
then
    docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD"
    docker push docker.io/sbueringer/caddy:latest
fi
