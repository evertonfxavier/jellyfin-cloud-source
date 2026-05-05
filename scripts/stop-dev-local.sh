#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="${ROOT_DIR}/.run"

BACKEND_PID_FILE="${RUN_DIR}/backend.pid"
FRONTEND_PID_FILE="${RUN_DIR}/frontend.pid"
MODE_FILE="${RUN_DIR}/mode"

if [ "${1:-}" = "separate" ] || [ "${1:-}" = "bundled" ] || [ "${1:-}" = "bundle" ]; then
  echo "Aviso: stop-dev-local.sh nao usa modo. Ele sempre para backend e frontend."
fi

FOUND_PID_FILE=0
STOPPED_ANY=0

stop_by_port() {
  local name="$1"
  local port="$2"
  local pids

  pids="$(lsof -tiTCP:${port} -sTCP:LISTEN 2>/dev/null || true)"
  if [ -z "${pids}" ]; then
    echo "${name}: nada escutando na porta ${port}."
    return
  fi

  local pid
  for pid in ${pids}; do
    if kill -0 "${pid}" 2>/dev/null; then
      kill "${pid}" || true
      echo "${name}: processo finalizado via porta ${port} (PID ${pid})."
      STOPPED_ANY=1
    fi
  done
}

stop_pid() {
  local name="$1"
  local pid_file="$2"

  if [ ! -f "${pid_file}" ]; then
    echo "${name}: PID file nao encontrado."
    return
  fi

  FOUND_PID_FILE=1

  local pid
  pid="$(cat "${pid_file}")"

  if kill -0 "${pid}" 2>/dev/null; then
    kill "${pid}"
    echo "${name}: processo finalizado (PID ${pid})."
    STOPPED_ANY=1
  else
    echo "${name}: processo ja nao estava ativo (PID ${pid})."
  fi

  rm -f "${pid_file}"
}

stop_pid "Backend" "${BACKEND_PID_FILE}"
stop_pid "Frontend" "${FRONTEND_PID_FILE}"

# Fallback para casos em que os processos foram iniciados fora do script
# ou os PID files foram perdidos.
stop_by_port "Backend" 8096
stop_by_port "Frontend" 8080

if [ "${FOUND_PID_FILE}" -eq 0 ]; then
  if [ "${STOPPED_ANY}" -eq 0 ]; then
    echo "Nenhum processo iniciado pelo script foi encontrado em execucao."
    echo "Dica: use ./start-dev-local.sh separate ou ./start-dev-local.sh bundled para iniciar."
  fi
fi

rm -f "${MODE_FILE}"
