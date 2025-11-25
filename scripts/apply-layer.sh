#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <layer-folder> [terraform apply args...]" >&2
  echo "Example: $0 01-networking -auto-approve" >&2
  exit 1
fi

LAYER="$1"
shift
LAYER_DIR="terraform/layers/${LAYER}"

if [[ ! -d "$LAYER_DIR" ]]; then
  echo "Layer folder '$LAYER_DIR' does not exist." >&2
  exit 1
fi

echo "Applying ${LAYER} (terraform -chdir=${LAYER_DIR} apply $*)"
terraform -chdir="$LAYER_DIR" apply "$@"
