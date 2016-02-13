#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker build -t apkg "$THIS_DIR"

# build nginx 1.9.11 apk from source
docker run --rm -it \
    -v $THIS_DIR/:/home/build/packages/main/ \
    -v $THIS_DIR/nginx.patch:/nginx.patch \
    apkg \
    bash -c '
        cd /aports &&
        git apply /nginx.patch &&
        chown build:abuild -R /aports &&
        cd main/nginx &&
        su build -c "abuild checksum" &&
        su build -c "abuild -r"
        '

