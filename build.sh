#!/bin/bash
#
# Sigh... this is really convoluted but it's the only reliable way
# to workaround docker's misguided refusal to make the build context
# available to RUN statements
#
# Explicit volume mappings are avoided on purpose to make sure this
# works even when run inside a docker container
#

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# $1 image
# $2 source path
# return true if the image is newer than the newest file in the source tree
function img_fresh() {
    # find creation date of container image, if present
    # NB: remove sub-second precision and make it find-friendly
    local created=$(
        docker inspect --format='{{.Created}}' --type=image "$1" |\
        cut -d. -f1 |\
        sed 's/T/ /'
    )
    echo "$1 created: $created" 1>&2
    # find first file in build context newer than image, if any
    # NB: docker gives UTC timestamps, make sure find does not compare it to local time
    [[ -n "$created" ]] && [[ -e "$2" ]] && [[ -z "$(TZ=UTC find "$2" -newermt "$created" | head -n 1)" ]]
}

IMAGE=nginx:alpine

# Only rebuild if needed to prevent cache busting
if img_fresh $IMAGE $THIS_DIR ; then
    exit 0
fi

# step 1: get local data into container image
TMP=$THIS_DIR/.dockerfile.tmp
tee "$TMP" <<EOF
FROM alpine:3.3
ADD apk/x86_64 /apk/x86_64
EOF
docker build -t nginx-cxt -f "$TMP" "$THIS_DIR"
rm -f "$TMP"

# step 2: get data from image to volume
docker run --name=nginx-cxt -v /cxt nginx-cxt cp -R /apk/x86_64 /cxt/

# step 3: use data from volume in command
docker run --name=nginx-build \
    --volumes-from nginx-cxt \
    alpine:3.3 \
    sh -c 'apk -U add nginx --repository /cxt --allow-untrusted && rm -rf /var/cache/apk/*'

# step 4: commit resulting layer
docker commit nginx-build $IMAGE

docker build -t $IMAGE - <<EOF
FROM $IMAGE
RUN mkdir -p /run/nginx &&\
    ln -sf /dev/stdout /var/log/nginx/access.log &&\
    ln -sf /dev/stderr /var/log/nginx/error.log
WORKDIR /var/lib/nginx
CMD ["nginx", "-g", "daemon off;"]
EOF

# cleanup intermediate containers
docker rm -f nginx-build
docker rm -f nginx-cxt
docker rmi nginx-cxt

