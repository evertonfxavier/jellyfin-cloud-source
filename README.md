# Jellyfin Cloud Source

Custom [Jellyfin](https://jellyfin.org/) fork with cloud media source support — **Torrent (via TorrServer)**, **Google Drive**, and **Mediafire** — no local downloads required.

## Architecture

```
┌─────────────────────────────────────────────┐
│            Docker Container                  │
│                                              │
│  ┌──────────────┐    ┌───────────────────┐  │
│  │  Jellyfin    │    │   TorrServer      │  │
│  │  Server      │◄──►│   (streaming)     │  │
│  │  :8096       │    │   :8090           │  │
│  └──────┬───────┘    └───────────────────┘  │
│         │                                    │
│  ┌──────┴───────┐                            │
│  │ Jellyfin Web │                            │
│  │ (custom UI)  │                            │
│  └──────────────┘                            │
└─────────────────────────────────────────────┘
         │
         ▼ External Sources
   ┌─────────────┐  ┌──────────┐  ┌───────────┐
   │   Torrent   │  │  Google  │  │ Mediafire │
   │  (magnet)   │  │  Drive   │  │           │
   └─────────────┘  └──────────┘  └───────────┘
```

## Features

- **Torrent Streaming** — Built-in TorrServer integration. Add magnets and watch in real-time without prior download.
- **Google Drive** — Add libraries pointing to Google Drive folders as media sources.
- **Mediafire** — Support for Mediafire links as external media file sources.
- **Custom UI** — Modified interface to manage cloud sources directly from the Jellyfin dashboard.

## Project Structure

```
.
├── Dockerfile              # Multi-stage build (server + web + TorrServer)
├── docker-compose.yml      # Full stack for deployment
├── package.json            # Multi-arch build script
├── submodules/
│   ├── jellyfin/           # [submodule] custom jellyfin-server
│   └── jellyfin-web/       # [submodule] custom jellyfin-web
├── scripts/                # Local development scripts
└── example/                # Deploy example using pre-built image
```

## Docker Image

Pre-built multi-arch image available on Docker Hub:

```
docker pull evertonxavier/jellyfin-cloud-source:latest
```

[![Docker Hub](https://img.shields.io/docker/pulls/evertonxavier/jellyfin-cloud-source)](https://hub.docker.com/r/evertonxavier/jellyfin-cloud-source)

Platforms: `linux/amd64`, `linux/arm64`

## Quick Start

### With pre-built image

```bash
docker run -d \
  --name jellyfin \
  -p 8096:8096 \
  -p 8090:8090 \
  -v jellyfin-config:/config \
  -v jellyfin-cache:/cache \
  evertonxavier/jellyfin-cloud-source:latest
```

Access: http://localhost:8096

### With Docker Compose (local build)

```bash
git clone --recurse-submodules git@github.com-personal:evertonfxavier/jellyfin-cloud-source.git
cd jellyfin-cloud-source
docker compose up -d --build
```

## Local Development

### Prerequisites

- .NET SDK 9.0
- Node.js 20+
- npm

### Separate mode (frontend hot-reload + backend)

```bash
./scripts/start-dev-local.sh separate
```

### Bundled mode (backend serving web)

```bash
./scripts/start-dev-local.sh bundled
```

### Stop / Status

```bash
./scripts/stop-dev-local.sh
./scripts/status-dev-local.sh
```

## Multi-Arch Build (amd64 + arm64)

```bash
npm run build
```

This builds and pushes the `evertonxavier/jellyfin-cloud-source:latest` image to Docker Hub.

## Ports

| Service     | Port  | Description          |
| ----------- | ----- | -------------------- |
| Jellyfin    | 8096  | Web UI + API         |
| TorrServer  | 8090  | Streaming API        |

## Submodules

| Path                       | Repository                                                     | Branch |
| -------------------------- | -------------------------------------------------------------- | ------ |
| `submodules/jellyfin/`     | `git@github.com-personal:evertonfxavier/jellyfin-server.git`   | master |
| `submodules/jellyfin-web/` | `git@github.com-personal:evertonfxavier/jellyfin-web.git`      | master |

To update submodules:

```bash
git submodule update --remote --merge
```

## Stack

- **Backend**: C# / .NET 9 (Jellyfin Server)
- **Frontend**: TypeScript / React (Jellyfin Web)
- **Streaming**: TorrServer (Go)
- **Container**: Debian Trixie + jellyfin-ffmpeg7
