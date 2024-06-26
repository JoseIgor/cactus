FROM alpine:latest

LABEL maintainer="joseigorcfm@gmail.com"

WORKDIR /cactus

RUN \
    apk add --no-cache \
    g++ \
    gcovr \
    git \
    meson \
    musl-dev \
    pkgconfig \
    valgrind

# install commitlint
RUN \
    apk add --no-cache \
    nodejs \
    npm && \
    npm install -g @commitlint/cli @commitlint/config-conventional

