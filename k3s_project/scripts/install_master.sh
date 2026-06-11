#!/bin/bash
# =============================================================================
# install_master.sh — Installation K3S sur kubes-01 (master)
# À exécuter en root sur kubes-01
# =============================================================================

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${YELLOW}[1/4] Prérequis système...${NC}"
apt update && apt upgrade -y
apt install -y curl wget vim
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
echo -e "${GREEN} Swap désactivé${NC}"
free -h

echo -e "${YELLOW}[2/4] Configuration réseau...${NC}"
cat >> /etc/network/interfaces << 'EOF'

auto ens34
iface ens34 inet static
    address 172.16.227.10
    netmask 255.255.255.0
EOF
ifup ens34 2>/dev/null || true

echo -e "${YELLOW}[3/4] Configuration /etc/hosts...${NC}"
cat >> /etc/hosts << 'EOF'
172.16.227.10   kubes-01.local kubes-01
172.16.227.11   kubes-02.local kubes-02
172.16.227.12   kubes-03.local kubes-03
EOF

echo -e "${YELLOW}[4/4] Installation K3S master...${NC}"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=172.16.227.10 \
  --advertise-address=172.16.227.10 \
  --flannel-iface=ens34" sh -

sleep 10
echo -e "${GREEN} K3S Master installé !${NC}"
kubectl get nodes

echo -e "${YELLOW}Token pour les workers :${NC}"
cat /var/lib/rancher/k3s/server/node-token
