#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-falseflag-demo}"

if ! command -v k3d >/dev/null 2>&1; then
  echo "missing required command: k3d" >&2
  exit 1
fi

k3d cluster delete "${CLUSTER_NAME}"
