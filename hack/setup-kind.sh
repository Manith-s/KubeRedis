#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${1:-kuberedis}"

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Kind cluster '${CLUSTER_NAME}' already exists."
else
  echo "Creating Kind cluster '${CLUSTER_NAME}'..."
  kind create cluster --name "${CLUSTER_NAME}"
fi

echo ""
echo "Cluster info:"
kubectl cluster-info --context "kind-${CLUSTER_NAME}"
