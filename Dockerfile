FROM node:22-trixie-slim

ENV NODE_ENV=production \
    DEBIAN_FRONTEND=noninteractive \
    NPM_CONFIG_LOGLEVEL=warn \
    HOME=/home/pi

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    procps \
    python3 \
    python3-dev \
    build-essential \
    tini \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g @earendil-works/pi-coding-agent \
 && npm cache clean --force

RUN mkdir -p /home/pi /work

COPY entrypoint.sh /usr/local/bin/pi-entrypoint
RUN chmod +x /usr/local/bin/pi-entrypoint

WORKDIR /work
ENTRYPOINT ["tini", "--", "/usr/local/bin/pi-entrypoint"]
CMD ["pi"]
