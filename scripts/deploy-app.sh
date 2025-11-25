#!/usr/bin/env bash
#
# Deploy an application to an AKS cluster for a given stamp
#
# Usage:
#   ./scripts/deploy-app.sh <stamp-id> <app-name> [namespace] [action]
#
# Arguments:
#   stamp-id   - The stamp ID (e.g., swc-dev, neu-prod)
#   app-name   - The application name (e.g., petclinic)
#   namespace  - Kubernetes namespace (default: default)
#   action     - deploy|uninstall|dry-run (default: deploy)
#
# Examples:
#   ./scripts/deploy-app.sh swc-dev petclinic
#   ./scripts/deploy-app.sh swc-dev petclinic petclinic deploy
#   ./scripts/deploy-app.sh swc-prod petclinic production uninstall
#
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✅${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠️${NC} $1"; }
log_error() { echo -e "${RED}❌${NC} $1"; }

# Parse arguments
STAMP_ID="${1:-}"
APP_NAME="${2:-}"
NAMESPACE="${3:-default}"
ACTION="${4:-deploy}"

if [[ -z "$STAMP_ID" ]] || [[ -z "$APP_NAME" ]]; then
    echo "Usage: $0 <stamp-id> <app-name> [namespace] [action]"
    echo ""
    echo "Arguments:"
    echo "  stamp-id   - The stamp ID (e.g., swc-dev, neu-prod)"
    echo "  app-name   - The application name (e.g., petclinic)"
    echo "  namespace  - Kubernetes namespace (default: default)"
    echo "  action     - deploy|uninstall|dry-run (default: deploy)"
    exit 1
fi

# Derive environment from stamp suffix
case "$STAMP_ID" in
    *-dev)
        ENVIRONMENT="dev"
        ;;
    *-staging)
        ENVIRONMENT="staging"
        ;;
    *-prod)
        ENVIRONMENT="prod"
        ;;
    *)
        log_warn "Unknown environment suffix in stamp '$STAMP_ID', defaulting to 'dev'"
        ENVIRONMENT="dev"
        ;;
esac

# Resource names (matching stamp module naming)
RESOURCE_GROUP="rg-${STAMP_ID}-compute"
AKS_CLUSTER="aks-${STAMP_ID}"
CHART_PATH="apps/${APP_NAME}"
RELEASE_NAME="${APP_NAME}"

log_info "Application Deployment"
echo "  Stamp:       ${STAMP_ID}"
echo "  Environment: ${ENVIRONMENT}"
echo "  App:         ${APP_NAME}"
echo "  Namespace:   ${NAMESPACE}"
echo "  Action:      ${ACTION}"
echo "  AKS:         ${AKS_CLUSTER}"
echo ""

# Check if chart exists
if [[ ! -d "$CHART_PATH" ]]; then
    log_error "Chart not found at ${CHART_PATH}"
    exit 1
fi

# Get AKS credentials
log_info "Getting AKS credentials..."
az aks get-credentials -g "${RESOURCE_GROUP}" -n "${AKS_CLUSTER}" --overwrite-existing

log_success "Connected to ${AKS_CLUSTER}"
kubectl cluster-info
echo ""

# Build Helm args
HELM_ARGS=("-f" "${CHART_PATH}/values.yaml")
ENV_VALUES_FILE="${CHART_PATH}/values-${ENVIRONMENT}.yaml"
if [[ -f "$ENV_VALUES_FILE" ]]; then
    log_info "Using environment values: ${ENV_VALUES_FILE}"
    HELM_ARGS+=("-f" "$ENV_VALUES_FILE")
fi

# Execute action
case "$ACTION" in
    deploy)
        log_info "Deploying ${RELEASE_NAME}..."
        helm upgrade --install "${RELEASE_NAME}" "${CHART_PATH}" \
            --namespace "${NAMESPACE}" \
            --create-namespace \
            "${HELM_ARGS[@]}" \
            --wait \
            --timeout 10m
        
        log_success "Deployment complete!"
        echo ""
        helm status "${RELEASE_NAME}" -n "${NAMESPACE}"
        echo ""
        kubectl get pods -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}"
        ;;
    
    dry-run)
        log_info "Dry run for ${RELEASE_NAME}..."
        helm upgrade --install "${RELEASE_NAME}" "${CHART_PATH}" \
            --namespace "${NAMESPACE}" \
            --create-namespace \
            "${HELM_ARGS[@]}" \
            --dry-run \
            --debug
        ;;
    
    uninstall)
        log_info "Uninstalling ${RELEASE_NAME}..."
        if helm status "${RELEASE_NAME}" -n "${NAMESPACE}" &>/dev/null; then
            helm uninstall "${RELEASE_NAME}" -n "${NAMESPACE}" --wait
            log_success "Release ${RELEASE_NAME} uninstalled"
        else
            log_warn "Release ${RELEASE_NAME} not found in namespace ${NAMESPACE}"
        fi
        ;;
    
    *)
        log_error "Unknown action: ${ACTION}"
        echo "Valid actions: deploy, uninstall, dry-run"
        exit 1
        ;;
esac
