#!/usr/bin/env bash
# Rolls back to the previous revision by shifting 100% of traffic to it
# — no redeploy, no rebuild, just a traffic-weight change. Requires the
# app to be in multiple-revision mode.
#
# Usage: ./rollback.sh <resource-group> <containerapp-name>
set -euo pipefail

RESOURCE_GROUP="${1:?Usage: $0 <resource-group> <containerapp-name>}"
APP_NAME="${2:?}"

echo "Ensuring multiple-revision mode..."
az containerapp revision set-mode \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --mode Multiple

echo "Current revisions:"
az containerapp revision list \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --query "[].{Name:name, Active:properties.active, Traffic:properties.trafficWeight, Created:properties.createdTime}" \
  -o table

echo
read -r -p "Revision name to roll back to (100% traffic): " TARGET_REVISION
read -r -p "Revision name currently receiving traffic to remove (0%): " BROKEN_REVISION

az containerapp ingress traffic set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --revision-weight "${TARGET_REVISION}=100" "${BROKEN_REVISION}=0"

echo "Traffic rolled back to $TARGET_REVISION."
