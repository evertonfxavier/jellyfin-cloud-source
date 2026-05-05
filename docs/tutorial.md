# Tutorial — Jellyfin External Source

Complete guide on how to deploy, configure, and use Jellyfin with external cloud sources.

---

## 1. Starting the Container

### Option A: Using pre-built image from Docker Hub

```bash
cd example
docker compose up -d
```

### Option B: Local build (for development)

```bash
docker compose up -d --build
```

Wait for the container to start (healthcheck takes ~30s to become healthy).

---

## 2. Ports and Services

| Service          | Port   | Protocol | Description                              |
| ---------------- | ------ | -------- | ---------------------------------------- |
| **Jellyfin**     | `8096` | HTTP     | Web interface + REST API for media server |
| **TorrServer**   | `8090` | HTTP     | Torrent management and streaming API     |

### Access URLs

| Service        | URL                            |
| -------------- | ------------------------------ |
| Jellyfin Web   | http://localhost:8096          |
| Jellyfin API   | http://localhost:8096/api-docs |
| TorrServer     | http://localhost:8090          |

> **Note:** If running on a remote server, replace `localhost` with the server's IP or domain.

---

## 3. Initial Jellyfin Setup

1. Go to http://localhost:8096
2. Choose your language
3. Create the admin user
4. On the library step, skip for now — we'll configure external sources later
5. Finish the wizard

---

## 4. Using External Sources

### 4.1 Torrent (via TorrServer)

TorrServer is built into the container and started automatically by Jellyfin.

**How to add torrent content:**

1. In the Jellyfin dashboard, go to **Settings** → **Libraries**
2. Add a new library
3. Select **Cloud Source** → **Torrent**
4. Paste the magnet link or infohash
5. Choose which files from the torrent to include in the library
6. TorrServer will stream on demand — no full download required

**Direct TorrServer API:**

```bash
# List active torrents
curl http://localhost:8090/torrents

# Add magnet
curl -X POST http://localhost:8090/torrents \
  -H "Content-Type: application/json" \
  -d '{"action": "add", "link": "magnet:?xt=urn:btih:..."}'
```

### 4.2 Google Drive

1. In the Jellyfin dashboard, go to **Settings** → **Libraries**
2. Add a new library
3. Select **Cloud Source** → **Google Drive**
4. Authenticate with your Google account
5. Select the Drive folder containing your media files
6. Jellyfin will index metadata and stream directly from Drive

### 4.3 Mediafire

1. In the Jellyfin dashboard, go to **Settings** → **Libraries**
2. Add a new library
3. Select **Cloud Source** → **Mediafire**
4. Paste the Mediafire file or folder link
5. The system resolves the download link and streams directly

---

## 5. Volumes and Persistence

| Volume            | Container Path | Description                         |
| ----------------- | -------------- | ----------------------------------- |
| `jellyfin-config` | `/config`      | Settings, DB, metadata              |
| `jellyfin-cache`  | `/cache`       | Image cache and transcoding         |

To back up, copy the `jellyfin-config` volume:

```bash
docker cp jellyfin:/config ./backup-config
```

---

## 6. Environment Variables

| Variable | Default              | Description              |
| -------- | -------------------- | ------------------------ |
| `PUID`   | `1000`               | Process user ID          |
| `PGID`   | `1000`               | Process group ID         |
| `TZ`     | `America/Sao_Paulo`  | Container timezone       |

---

## 7. Network

The `docker-compose.yml` creates a bridge network with IPv6 support:

- **Network:** `jellyfin-net`
- **IPv6 Subnet:** `fd00:dead:beef::/48`

---

## 8. Healthcheck

The container has automatic healthcheck:

- **Interval:** 30s
- **Timeout:** 30s
- **Start period:** 10s
- **Retries:** 3
- **Endpoint:** `http://localhost:8096/health`

Check status:

```bash
docker inspect --format='{{.State.Health.Status}}' jellyfin
```

---

## 9. Troubleshooting

### Container won't start

```bash
docker logs jellyfin
```

### TorrServer not responding on port 8090

Check if the process is running inside the container:

```bash
docker exec jellyfin ps aux | grep TorrServer
```

### Slow transcoding

The container supports hardware acceleration (NVIDIA). Add to `docker-compose.yml`:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - capabilities: [gpu]
```

### Restart the container

```bash
docker compose restart jellyfin
```
