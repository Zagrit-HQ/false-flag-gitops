#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITOPS_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CLUSTER_NAME="${CLUSTER_NAME:-falseflag-demo}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
ARGOCD_INSTALL_URL="${ARGOCD_INSTALL_URL:-https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml}"

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

require docker
require k3d
require kubectl

if ! k3d cluster list "${CLUSTER_NAME}" >/dev/null 2>&1; then
  k3d cluster create --config "${SCRIPT_DIR}/k3d.yaml"
else
  echo "k3d cluster ${CLUSTER_NAME} already exists"
fi

kubectl config use-context "k3d-${CLUSTER_NAME}" >/dev/null

kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n "${ARGOCD_NAMESPACE}" --server-side --force-conflicts -f "${ARGOCD_INSTALL_URL}"

kubectl wait --for=condition=Established crd/applications.argoproj.io --timeout=120s
kubectl -n "${ARGOCD_NAMESPACE}" rollout status deployment/argocd-repo-server --timeout=180s
kubectl -n "${ARGOCD_NAMESPACE}" rollout status deployment/argocd-server --timeout=180s
kubectl -n "${ARGOCD_NAMESPACE}" rollout status statefulset/argocd-application-controller --timeout=180s

kubectl apply -f "${GITOPS_ROOT}/staging/app.yaml"
kubectl apply -f "${GITOPS_ROOT}/production/app.yaml"
kubectl apply -f "${GITOPS_ROOT}/preview/app-of-app.yaml"

cat <<EOF

Demo cluster is ready.

Open Argo CD:
  kubectl -n ${ARGOCD_NAMESPACE} port-forward svc/argocd-server 8080:443

Initial admin password:
  kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo

EOF
