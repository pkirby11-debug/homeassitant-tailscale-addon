ARG BUILD_FROM=alpine:3.20
FROM ${BUILD_FROM}

ENV LANG=C.UTF-8

RUN apk add --no-cache \
    ca-certificates \
    iptables \
    ip6tables \
    iproute2 \
    bash \
    curl \
    jq

ARG BUILD_ARCH
ARG TAILSCALE_VERSION="1.92.3"

RUN case "${BUILD_ARCH}" in \
        "aarch64") TS_ARCH="arm64" ;; \
        "amd64")   TS_ARCH="amd64" ;; \
        "armhf")   TS_ARCH="arm" ;; \
        "armv7")   TS_ARCH="arm" ;; \
        *) echo "Unsupported architecture: ${BUILD_ARCH}" && exit 1 ;; \
    esac && \
    echo "Downloading Tailscale v${TAILSCALE_VERSION} for ${TS_ARCH}..." && \
    curl -sSL "https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_VERSION}_${TS_ARCH}.tgz" -o /tmp/tailscale.tgz && \
    tar -xzf /tmp/tailscale.tgz -C /tmp && \
    mv /tmp/tailscale_${TAILSCALE_VERSION}_${TS_ARCH}/tailscale /usr/bin/tailscale && \
    mv /tmp/tailscale_${TAILSCALE_VERSION}_${TS_ARCH}/tailscaled /usr/sbin/tailscaled && \
    rm -rf /tmp/tailscale*

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
