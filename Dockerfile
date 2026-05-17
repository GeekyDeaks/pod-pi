FROM docker.io/library/golang:1.24-trixie

ENV NODE_ENV=development \
    DEBIAN_FRONTEND=noninteractive \
    NPM_CONFIG_AUDIT=false \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_LOGLEVEL=warn \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    GOPATH=/go \
    GOCACHE=/tmp/go-build \
    HOME=/home/pi \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    ANDROID_TOOLS_URL=https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip

ENV PATH=${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${PATH}

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    coreutils \
    curl \
    file \
    findutils \
    git \
    gnupg \
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
    openjdk-21-jdk-headless \
 && install -d -m 0755 /etc/apt/keyrings \
 && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends nodejs

RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" \
 && curl -fsSL "${ANDROID_TOOLS_URL}" -o /tmp/android-commandlinetools.zip \
 && unzip -q /tmp/android-commandlinetools.zip -d /tmp/android-commandlinetools \
 && mv /tmp/android-commandlinetools/cmdline-tools "${ANDROID_HOME}/cmdline-tools/latest" \
 && yes | sdkmanager --licenses >/dev/null \
 && sdkmanager \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0" \
 && chmod -R a+rwx "${ANDROID_HOME}" \
 && rm -rf /tmp/android-commandlinetools /tmp/android-commandlinetools.zip

RUN npm install -g \
    @earendil-works/pi-coding-agent \
 && npm cache clean --force

RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 && mkdir -p /home/pi /work /go \
 && chmod -R a+rwx /go

COPY entrypoint.sh /usr/local/bin/pi-entrypoint
RUN chmod +x /usr/local/bin/pi-entrypoint

WORKDIR /work
ENTRYPOINT ["tini", "--", "/usr/local/bin/pi-entrypoint"]
CMD ["pi"]
