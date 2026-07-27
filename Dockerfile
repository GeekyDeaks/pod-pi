ARG DEBIAN_VERSION=trixie-slim
ARG GO_IMAGE=docker.io/library/golang:1.24-trixie

FROM docker.io/library/debian:${DEBIAN_VERSION} AS base

ENV NODE_ENV=development \
    DEBIAN_FRONTEND=noninteractive \
    NPM_CONFIG_AUDIT=false \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_LOGLEVEL=warn \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    HOME=/home/pi \
    TERRAFORM_VERSION=1.15.4 \
    RGA_VERSION=0.10.10 \
    LIGHTDASH_CLI_VERSION=latest \
    PI_CODING_AGENT_VERSION=latest

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    antiword \
    bash \
    bat \
    bzip2 \
    ca-certificates \
    catdoc \
    coreutils \
    csvkit \
    curl \
    ddgr \
    djvulibre-bin \
    dnsutils \
    docx2txt \
    fd-find \
    ffmpeg \
    file \
    findutils \
    git \
    gnupg \
    graphviz \
    grep \
    html2text \
    imagemagick \
    iproute2 \
    iputils-ping \
    jq \
    less \
    libimage-exiftool-perl \
    mediainfo \
    miller \
    netcat-openbsd \
    nmap \
    odt2txt \
    openssh-client \
    pandoc \
    patch \
    poppler-utils \
    procps \
    postgresql-client \
    python3 \
    python3-bs4 \
    python3-lxml \
    python3-numpy \
    python3-opencv \
    python3-openpyxl \
    python3-pandas \
    python3-pil \
    python3-pip \
    python3-requests \
    python3-httpx \
    python3-venv \
    python3-yaml \
    qpdf \
    ripgrep \
    sqlite3 \
    tcpdump \
    tesseract-ocr \
    tesseract-ocr-eng \
    tini \
    tmux \
    universal-ctags \
    traceroute \
    tree \
    unrar-free \
    unrtf \
    unzip \
    whois \
    w3m \
    xmlstarlet \
    xz-utils \
    zip \
    zstd \
    7zip \
 && install -d -m 0755 /etc/apt/keyrings \
 && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends nodejs \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd \
 && ln -sf /usr/bin/batcat /usr/local/bin/bat

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) terraform_arch=amd64 ;; \
      arm64) terraform_arch=arm64 ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${terraform_arch}.zip" -o /tmp/terraform.zip; \
    unzip -q /tmp/terraform.zip -d /usr/local/bin; \
    chmod +x /usr/local/bin/terraform; \
    terraform -version; \
    rm -f /tmp/terraform.zip

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) rga_target=x86_64-unknown-linux-musl ;; \
      arm64) rga_target=aarch64-unknown-linux-gnu ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    rga_dir="ripgrep_all-v${RGA_VERSION}-${rga_target}"; \
    curl -fsSL "https://github.com/phiresky/ripgrep-all/releases/download/v${RGA_VERSION}/${rga_dir}.tar.gz" -o /tmp/ripgrep-all.tar.gz; \
    tar -xzf /tmp/ripgrep-all.tar.gz -C /tmp; \
    install -m 0755 "/tmp/${rga_dir}/rga" "/tmp/${rga_dir}/rga-preproc" /usr/local/bin/; \
    rga --version; \
    rm -rf /tmp/ripgrep-all.tar.gz "/tmp/${rga_dir}"

RUN npm install -g \
    "@earendil-works/pi-coding-agent@${PI_CODING_AGENT_VERSION}" \
    "@lightdash/cli@${LIGHTDASH_CLI_VERSION}" \
 && npm cache clean --force

RUN rm -rf /tmp/* /var/tmp/* \
 && mkdir -p /home/pi /work \
 && chmod a+rwx /home/pi /work

COPY image-skills /usr/local/share/pi-agent/skills
COPY entrypoint.sh /usr/local/bin/pi-entrypoint
RUN chmod +x /usr/local/bin/pi-entrypoint

WORKDIR /work
ENTRYPOINT ["tini", "--", "/usr/local/bin/pi-entrypoint"]
CMD ["pi"]

FROM ${GO_IMAGE} AS go-toolchain

FROM base AS go
ENV GOPATH=/go \
    GOCACHE=/tmp/go-build \
    PATH=/usr/local/go/bin:${PATH}
COPY --from=go-toolchain /usr/local/go /usr/local/go
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /go \
 && chmod -R a+rwx /go

FROM base AS adk
ENV GRADLE_VERSION=8.10.2 \
    GRADLE_HOME=/opt/gradle \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    ANDROID_TOOLS_URL=https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    PATH=/opt/gradle/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/emulator:${PATH}
RUN apt-get update \
 && apt-get install -y --no-install-recommends openjdk-21-jdk-headless \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p "${GRADLE_HOME}" "${ANDROID_HOME}/cmdline-tools" \
 && curl -fsSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o /tmp/gradle.zip \
 && unzip -q /tmp/gradle.zip -d /opt \
 && mv "/opt/gradle-${GRADLE_VERSION}"/* "${GRADLE_HOME}/" \
 && rmdir "/opt/gradle-${GRADLE_VERSION}" \
 && curl -fsSL "${ANDROID_TOOLS_URL}" -o /tmp/android-commandlinetools.zip \
 && unzip -q /tmp/android-commandlinetools.zip -d /tmp/android-commandlinetools \
 && mv /tmp/android-commandlinetools/cmdline-tools "${ANDROID_HOME}/cmdline-tools/latest" \
 && yes | sdkmanager --licenses >/dev/null \
 && sdkmanager \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0" \
 && chmod -R a+rwx "${GRADLE_HOME}" "${ANDROID_HOME}" \
 && rm -rf /tmp/gradle.zip /tmp/android-commandlinetools /tmp/android-commandlinetools.zip

FROM base AS final
