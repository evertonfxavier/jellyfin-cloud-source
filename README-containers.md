# Jellyfin Cloud Source

Custom [Jellyfin](https://jellyfin.org/) media server with built-in cloud streaming support — watch media from **Torrent**, **Google Drive**, and **Mediafire** without downloading files locally.

## Quick Start

```bash
docker run -d \
  --name jellyfin \
  -p 8096:8096 \
  -p 8090:8090 \
  -v jellyfin-config:/config \
  -v jellyfin-cache:/cache \
  -e TZ=America/Sao_Paulo \
  --restart unless-stopped \
  evertonxavier/jellyfin-cloud-source:latest
```

Or with Docker Compose:

```yaml
services:
  jellyfin:
    image: evertonxavier/jellyfin-cloud-source:latest
    container_name: jellyfin
    ports:
      - "8096:8096"  # Jellyfin Web UI + API
      - "8090:8090"  # TorrServer API
    volumes:
      - jellyfin-config:/config
      - jellyfin-cache:/cache
    environment:
      - TZ=America/Sao_Paulo
    restart: unless-stopped

volumes:
  jellyfin-config:
  jellyfin-cache:
```

Then access **http://localhost:8096**

## Supported Platforms

| Architecture | Tag       |
| ------------ | --------- |
| linux/amd64  | `amd64`   |
| linux/arm64  | `arm64`   |
| Multi-arch   | `latest`  |

## Ports

| Port   | Service      | Description                              |
| ------ | ------------ | ---------------------------------------- |
| `8096` | Jellyfin     | Web UI + REST API                        |
| `8090` | TorrServer   | Torrent streaming and management API     |

## Cloud Sources

| Source        | Description                                                    |
| ------------- | -------------------------------------------------------------- |
| **Torrent**   | Stream via magnet links using built-in TorrServer (no download required) |
| **Google Drive** | Mount Google Drive folders as media libraries              |
| **Mediafire** | Stream directly from Mediafire links                          |

## Volumes

| Path      | Description                              |
| --------- | ---------------------------------------- |
| `/config` | Jellyfin settings, database, metadata    |
| `/cache`  | Image cache and transcoding temp files   |

## Environment Variables

| Variable | Default | Description       |
| -------- | ------- | ----------------- |
| `PUID`   | `1000`  | Process user ID   |
| `PGID`   | `1000`  | Process group ID  |
| `TZ`     | —       | Container timezone |

## GPU Acceleration (optional)

For NVIDIA hardware transcoding:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - capabilities: [gpu]
```

## Links

- **Source Code**: [github.com/evertonfxavier/jellyfin-cloud-source](https://github.com/evertonfxavier/jellyfin-cloud-source)
- **Issues**: [github.com/evertonfxavier/jellyfin-cloud-source/issues](https://github.com/evertonfxavier/jellyfin-cloud-source/issues)
- **Based on**: [Jellyfin](https://jellyfin.org/) + [TorrServer](https://github.com/YouROK/TorrServer)
