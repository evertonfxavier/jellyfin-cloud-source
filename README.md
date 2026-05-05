# Jellyfin External Source

Fork customizado do [Jellyfin](https://jellyfin.org/) com suporte a fontes de mídia na nuvem — **Torrent (via TorrServer)**, **Google Drive** e **Mediafire** — sem precisar baixar arquivos localmente.

## Arquitetura

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
         ▼ Fontes externas
   ┌─────────────┐  ┌──────────┐  ┌───────────┐
   │   Torrent   │  │  Google  │  │ Mediafire │
   │  (magnet)   │  │  Drive   │  │           │
   └─────────────┘  └──────────┘  └───────────┘
```

## Funcionalidades

- **Torrent Streaming** — Integração com TorrServer embutido. Adicione magnets e assista em tempo real sem download prévio.
- **Google Drive** — Adicione bibliotecas apontando para pastas do Google Drive como fonte de mídia.
- **Mediafire** — Suporte a links do Mediafire como fonte externa de arquivos de mídia.
- **Interface customizada** — UI modificada para gerenciar fontes na nuvem diretamente pelo painel do Jellyfin.

## Estrutura do Projeto

```
.
├── Dockerfile              # Build multi-stage (server + web + TorrServer)
├── docker-compose.yml      # Stack completa para deploy
├── package.json            # Script de build multi-arch
├── submodules/
│   ├── jellyfin/           # [submodule] jellyfin-server customizado
│   └── jellyfin-web/       # [submodule] jellyfin-web customizado
├── scripts/                # Scripts de desenvolvimento local
└── example/                # Exemplo de deploy usando imagem pronta
```

## Início Rápido

### Com Docker Compose (build local)

```bash
git clone --recurse-submodules git@github.com-personal:evertonfxavier/jellyfin-external-source.git
cd jellyfin-external-source
docker compose up -d --build
```

Acesse: http://localhost:8096

### Usando imagem pronta

```bash
cd example
docker compose up -d
```

## Desenvolvimento Local

### Pré-requisitos

- .NET SDK 9.0
- Node.js 20+
- npm

### Modo separado (frontend hot-reload + backend)

```bash
./scripts/start-dev-local.sh separate
```

### Modo bundled (backend servindo o web)

```bash
./scripts/start-dev-local.sh bundled
```

### Parar / Status

```bash
./scripts/stop-dev-local.sh
./scripts/status-dev-local.sh
```

## Build Multi-Arch (amd64 + arm64)

```bash
npm run build
```

Isso gera e faz push da imagem `evertonxavier/jellyfin-external-source:latest` para o Docker Hub.

## Portas

| Serviço     | Porta | Descrição            |
| ----------- | ----- | -------------------- |
| Jellyfin    | 8096  | Web UI + API         |
| TorrServer  | 8090  | API de streaming     |

## Submodules

| Pasta                   | Repositório                                                    | Branch |
| ----------------------- | -------------------------------------------------------------- | ------ |
| `submodules/jellyfin/`  | `git@github.com-personal:evertonfxavier/jellyfin-server.git`   | master |
| `submodules/jellyfin-web/` | `git@github.com-personal:evertonfxavier/jellyfin-web.git`   | master |

Para atualizar os submodules:

```bash
git submodule update --remote --merge
```

## Stack

- **Backend**: C# / .NET 9 (Jellyfin Server)
- **Frontend**: TypeScript / React (Jellyfin Web)
- **Streaming**: TorrServer (Go)
- **Container**: Debian Trixie + jellyfin-ffmpeg7
