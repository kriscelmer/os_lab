#!/usr/bin/env bash
set -euo pipefail
set -x

# This script is for educational purposes only. It is not intended for production use.
# This scripts sets up a Kubernetes worker node, it is executed on a master node.
# The script requires one argument: the IP address of the worker node.

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <worker-ip>"
  exit 1
fi

WORKER_IP="$1"

# Get the join command from the master node
JOIN=$(kubeadm token create --print-join-command --ttl 0)

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/labkey.pem ubuntu@"$WORKER_IP" "sudo $JOIN"