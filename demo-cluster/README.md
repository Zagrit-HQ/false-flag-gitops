# Demo Cluster

This directory contains a local K3s-on-Docker cluster for demonstrating the
FalseFlag GitOps flow with Argo CD.

The setup uses k3d to create a local K3s cluster, installs Argo CD into the
`argocd` namespace, then registers the staging, production, and preview
App-of-Apps manifests from this GitOps repository.

## Prerequisites

- Docker
- k3d
- kubectl

## Start

```sh
./demo-cluster/bootstrap.sh
```

The bootstrap script:

- Creates a `falseflag-demo` k3d cluster.
- Installs Argo CD.
- Applies the staging Application.
- Applies the production Application.
- Applies the preview App-of-Apps Application.

## Open Argo CD

```sh
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

The UI is available at <https://localhost:8080>.

Get the initial admin password:

```sh
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

## Stop

```sh
./demo-cluster/destroy.sh
```

This deletes the whole k3d cluster.
