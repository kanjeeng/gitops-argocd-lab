#!/bin/bash
# Bootstrap k3s-server (control-plane).
# Dijalankan otomatis oleh cloud-init saat instance pertama kali menyala.
set -eu
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y curl ca-certificates

# Instal k3s server memakai skrip resmi.
# - Traefik bawaan dimatikan: Traefik dipasang lewat ArgoCD (GitOps).
# - ServiceLB (klipper-lb) tetap aktif untuk membuka port 80/443 pada node.
# - tls-san memastikan sertifikat API valid untuk Elastic IP dan nama api.<domain>.
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${k3s_version}" K3S_TOKEN="${k3s_token}" sh -s - server \
  --node-name k3s-server \
  --node-ip 10.4.1.10 \
  --advertise-address 10.4.1.10 \
  --tls-san ${eip} \
  --tls-san api.${base_domain} \
  --disable traefik \
  --write-kubeconfig-mode 644

# Tunggu API siap, lalu tandai selesai.
until k3s kubectl get nodes >/dev/null 2>&1; do
  sleep 5
done
touch /var/lib/cloud/instance/k3s-server-ready
