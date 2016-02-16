Alpinx
======

A minimal and up-to-date nginx image based on Alpine Linux.


Why ?
-----

At this time:

 1. Nginx maintainers are still using a bloated `debian:jessie` base image
 2. Alpine packages nginx stable (1.8) instead of mainline (1.9)

This image gives the best of both world: up-to-date nginx in a small image.


License
-------

BSD 2-Clause, see accompanying LICENSE file.


Usage
-----

The latest build of this image (1.9.11) is available on [Docker Hub](https://hub.docker.com/r/huguesb/alpinx/)

```
docker run -p 8080:80 huguesb/alpinx
```

Or

```
FROM hugues/alpinx
...
```

Build Requirements
------------------

 - bash
 - docker 1.5+


Implentation details
--------------------

To build this image from scratch, a two-step process is required:

 1. Build apk package(s) from source on the host

    ```
    ./apk/build.sh
    ```

    This is rather slow, should be fairly infrequent, and uses explicit
    mapping of volumes to host folders so it cannot be easily integrated
    in a containerized CI.

    Instead, the artifacts are stored in the repo and have to be rebuilt
    manually as needed. 

 2. Install the package(s) into a docker image

    ```bash
    ./build.sh
    ```

    This will build and tag `huguesb/alpinx` locally, instead of fetching it
    from [Docker Hub](https://hub.docker.com/r/huguesb/alpinx/).

    Doing the second step "right" is a little convoluted due to limitations
    of the `docker build` command. In particular, it is not possible to
    access files from the build context in a RUN statement. One could use
    a COPY statement but then the intermediate artifacts would remain in the
    final image even if a `rm` command were used in a subsequent layer.

    To be easily integrated in a containerized CI, this script eschews
    explicit mapping of volumes to host folders, which requires additional
    contorsions.

