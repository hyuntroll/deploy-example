#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${COMPOSE_FILE:-${ROOT_DIR}/compose.yaml}"
VERSION_FILE="${VERSION_FILE:-${ROOT_DIR}/versions/prod.env}"
SECRETS_FILE="${SECRETS_FILE:-${ROOT_DIR}/env/prod.secrets}"
RUNTIME_DIR="${RUNTIME_DIR:-${ROOT_DIR}/.runtime}"
APP_BASE_URL="${APP_BASE_URL:-http://127.0.0.1:8080}"

[[ -s "${VERSION_FILE}" ]] || { echo "Missing ${VERSION_FILE}" >&2; exit 1; }
[[ -s "${SECRETS_FILE}" ]] || { echo "Missing ${SECRETS_FILE}" >&2; exit 1; }

mkdir -p "${RUNTIME_DIR}"

compose=(
  docker compose
  -f "${COMPOSE_FILE}"
  --env-file "${VERSION_FILE}"
  --env-file "${SECRETS_FILE}"
)

rollback() {
  if [[ ! -s "${RUNTIME_DIR}/previous.env" ]]; then
    echo "No previous release is available for rollback" >&2
    return 1
  fi

  echo "Rolling back to the previous release"
  docker compose \
    -f "${COMPOSE_FILE}" \
    --env-file "${RUNTIME_DIR}/previous.env" \
    --env-file "${SECRETS_FILE}" \
    up -d --wait
  curl --fail --silent --show-error --max-time 10 "${APP_BASE_URL}/readyz" >/dev/null
  cp "${RUNTIME_DIR}/previous.env" "${RUNTIME_DIR}/current.env"
}

if [[ -s "${RUNTIME_DIR}/current.env" ]]; then
  cp "${RUNTIME_DIR}/current.env" "${RUNTIME_DIR}/previous.env"
fi

if ! "${compose[@]}" up -d --wait; then
  rollback || true
  exit 1
fi

if ! curl --fail --silent --show-error --max-time 10 "${APP_BASE_URL}/readyz" >/dev/null; then
  "${compose[@]}" logs --tail=100 app >&2 || true
  rollback || true
  exit 1
fi

cp "${VERSION_FILE}" "${RUNTIME_DIR}/current.env"
echo "Deployment is ready"
