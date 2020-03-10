ARG     build=default

FROM    golang:1.11.5-alpine
ARG	DOCKER_VERSION=18.09.1
ENV     CGO_ENABLED=0 \
        DISABLE_WARN_OUTSIDE_CONTAINER=1 \
        VERSION=${DOCKER_VERSION}-ce
RUN     apk add --no-cache git bash coreutils gcc musl-dev make
RUN     git clone --quiet --depth=1 --single-branch --branch v${DOCKER_VERSION} \
        https://github.com/docker/cli src/github.com/docker/cli
RUN     make -C src/github.com/docker/cli binary

FROM    alpine:3.9 as default
COPY    --from=0 /go/src/github.com/docker/cli/build/docker-linux-amd64 /usr/local/bin/docker
RUN     apk add --no-cache jq openssl dumb-init
COPY    sendmail /usr/local/sbin/
COPY    docker-events /usr/local/bin/
COPY	events.d /etc/
ENTRYPOINT ["dumb-init","--"]
CMD     ["docker-events"]

FROM    alpine:3.9 as redis
COPY    --from=0 /go/src/github.com/docker/cli/build/docker-linux-amd64 /usr/local/bin/docker
RUN     apk add --no-cache jq dumb-init redis
COPY    docker-events.redis /usr/local/bin/docker-events
ENTRYPOINT ["dumb-init","--"]
CMD     ["docker-events"]

FROM    $build
