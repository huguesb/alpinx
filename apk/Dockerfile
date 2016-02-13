FROM alpine:3.3

RUN adduser build -D -G abuild &&\
    echo "build ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers &&\
    mkdir -p /var/cache/distfiles &&\
    chown build:abuild -R /var/cache/distfiles

RUN apk -U add bash alpine-sdk

RUN su build -c 'abuild-keygen -a -i -n'

RUN git clone git://dev.alpinelinux.org/aports

