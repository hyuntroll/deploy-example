#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${COMPOSE_FILE:-${ROOT_DIR}/compose.yaml}"
SECRETS_FILE="${SECRETS_FILE:-${ROOT_DIR}/env/prod.secrets}"
RUNTIME_DIR="${RUNTIME_DIR:-${ROOT_DIR}/.runtime}"
APP_BASE_URL="${APP_BASE_URL:-http://127.0.0.1:8080}"
PREVIOUS_FILE="${RUNTIME_DIR}/previous.env"

[[ -s "${PREVIOUS_FILE}" ]] || { echo "Missing ${PREVIOUS_FILE}" >&2; exit 1; }
[[ -s "${SECRETS_FILE}" ]] || { echo "Missing ${SECRETS_FILE}" >&2; exit 1; }

docker compose \
  -f "${COMPOSE_FILE}" \
  --env-file "${PREVIOUS_FILE}" \
  --env-file "${SECRETS_FILE}" \
  up -d --wait
curl --fail --silent --show-error --max-time 10 "${APP_BASE_URL}/readyz" >/dev/null
cp "${PREVIOUS_FILE}" "${RUNTIME_DIR}/current.env"
echo "Rollback is ready"
