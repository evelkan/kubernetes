#!/bin/bash
# =============================================================================
# install_worker.sh — Rejoindre le cluster K3S (kubes-02 ou kubes-03)
# Usage : bash install_worker.sh <IP_WORKER> <TOKEN>
# Exemple : bash install_worker.sh 172.16.227.11 K10abc123...
# =============================================================================

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

WORKER_IP=$1
TOKEN=$2
MASTER_IP="172.16.227.10"
IFACE="ens34"

if [ -z "$WORKER_IP" ] || [ -z "$TOKEN" ]; then
  echo -e "${RED}Usage : bash install_worker.sh <IP_WORKER> <TOKEN>${NC}"
  echo "Exemple : bash install_worker.sh 172.16.227.11 K10abc123..."
  exit 1
fi

echo -e "${YELLOW}[1/4] Prérequis système...${NC}"
apt update && apt install -y curl wget vim
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo -e "${YELLOW}[2/4] Configuration réseau (${WORKER_IP})...${NC}"
cat >> /etc/network/interfaces << EOF

auto ${IFACE}
iface ${IFACE} inet static
    address ${WORKER_IP}
    netmask 255.255.255.0
EOF
ifup ${IFACE} 2>/dev/null || true

echo -e "${YELLOW}[3/4] Configuration /etc/hosts...${NC}"
cat >> /etc/hosts << 'EOF'
172.16.227.10   kubes-01.local kubes-01
172.16.227.11   kubes-02.local kubes-02
172.16.227.12   kubes-03.local kubes-03
EOF

echo -e "${YELLOW}[4/4] Désinstallation K3S standalone et jonction cluster...${NC}"
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
  /usr/local/bin/k3s-uninstall.sh
fi

curl -sfL https://get.k3s.io | \
  K3S_URL=https://${MASTER_IP}:6443 \
  K3S_TOKEN=${TOKEN} \
  INSTALL_K3S_EXEC="--node-ip=${WORKER_IP} --flannel-iface=${IFACE}" sh -

sleep 5
echo -e "${GREEN} Worker ${WORKER_IP} a rejoint le cluster !${NC}"
systemctl status k3s-agent --no-pager
