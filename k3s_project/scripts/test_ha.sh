#!/bin/bash
# =============================================================================
# test_ha.sh — Test de la Haute Disponibilité
# À exécuter sur kubes-01
# =============================================================================

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}       TEST HAUTE DISPONIBILITÉ        ${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

echo -e "\n${YELLOW}[1/4] État initial du cluster :${NC}"
kubectl get nodes
echo ""
kubectl get pods -o wide

echo -e "\n${RED}[2/4] Arrêt de kubes-02...${NC}"
echo "Exécute cette commande sur kubes-02 :"
echo -e "${YELLOW}  sudo systemctl stop k3s-agent${NC}"
echo ""
echo "Appuie sur Entrée une fois kubes-02 arrêté..."
read

echo -e "\n${YELLOW}[3/4] Surveillance du rescheduling (attente ~2-5 min)...${NC}"
echo "Nodes :"
kubectl get nodes
echo ""
echo "Pods en cours de redistribution (Ctrl+C pour arrêter) :"
kubectl get pods -o wide -w &
WPID=$!
sleep 120
kill $WPID 2>/dev/null
wait $WPID 2>/dev/null

echo -e "\n${YELLOW}État après rescheduling :${NC}"
kubectl get nodes
kubectl get pods -o wide

echo -e "\n${GREEN}[4/4] Remise en service de kubes-02...${NC}"
echo "Exécute cette commande sur kubes-02 :"
echo -e "${YELLOW}  sudo systemctl start k3s-agent${NC}"
echo ""
echo "Appuie sur Entrée une fois kubes-02 redémarré..."
read

sleep 15
echo -e "${GREEN} État final :${NC}"
kubectl get nodes
kubectl get pods -o wide
