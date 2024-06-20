#!/usr/bin/env bash

docker run \
    --rm \
    --interactive --tty \
    --volume="${PWD}":/work \
    jmeeuws/esp-dlang \
    bash -c " \
        ulimit -n 4096 && \
        \$SHELL \
    "
sudo chown -R $UID .
