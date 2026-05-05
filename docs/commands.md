## Jellyfin local - comandos

### Rodar pela raiz do projeto

Modo separado (frontend + backend nowebclient):

```bash
./scripts/start-dev-local.sh separate
```

Modo backend servindo web (bundled):

```bash
./scripts/start-dev-local.sh bundled
```

Atalho aceito:

```bash
./scripts/start-dev-local.sh bundle
```

Parar tudo:

```bash
./scripts/stop-dev-local.sh
```

Ver status (modo, PID e portas):

```bash
./scripts/status-dev-local.sh
```

### Rodar de dentro da pasta scripts

Modo separado:

```bash
./start-dev-local.sh separate
```

Modo bundled:

```bash
./start-dev-local.sh bundled
```

Atalho:

```bash
./start-dev-local.sh bundle
```

Parar tudo:

```bash
./stop-dev-local.sh
```

Ver status:

```bash
./status-dev-local.sh
```

Observacao: `stop-dev-local.sh` nao recebe modo (`separate`/`bundled`).

### URLs

- Modo `separate`: frontend em `http://localhost:8080` e backend em `http://localhost:8096`
- Modo `bundled`: web + backend em `http://localhost:8096`

## Rodar sem script (manual)

### 1) Modo separate (frontend separado + backend nowebclient)

Terminal A (backend):

```bash
cd /Users/everton/personal/jellyfin/jellyfin
DOTNET_ROOT=/usr/local/share/dotnet PATH="/usr/local/share/dotnet:$PATH" /usr/local/share/dotnet/dotnet run --project Jellyfin.Server --nowebclient
```

Terminal B (frontend):

```bash
cd /Users/everton/personal/jellyfin/jellyfin-web
source ~/.nvm/nvm.sh
nvm use 20.20.0
npm install
npm start
```

### 2) Modo bundled (backend servindo o dist do frontend)

Gerar frontend:

```bash
cd /Users/everton/personal/jellyfin/jellyfin-web
source ~/.nvm/nvm.sh
nvm use 20.20.0
npm install
npm run build:development
```

Subir backend apontando para o dist:

```bash
cd /Users/everton/personal/jellyfin/jellyfin
DOTNET_ROOT=/usr/local/share/dotnet PATH="/usr/local/share/dotnet:$PATH" /usr/local/share/dotnet/dotnet run --project Jellyfin.Server --webdir /Users/everton/personal/jellyfin/jellyfin-web/dist
```

### Parar processos manualmente

- Se estiverem em primeiro plano, use `Ctrl + C` em cada terminal.
- Se tiver deixado em background, use `pkill -f "Jellyfin.Server"` e `pkill -f "webpack serve"`.

## Diagnostico rapido

Se `stop` nao encerrar algo, rode:

```bash
./scripts/status-dev-local.sh
```

O `stop-dev-local.sh` agora tenta:

1. Encerrar por PID file (`.run/backend.pid`, `.run/frontend.pid`)
2. Fallback por porta (`8096` backend e `8080` frontend)

