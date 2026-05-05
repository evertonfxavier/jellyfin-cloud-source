# =============================================================================
# Jellyfin + TorrServer — Custom Docker Image
# Based on https://github.com/jellyfin/jellyfin-packaging/blob/master/docker/Dockerfile
# =============================================================================

ARG DOTNET_VERSION=9.0
ARG NODEJS_VERSION=20
ARG OS_VERSION=trixie
ARG FFMPEG_PACKAGE=jellyfin-ffmpeg7
ARG TORRSERVER_VERSION=MatriX.141

# =============================================================================
# Stage 1: Build jellyfin-web
# =============================================================================
FROM node:${NODEJS_VERSION}-alpine AS web

RUN apk add --no-cache \
    autoconf g++ make libpng-dev gifsicle alpine-sdk \
    automake libtool gcc musl-dev nasm python3 git

WORKDIR /src
COPY submodules/jellyfin-web .

RUN npm ci --no-audit --unsafe-perm \
    && npm run build:production \
    && mv dist /web

# =============================================================================
# Stage 2: Build jellyfin-server
# =============================================================================
FROM debian:${OS_VERSION}-slim AS server

ARG DOTNET_VERSION
ARG DOTNET_ARCH

WORKDIR /src
COPY submodules/jellyfin .

ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests --yes \
    curl ca-certificates libicu76 \
    && curl -fsSL https://dot.net/v1/dotnet-install.sh \
    | bash /dev/stdin --channel ${DOTNET_VERSION} --install-dir /usr/local/bin

RUN dotnet publish Jellyfin.Server \
    --configuration Release \
    --output /server \
    --self-contained \
    -p:DebugSymbols=false \
    -p:DebugType=none

# =============================================================================
# Stage 3: Download TorrServer binary
# =============================================================================
FROM debian:${OS_VERSION}-slim AS torrserver

ARG TORRSERVER_VERSION
ARG TARGETARCH

RUN apt-get update \
    && apt-get install --no-install-recommends --yes curl ca-certificates \
    && ARCH=$(case "${TARGETARCH}" in \
    amd64) echo "amd64" ;; \
    arm64) echo "arm64" ;; \
    arm)   echo "arm7" ;; \
    *)     echo "amd64" ;; \
    esac) \
    && curl -fsSL -o /TorrServer \
    "https://github.com/YouROK/TorrServer/releases/download/${TORRSERVER_VERSION}/TorrServer-linux-${ARCH}" \
    && chmod +x /TorrServer

# =============================================================================
# Stage 4: Final combined image
# =============================================================================
FROM debian:${OS_VERSION}-slim AS combined

ARG OS_VERSION
ARG FFMPEG_PACKAGE
ARG TARGETARCH

# Map Docker arch to Debian arch
RUN DEBIAN_ARCH=$(case "${TARGETARCH}" in \
    amd64) echo "amd64" ;; \
    arm64) echo "arm64" ;; \
    arm)   echo "armhf" ;; \
    *)     echo "amd64" ;; \
    esac) \
    && echo "${DEBIAN_ARCH}" > /tmp/debian_arch

ENV HEALTHCHECK_URL=http://localhost:8096/health

ENV DEBIAN_FRONTEND="noninteractive" \
    LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    JELLYFIN_DATA_DIR="/config" \
    JELLYFIN_CACHE_DIR="/cache" \
    JELLYFIN_CONFIG_DIR="/config/config" \
    JELLYFIN_LOG_DIR="/config/log" \
    JELLYFIN_WEB_DIR="/jellyfin/jellyfin-web" \
    JELLYFIN_FFMPEG="/usr/lib/jellyfin-ffmpeg/ffmpeg"

ENV XDG_CACHE_HOME=${JELLYFIN_CACHE_DIR}
ENV MALLOC_TRIM_THRESHOLD_=131072

# Nvidia support
ENV NVIDIA_VISIBLE_DEVICES="all"
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

# Install jellyfin-ffmpeg + runtime deps
RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests --yes \
    ca-certificates gnupg curl \
    && curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg \
    && DEBIAN_ARCH=$(cat /tmp/debian_arch) \
    && cat <<EOF > /etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/debian
Suites: ${OS_VERSION}
Components: main
Architectures: ${DEBIAN_ARCH}
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF
RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests --yes \
    ${FFMPEG_PACKAGE} openssl locales libicu76 libfontconfig1 libfreetype6 \
    && sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && apt-get remove gnupg --yes \
    && apt-get clean autoclean --yes \
    && apt-get autoremove --yes \
    && rm -rf /var/cache/apt/archives* /var/lib/apt/lists/*

# Create dirs
RUN mkdir -p ${JELLYFIN_DATA_DIR} ${JELLYFIN_CACHE_DIR} \
    && chmod 777 ${JELLYFIN_DATA_DIR} ${JELLYFIN_CACHE_DIR}

# Copy artifacts from build stages
COPY --from=server /server /jellyfin
COPY --from=web /web /jellyfin/jellyfin-web
COPY --from=torrserver /TorrServer /jellyfin/TorrServer

EXPOSE 8096 8090

VOLUME ${JELLYFIN_DATA_DIR} ${JELLYFIN_CACHE_DIR}

ENTRYPOINT ["/jellyfin/jellyfin"]

HEALTHCHECK --interval=30s --timeout=30s --start-period=10s --retries=3 \
    CMD curl --noproxy 'localhost' -Lk -fsS "${HEALTHCHECK_URL}" || exit 1
