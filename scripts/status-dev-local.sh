#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="${ROOT_DIR}/.run"

BACKEND_PID_FILE="${RUN_DIR}/backend.pid"
FRONTEND_PID_FILE="${RUN_DIR}/frontend.pid"
MODE_FILE="${RUN_DIR}/mode"

print_pid_status() {
  local name="$1"
  local pid_file="$2"

  if [ ! -f "${pid_file}" ]; then
    echo "${name}: PID file ausente"
    return
  fi

  local pid
  pid="$(cat "${pid_file}")"
  if kill -0 "${pid}" 2>/dev/null; then
    echo "${name}: ativo (PID ${pid})"
  else
    echo "${name}: PID file presente, mas processo inativo (PID ${pid})"
  fi
}

print_port_status() {
  local name="$1"
  local port="$2"
  local pids

  pids="$(lsof -tiTCP:${port} -sTCP:LISTEN 2>/dev/null || true)"
  if [ -z "${pids}" ]; then
    echo "${name} porta ${port}: livre"
  else
    echo "${name} porta ${port}: em uso (PID(s): ${pids//$'\n'/, })"
  fi
}

echo "Status Jellyfin local"
if [ -f "${MODE_FILE}" ]; then
  echo "Modo: $(cat "${MODE_FILE}")"
else
  echo "Modo: desconhecido (arquivo .run/mode ausente)"
fi

print_pid_status "Backend" "${BACKEND_PID_FILE}"
print_pid_status "Frontend" "${FRONTEND_PID_FILE}"

print_port_status "Backend" 8096
print_port_status "Frontend" 8080
