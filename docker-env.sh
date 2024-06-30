#!/usr/bin/env bash

DOCKER_RUN_ARGS=""
DOCKER_RUN_ARGS+=" --rm"
DOCKER_RUN_ARGS+=" -it"
DOCKER_RUN_ARGS+=" --volume=${PWD}:/work"

IMAGE="jmeeuws/esp-dlang:latest"

INIT_SCRIPT=" \
ulimit -n 4096 && \
bash \
"

docker run $DOCKER_RUN_ARGS $IMAGE bash -c "${INIT_SCRIPT}"

sudo chown -R $UID .
