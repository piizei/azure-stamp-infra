#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <layer-folder> (e.g. 01-networking)" >&2
  exit 1
fi

LAYER="$1"
LAYER_DIR="terraform/layers/${LAYER}"
BOOTSTRAP_DIR="terraform/layers/00-bootstrap"

case "$LAYER" in
  01-networking)
    TFSTATE_KEY="networking.tfstate"
    ;;
  02-shared)
    TFSTATE_KEY="shared.tfstate"
    ;;
  03-database)
    TFSTATE_KEY="database.tfstate"
    ;;
  04-compute)
    TFSTATE_KEY="compute.tfstate"
    ;;
  00-bootstrap)
    echo "Layer 00-bootstrap manages its own local state; run terraform init/apply directly inside that folder." >&2
    exit 1
    ;;
  *)
    TFSTATE_KEY="${LAYER}.tfstate"
    ;;
esac

if [[ ! -d "$LAYER_DIR" ]]; then
  echo "Layer folder '$LAYER_DIR' does not exist." >&2
  exit 1
fi

# Ensure the bootstrap layer has been applied so the outputs are available.
for output_name in resource_group_name storage_account_name container_name; do
  if ! terraform -chdir="$BOOTSTRAP_DIR" output -raw "$output_name" >/dev/null 2>&1; then
    echo "Unable to read '$output_name' from $BOOTSTRAP_DIR. Run terraform init/apply there first." >&2
    exit 1
  fi
done

TFSTATE_RG=$(terraform -chdir="$BOOTSTRAP_DIR" output -raw resource_group_name)
TFSTATE_SA=$(terraform -chdir="$BOOTSTRAP_DIR" output -raw storage_account_name)
TFSTATE_CONTAINER=$(terraform -chdir="$BOOTSTRAP_DIR" output -raw container_name)

echo "Initializing ${LAYER} with backend settings from 00-bootstrap..."
terraform -chdir="$LAYER_DIR" init \
  -backend-config="resource_group_name=${TFSTATE_RG}" \
  -backend-config="storage_account_name=${TFSTATE_SA}" \
  -backend-config="container_name=${TFSTATE_CONTAINER}" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="key=${TFSTATE_KEY}"
