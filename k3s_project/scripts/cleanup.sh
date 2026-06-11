#!/bin/bash
# =============================================================================
# cleanup.sh — Supprime tous les déploiements du projet
# =============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${RED}  Suppression de tous les déploiements K3S...${NC}"
echo -n "Confirmer ? (oui/non) : "
read confirm

if [ "$confirm" != "oui" ]; then
  echo -e "${YELLOW}Annulé.${NC}"
  exit 0
fi

cd ~/deployments

echo -e "${YELLOW}Suppression des déploiements...${NC}"
kubectl delete -f nginx.yaml 2>/dev/null && echo "nginx supprimé" || echo " nginx déjà absent"
kubectl delete -f apache.yaml 2>/dev/null && echo " apache supprimé" || echo "apache déjà absent"
kubectl delete -f mariadb.yaml 2>/dev/null && echo " mariadb supprimé" || echo "mariadb déjà absent"

echo -e "${YELLOW}Suppression des ConfigMaps...${NC}"
kubectl delete -f nginx-configmap.yaml 2>/dev/null && echo " nginx-config supprimé" || true
kubectl delete -f apache-configmap.yaml 2>/dev/null && echo " apache-config supprimé" || true

echo -e "${YELLOW}Suppression des Secrets...${NC}"
kubectl delete -f mariadb-secret.yaml 2>/dev/null && echo " mariadb-secret supprimé" || true

echo -e "${YELLOW}Suppression du RBAC...${NC}"
kubectl delete -f rbac.yaml 2>/dev/null && echo " rbac supprimé" || true

echo -e "${YELLOW}Suppression des PVC (attente libération)...${NC}"
kubectl delete -f nginx-pv.yaml 2>/dev/null && echo " nginx-pv supprimé" || true
kubectl delete -f mariadb-pv.yaml 2>/dev/null && echo " mariadb-pv supprimé" || true

echo -e "\n${GREEN} Nettoyage terminé !${NC}"
kubectl get pods
kubectl get pv 2>/dev/null
