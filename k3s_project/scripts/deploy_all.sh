#!/bin/bash
# =============================================================================
# deploy_all.sh — A déployer dans l'ordre
# À exécuter sur kubes-01 depuis ~/deployments
# =============================================================================

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

cd ~/deployments

echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}   DÉPLOIEMENT COMPLET — Projet K3S    ${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

echo -e "\n${YELLOW}[1/6] Création des Secrets...${NC}"
kubectl apply -f mariadb-secret.yaml
kubectl get secrets

echo -e "\n${YELLOW}[2/6] Création des PV/PVC...${NC}"
kubectl apply -f nginx-pv.yaml
kubectl apply -f mariadb-pv.yaml
kubectl get pv && kubectl get pvc

echo -e "\n${YELLOW}[3/6] Création des ConfigMaps...${NC}"
kubectl apply -f nginx-configmap.yaml
kubectl apply -f apache-configmap.yaml
kubectl get configmaps

echo -e "\n${YELLOW}[4/6] Déploiement des applications...${NC}"
kubectl apply -f nginx.yaml
kubectl apply -f apache.yaml
kubectl apply -f mariadb.yaml

echo -e "\n${YELLOW}[5/6] Configuration RBAC...${NC}"
kubectl apply -f rbac.yaml

echo -e "\n${YELLOW}[6/6] Vérification...${NC}"
echo "Attente du démarrage des pods..."
sleep 30
kubectl get pods -o wide
kubectl get services

echo -e "\n${GREEN} Déploiement complet terminé !${NC}"
echo -e "${YELLOW}Accès aux applications :${NC}"
echo "  Nginx   → http://172.16.197.131:30080"
echo "  Apache  → http://172.16.197.131:30081"
echo "  MariaDB → 172.16.197.131:30306"
