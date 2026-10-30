# The Linux environment for make test-linux and the CI Linux job: Ubuntu
# 24.04 with the Swift toolchain named in .swift-version, installed through
# swiftly as on the server (docs/decisions.md E21). Build it with
#   docker build --build-arg SWIFT_VERSION=$(cat .swift-version) scripts/linux
FROM ubuntu:24.04

ARG SWIFT_VERSION
ENV DEBIAN_FRONTEND=noninteractive \
    SWIFTLY_HOME_DIR=/opt/swiftly \
    SWIFTLY_BIN_DIR=/opt/swiftly/bin \
    PATH=/opt/swiftly/bin:$PATH

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gnupg libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# swiftly, checked against swift.org's signing keys.
RUN set -eux; \
    cd /tmp; \
    curl -fsSL https://www.swift.org/keys/all-keys.asc | gpg --batch --import -; \
    curl -fsSLO "https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz"; \
    curl -fsSLO "https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz.sig"; \
    gpg --batch --verify "swiftly-$(uname -m).tar.gz.sig" "swiftly-$(uname -m).tar.gz"; \
    tar -xzf "swiftly-$(uname -m).tar.gz"; \
    ./swiftly init --assume-yes --skip-install --quiet-shell-followup; \
    rm -f swiftly "swiftly-$(uname -m).tar.gz" "swiftly-$(uname -m).tar.gz.sig"

# The pinned toolchain and the system packages it needs.
RUN set -eux; \
    test -n "$SWIFT_VERSION"; \
    apt-get update; \
    swiftly install --assume-yes --use "$SWIFT_VERSION" --post-install-file=/tmp/post-install.sh; \
    if [ -f /tmp/post-install.sh ]; then sh /tmp/post-install.sh; fi; \
    rm -rf /var/lib/apt/lists/* /tmp/post-install.sh; \
    swift --version
