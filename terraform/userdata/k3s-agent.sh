#!/bin/bash
# Bootstrap k3s-agent (worker). Join otomatis ke server memakai token yang sama.
set -eu
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y curl ca-certificates

# Tunggu sampai API server siap (maksimal sekitar 15 menit).
tries=0
until curl -ksf https://${server_ip}:6443/ping >/dev/null 2>&1; do
  tries=$((tries + 1))
  if [ "$tries" -ge 90 ]; then
    echo "k3s-server belum siap" >&2
    exit 1
  fi
  sleep 10
done

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${k3s_version}" K3S_URL="https://${server_ip}:6443" K3S_TOKEN="${k3s_token}" sh -s - agent \
  --node-name ${node_name} \
  --node-ip ${node_ip}

touch /var/lib/cloud/instance/k3s-agent-ready
