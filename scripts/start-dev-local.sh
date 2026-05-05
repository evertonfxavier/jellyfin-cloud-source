#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="${ROOT_DIR}/.run"
LOG_DIR="${ROOT_DIR}/.logs"

BACKEND_PID_FILE="${RUN_DIR}/backend.pid"
FRONTEND_PID_FILE="${RUN_DIR}/frontend.pid"
MODE_FILE="${RUN_DIR}/mode"
BACKEND_LOG="${LOG_DIR}/backend.log"
FRONTEND_LOG="${LOG_DIR}/frontend.log"

mkdir -p "${RUN_DIR}" "${LOG_DIR}"

MODE="${1:-separate}"

# Common shorthand.
if [ "${MODE}" = "bundle" ]; then
  MODE="bundled"
fi

if [ "${MODE}" != "separate" ] && [ "${MODE}" != "bundled" ]; then
  echo "Modo invalido: ${MODE}"
  echo "Use: ./scripts/start-dev-local.sh [separate|bundled]"
  exit 1
fi

if [ ! -d "${ROOT_DIR}/jellyfin" ] || [ ! -d "${ROOT_DIR}/jellyfin-web" ]; then
  echo "Repos jellyfin e jellyfin-web nao encontrados em ${ROOT_DIR}."
  exit 1
fi

stop_by_pid_file() {
  local pid_file="$1"
  if [ -f "${pid_file}" ]; then
    local pid
    pid="$(cat "${pid_file}")"
    if kill -0 "${pid}" 2>/dev/null; then
      kill "${pid}" || true
    fi
    rm -f "${pid_file}"
  fi
}

start_backend() {
  local backend_args=()

  if [ "${MODE}" = "separate" ]; then
    backend_args=(--nowebclient)
  else
    backend_args=(--webdir "${ROOT_DIR}/jellyfin-web/dist")
  fi

  DOTNET_CMD="$(command -v dotnet || true)"
  DOTNET_ROOT=""

  if [ -x "/usr/local/share/dotnet/dotnet" ]; then
    DOTNET_CMD="/usr/local/share/dotnet/dotnet"
    DOTNET_ROOT="/usr/local/share/dotnet"
  fi

  if [ -z "${DOTNET_CMD}" ]; then
    echo "dotnet nao encontrado no PATH."
    exit 1
  fi

  cd "${ROOT_DIR}/jellyfin"
  if [ -n "${DOTNET_ROOT}" ]; then
    nohup env DOTNET_ROOT="${DOTNET_ROOT}" PATH="${DOTNET_ROOT}:${PATH}" \
      "${DOTNET_CMD}" run --project Jellyfin.Server "${backend_args[@]}" >"${BACKEND_LOG}" 2>&1 &
  else
    nohup "${DOTNET_CMD}" run --project Jellyfin.Server "${backend_args[@]}" >"${BACKEND_LOG}" 2>&1 &
  fi
  echo $! > "${BACKEND_PID_FILE}"
  echo "Backend iniciado (PID $(cat "${BACKEND_PID_FILE}"))."
}

start_frontend_dev_server() {
  nohup bash -lc "
    set -euo pipefail
    cd \"${ROOT_DIR}/jellyfin-web\"
    if [ -f \"\$HOME/.nvm/nvm.sh\" ]; then
      source \"\$HOME/.nvm/nvm.sh\"
      nvm use 20.20.0 >/dev/null
    fi
    npm install
    npm start
  " >"${FRONTEND_LOG}" 2>&1 &

  echo $! > "${FRONTEND_PID_FILE}"
  echo "Frontend iniciado (PID $(cat "${FRONTEND_PID_FILE}"))."
}

build_frontend_dist() {
  echo "Gerando jellyfin-web/dist para modo bundled..."
  bash -lc "
    set -euo pipefail
    cd \"${ROOT_DIR}/jellyfin-web\"
    if [ -f \"\$HOME/.nvm/nvm.sh\" ]; then
      source \"\$HOME/.nvm/nvm.sh\"
      nvm use 20.20.0 >/dev/null
    fi
    npm install
    npm run build:development
  "
}

# Troca de modo deve desligar processos existentes para evitar conflito e estado misto.
stop_by_pid_file "${BACKEND_PID_FILE}"
stop_by_pid_file "${FRONTEND_PID_FILE}"

if [ "${MODE}" = "separate" ]; then
  start_backend
  start_frontend_dev_server

  echo "separate" > "${MODE_FILE}"
  echo ""
  echo "Modo ativo: separate"
  echo "- Frontend: http://localhost:8080"
  echo "- Backend:  http://localhost:8096"
else
  build_frontend_dist
  start_backend

  echo "bundled" > "${MODE_FILE}"
  echo ""
  echo "Modo ativo: bundled"
  echo "- Web + Backend: http://localhost:8096"
fi

echo ""
echo "Servicos iniciados."
echo ""
echo "Logs:"
echo "- ${BACKEND_LOG}"
if [ "${MODE}" = "separate" ]; then
  echo "- ${FRONTEND_LOG}"
fi