#!/bin/bash

WORKDIR=`echo $0 | sed -e s/build.sh//`
cd ${WORKDIR}

docker build -t docker.io/sbueringer/squid:latest .

if [ "$TRAVIS_BRANCH" == "master" ] && [ ! -z "$DOCKER_USERNAME" ] && [ ! -z $DOCKER_PASSWORD ]
then
    docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD"
    docker push docker.io/sbueringer/squid:latest;
fi
