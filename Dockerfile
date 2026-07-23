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
    ANDROID_TOOLS_URL=https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    GRADLE_VERSION=8.10.2 \
    GRADLE_HOME=/opt/gradle \
    TERRAFORM_VERSION=1.15.4 \
    RGA_VERSION=0.10.10 \
    PI_CODING_AGENT_VERSION=latest

ENV PATH=${GRADLE_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${PATH}

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    antiword \
    bash \
    bat \
    build-essential \
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
    openjdk-21-jdk-headless \
    openssh-client \
    pandoc \
    patch \
    poppler-utils \
    procps \
    python3 \
    python3-bs4 \
    python3-dev \
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
 && apt-get install -y --no-install-recommends nodejs

RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd \
 && ln -sf /usr/bin/batcat /usr/local/bin/bat

RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" "${GRADLE_HOME}" \
 && curl -fsSL "${ANDROID_TOOLS_URL}" -o /tmp/android-commandlinetools.zip \
 && unzip -q /tmp/android-commandlinetools.zip -d /tmp/android-commandlinetools \
 && mv /tmp/android-commandlinetools/cmdline-tools "${ANDROID_HOME}/cmdline-tools/latest" \
 && curl -fsSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o /tmp/gradle.zip \
 && unzip -q /tmp/gradle.zip -d /opt \
 && mv "/opt/gradle-${GRADLE_VERSION}"/* "${GRADLE_HOME}/" \
 && rmdir "/opt/gradle-${GRADLE_VERSION}" \
 && yes | sdkmanager --licenses >/dev/null \
 && sdkmanager \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0" \
 && chmod -R a+rwx "${ANDROID_HOME}" "${GRADLE_HOME}" \
 && rm -rf /tmp/android-commandlinetools /tmp/android-commandlinetools.zip /tmp/gradle.zip

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
 && npm cache clean --force

RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 && mkdir -p /home/pi /work /go \
 && chmod -R a+rwx /go

COPY image-skills /usr/local/share/pi-agent/skills
COPY entrypoint.sh /usr/local/bin/pi-entrypoint
RUN chmod +x /usr/local/bin/pi-entrypoint

WORKDIR /work
ENTRYPOINT ["tini", "--", "/usr/local/bin/pi-entrypoint"]
CMD ["pi"]
