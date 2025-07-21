#!/usr/bin/env bash
set -euo pipefail
set -x

# This script is for educational purposes only. It is not intended for production use.
# This scripts sets up a Kubernetes master node on an Instance created with Image prepared by prep-k8s-image.sh.

export DEBIAN_FRONTEND=noninteractive

# Initialize the Kubernetes cluster
sudo kubeadm init --pod-network-cidr 10.244.0.0/16
# Configure kubectl for the current user
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

VER=v3.30.2 # Calico version
# Install Calico CNI plugin

### 1 CRDs (use *server‑side* to avoid 262 kB annotation limit)
kubectl apply --server-side -f https://raw.githubusercontent.com/projectcalico/calico/${VER}/manifests/operator-crds.yaml

### 2 Operator
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/${VER}/manifests/tigera-operator.yaml

### 3 Minimal Installation object (matches kubeadm’s pod‑CIDR)
cat <<EOF | kubectl apply -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - cidr: 10.244.0.0/16
      encapsulation: VXLAN
EOF
