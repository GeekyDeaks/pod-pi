FROM node:22-trixie-slim

ARG PI_VERSION=0.74.0
ARG MISTRALAI_VERSION=2.2.0

ENV NODE_ENV=production \
    DEBIAN_FRONTEND=noninteractive \
    NPM_CONFIG_AUDIT=false \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_LOGLEVEL=warn \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    HOME=/home/pi

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    coreutils \
    curl \
    file \
    findutils \
    git \
    grep \
    jq \
    less \
    openssh-client \
    patch \
    procps \
    python3 \
    python3-dev \
    build-essential \
    ripgrep \
    tini \
    tmux \
    unzip \
    zip \
 && npm install -g --omit=dev \
    @earendil-works/pi-coding-agent@${PI_VERSION} \
    @mistralai/mistralai@${MISTRALAI_VERSION} \
 && npm cache clean --force \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 && mkdir -p /home/pi /work

COPY entrypoint.sh /usr/local/bin/pi-entrypoint
RUN chmod +x /usr/local/bin/pi-entrypoint

WORKDIR /work
ENTRYPOINT ["tini", "--", "/usr/local/bin/pi-entrypoint"]
CMD ["pi"]
