#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <layer-folder> [terraform destroy args...]" >&2
  echo "Example: $0 02-shared -auto-approve" >&2
  exit 1
fi

LAYER="$1"
shift
LAYER_DIR="terraform/layers/${LAYER}"

if [[ ! -d "$LAYER_DIR" ]]; then
  echo "Layer folder '$LAYER_DIR' does not exist." >&2
  exit 1
fi

echo "Destroying ${LAYER} (terraform -chdir=${LAYER_DIR} destroy $*)"
terraform -chdir="$LAYER_DIR" destroy "$@"
