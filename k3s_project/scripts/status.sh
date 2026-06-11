#!/bin/bash
# =============================================================================
# status.sh — État complet du cluster K3S
# =============================================================================

CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}       ÉTAT DU CLUSTER K3S             ${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

echo -e "\n${YELLOW}── NODES ──${NC}"
kubectl get nodes -o wide

echo -e "\n${YELLOW}── PODS ──${NC}"
kubectl get pods -o wide

echo -e "\n${YELLOW}── SERVICES ──${NC}"
kubectl get services

echo -e "\n${YELLOW}── VOLUMES ──${NC}"
kubectl get pv 2>/dev/null
kubectl get pvc 2>/dev/null

echo -e "\n${YELLOW}── CONFIGMAPS ──${NC}"
kubectl get configmaps

echo -e "\n${YELLOW}── SECRETS ──${NC}"
kubectl get secrets

echo -e "\n${YELLOW}── RBAC ──${NC}"
kubectl get serviceaccounts
kubectl get roles
kubectl get rolebindings

echo -e "\n${YELLOW}── HELM ──${NC}"
helm list 2>/dev/null || echo "Helm non installé ou aucune release"

echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
