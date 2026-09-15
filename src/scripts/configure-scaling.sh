#!/usr/bin/env bash
# Configures an HTTP-concurrency scale rule (scale on real request load,
# not CPU) for the given Container App.
#
# Usage: ./configure-scaling.sh <resource-group> <containerapp-name>
set -euo pipefail

RESOURCE_GROUP="${1:?Usage: $0 <resource-group> <containerapp-name>}"
APP_NAME="${2:?}"

az containerapp update \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --min-replicas 1 --max-replicas 10 \
  --scale-rule-name http-concurrency-rule \
  --scale-rule-type http \
  --scale-rule-http-concurrency 50

echo "Scaling rule set: $APP_NAME scales out past 50 concurrent requests per replica, 1-10 replicas."
