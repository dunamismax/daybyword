# The Linux environment for make test-linux and the CI Linux job: Ubuntu
# 24.04 with the Swift toolchain named in .swift-version, installed and
# signature-checked by install-swift.sh, as on the server (docs/decisions.md
# E22). Build it with
#   docker build --build-arg SWIFT_VERSION=$(cat .swift-version) scripts/linux
FROM ubuntu:24.04

ARG SWIFT_VERSION
ENV DEBIAN_FRONTEND=noninteractive

# What the toolchain needs on Ubuntu 24.04 (swift.org's install notes), plus
# curl and gpg for the installer and libsqlite3-dev for ReadingData.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       binutils ca-certificates curl git gnupg libc6-dev libcurl4-openssl-dev libedit2 \
       libgcc-13-dev libncurses-dev libpython3-dev libsqlite3-0 libsqlite3-dev \
       libstdc++-13-dev libxml2-dev libz3-dev pkg-config tzdata unzip zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

COPY install-swift.sh swift-signing-keys.asc /tmp/install-swift/
RUN test -n "$SWIFT_VERSION" \
    && sh /tmp/install-swift/install-swift.sh "$SWIFT_VERSION" /opt/swift \
    && rm -rf /tmp/install-swift

ENV PATH=/opt/swift/${SWIFT_VERSION}/usr/bin:$PATH
