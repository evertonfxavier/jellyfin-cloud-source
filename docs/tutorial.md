# Tutorial — Jellyfin External Source

Guia completo de como subir, configurar e usar o Jellyfin com fontes externas na nuvem.

---

## 1. Subindo o Container

### Opção A: Usando imagem pronta do Docker Hub

```bash
cd example
docker compose up -d
```

### Opção B: Build local (para desenvolvimento)

```bash
docker compose up -d --build
```

Aguarde o container iniciar (o healthcheck leva ~30s para ficar saudável).

---

## 2. Portas e Serviços

| Serviço          | Porta  | Protocolo | Descrição                                  |
| ---------------- | ------ | --------- | ------------------------------------------ |
| **Jellyfin**     | `8096` | HTTP      | Interface web + API REST do media server    |
| **TorrServer**   | `8090` | HTTP      | API de gerenciamento e streaming de torrent |

### URLs de acesso

| Serviço        | URL                          |
| -------------- | ---------------------------- |
| Jellyfin Web   | http://localhost:8096        |
| Jellyfin API   | http://localhost:8096/api-docs |
| TorrServer     | http://localhost:8090        |

> **Nota:** Se estiver rodando em um servidor remoto, substitua `localhost` pelo IP ou domínio do servidor.

---

## 3. Configuração Inicial do Jellyfin

1. Acesse http://localhost:8096
2. Escolha o idioma (Português Brasil disponível)
3. Crie o usuário administrador
4. Na etapa de bibliotecas, pule por enquanto — vamos configurar as fontes externas depois
5. Finalize o wizard

---

## 4. Usando Fontes Externas

### 4.1 Torrent (via TorrServer)

O TorrServer já vem embutido no container e é iniciado automaticamente pelo Jellyfin.

**Como adicionar conteúdo via torrent:**

1. No painel do Jellyfin, vá em **Configurações** → **Bibliotecas**
2. Adicione uma nova biblioteca
3. Selecione a opção de **Fonte na Nuvem** → **Torrent**
4. Cole o link magnet ou infohash do torrent
5. Escolha quais arquivos da torrent deseja incluir na biblioteca
6. O TorrServer fará o streaming sob demanda — sem download completo

**API direta do TorrServer:**

```bash
# Listar torrents ativos
curl http://localhost:8090/torrents

# Adicionar magnet
curl -X POST http://localhost:8090/torrents \
  -H "Content-Type: application/json" \
  -d '{"action": "add", "link": "magnet:?xt=urn:btih:..."}'
```

### 4.2 Google Drive

1. No painel do Jellyfin, vá em **Configurações** → **Bibliotecas**
2. Adicione uma nova biblioteca
3. Selecione **Fonte na Nuvem** → **Google Drive**
4. Autentique com sua conta Google
5. Selecione a pasta do Drive que contém seus arquivos de mídia
6. O Jellyfin vai indexar os metadados e fazer streaming direto do Drive

### 4.3 Mediafire

1. No painel do Jellyfin, vá em **Configurações** → **Bibliotecas**
2. Adicione uma nova biblioteca
3. Selecione **Fonte na Nuvem** → **Mediafire**
4. Cole o link do arquivo ou pasta do Mediafire
5. O sistema resolve o link de download e faz streaming direto

---

## 5. Volumes e Persistência

| Volume            | Caminho no container | Descrição                          |
| ----------------- | -------------------- | ---------------------------------- |
| `jellyfin-config` | `/config`            | Configurações, DB, metadados       |
| `jellyfin-cache`  | `/cache`             | Cache de imagens e transcodificação |

Para fazer backup, copie o volume `jellyfin-config`:

```bash
docker cp jellyfin:/config ./backup-config
```

---

## 6. Variáveis de Ambiente

| Variável | Padrão               | Descrição                |
| -------- | -------------------- | ------------------------ |
| `PUID`   | `1000`               | User ID do processo      |
| `PGID`   | `1000`               | Group ID do processo     |
| `TZ`     | `America/Sao_Paulo`  | Timezone do container    |

---

## 7. Rede

O `docker-compose.yml` cria uma rede bridge com suporte a IPv6:

- **Rede:** `jellyfin-net`
- **Subnet IPv6:** `fd00:dead:beef::/48`

---

## 8. Healthcheck

O container possui healthcheck automático:

- **Intervalo:** 30s
- **Timeout:** 30s
- **Start period:** 10s
- **Retries:** 3
- **Endpoint:** `http://localhost:8096/health`

Verifique o status:

```bash
docker inspect --format='{{.State.Health.Status}}' jellyfin
```

---

## 9. Troubleshooting

### Container não inicia

```bash
docker logs jellyfin
```

### TorrServer não responde na porta 8090

Verifique se o processo está ativo dentro do container:

```bash
docker exec jellyfin ps aux | grep TorrServer
```

### Transcodificação lenta

O container suporta aceleração por hardware (NVIDIA). Adicione ao `docker-compose.yml`:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - capabilities: [gpu]
```

### Reiniciar o container

```bash
docker compose restart jellyfin
```
