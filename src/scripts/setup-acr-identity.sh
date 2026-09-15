#!/usr/bin/env bash
# Connects a Container App to ACR via managed identity instead of the
# registry's admin username/password — no long-lived credential to
# rotate or leak.
#
# Usage: ./setup-acr-identity.sh <resource-group> <containerapp-name> <acr-name>
set -euo pipefail

RESOURCE_GROUP="${1:?Usage: $0 <resource-group> <containerapp-name> <acr-name>}"
APP_NAME="${2:?}"
ACR_NAME="${3:?}"

echo "Assigning a system-assigned identity to $APP_NAME..."
az containerapp identity assign \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --system-assigned

PRINCIPAL_ID=$(az containerapp identity show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --query principalId -o tsv)

ACR_ID=$(az acr show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --query id -o tsv)

echo "Granting AcrPull, scoped to $ACR_NAME only..."
az role assignment create \
  --assignee "$PRINCIPAL_ID" \
  --role AcrPull \
  --scope "$ACR_ID"

echo "Connecting the Container App's registry config to $ACR_NAME..."
az containerapp registry set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --server "${ACR_NAME}.azurecr.io" \
  --identity system

echo "Done. $APP_NAME can now pull from $ACR_NAME with zero stored credentials."
