#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docker compose \
  -f "${ROOT_DIR}/compose.yaml" \
  --env-file "${ROOT_DIR}/versions/prod.env" \
  --env-file "${ROOT_DIR}/env/prod.secrets.example" \
  config --quiet

echo "Infra configuration is valid"
