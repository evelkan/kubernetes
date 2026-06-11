#!/bin/bash
# =============================================================================
# SCRIPTS UTILES — Projet Kubernetes K3S
# La Plateforme — Formation DevOps
# =============================================================================
# Usage : bash scripts_k3s.sh [COMMANDE]
# =============================================================================

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ------------------------------------------------------------------------------
# MENU PRINCIPAL
# ------------------------------------------------------------------------------
menu() {
  echo -e "${BLUE}"
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║        SCRIPTS K3S — La Plateforme DevOps            ║"
  echo "╠══════════════════════════════════════════════════════╣"
  echo "║  1. setup_vm          — Prérequis système (swap...)  ║"
  echo "║  2. install_master    — Installer K3S master         ║"
  echo "║  3. install_worker    — Rejoindre le cluster         ║"
  echo "║  4. deploy_apps       — Déployer Nginx/Apache/MariaDB║"
  echo "║  5. deploy_ha         — Redéployer en HA (replicas:3)║"
  echo "║  6. deploy_volumes    — Créer PV/PVC                 ║"
  echo "║  7. deploy_configmaps — Créer les ConfigMaps         ║"
  echo "║  8. deploy_secrets    — Créer les Secrets            ║"
  echo "║  9. deploy_rbac       — Créer les règles RBAC        ║"
  echo "║ 10. test_ha           — Tester la HA                 ║"
  echo "║ 11. status            — État complet du cluster      ║"
  echo "║ 12. cleanup           — Supprimer tous les déploiem. ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo -n "Choix : "
  read choice
  case $choice in
    1) setup_vm ;;
    2) install_master ;;
    3) install_worker ;;
    4) deploy_apps ;;
    5) deploy_ha ;;
    6) deploy_volumes ;;
    7) deploy_configmaps ;;
    8) deploy_secrets ;;
    9) deploy_rbac ;;
    10) test_ha ;;
    11) status ;;
    12) cleanup ;;
    *) echo -e "${RED}Choix invalide${NC}" ;;
  esac
}

# ------------------------------------------------------------------------------
# JOB 01 — PRÉREQUIS SYSTÈME
# À exécuter sur les 3 VMs avant l'installation de K3S
# ------------------------------------------------------------------------------
setup_vm() {
  echo -e "${CYAN}[JOB 01] Configuration des prérequis système...${NC}"

  # Mise à jour du système
  echo -e "${YELLOW}→ Mise à jour des paquets...${NC}"
  apt update && apt upgrade -y

  # Installation des outils
  echo -e "${YELLOW}→ Installation des outils...${NC}"
  apt install -y curl wget vim

  # Désactivation du swap (obligatoire pour K3S)
  echo -e "${YELLOW}→ Désactivation du swap...${NC}"
  swapoff -a
  sed -i '/ swap / s/^/#/' /etc/fstab

  # Vérification
  echo -e "${GREEN}✅ Swap désactivé :${NC}"
  free -h

  echo -e "${GREEN}[JOB 01] Prérequis configurés !${NC}"
}

# ------------------------------------------------------------------------------
# JOB 01 — INSTALLATION K3S MASTER (kubes-01)
# ------------------------------------------------------------------------------
install_master() {
  echo -e "${CYAN}[JOB 01] Installation K3S — Master (kubes-01)...${NC}"

  NODE_IP="172.16.227.10"
  IFACE="ens34"

  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=${NODE_IP} \
    --advertise-address=${NODE_IP} \
    --flannel-iface=${IFACE}" sh -

  echo -e "${YELLOW}→ Attente du démarrage K3S...${NC}"
  sleep 10

  echo -e "${GREEN}✅ K3S Master installé !${NC}"
  echo -e "${YELLOW}→ Token du master :${NC}"
  cat /var/lib/rancher/k3s/server/node-token

  echo -e "${YELLOW}→ État des nodes :${NC}"
  kubectl get nodes
}

# ------------------------------------------------------------------------------
# JOB 03 — REJOINDRE LE CLUSTER (kubes-02 ou kubes-03)
# Usage : bash scripts_k3s.sh install_worker
# ------------------------------------------------------------------------------
install_worker() {
  echo -e "${CYAN}[JOB 03] Rejoindre le cluster K3S...${NC}"

  echo -n "IP de ce worker (ex: 172.16.227.11) : "
  read WORKER_IP

  echo -n "Token du master : "
  read TOKEN

  MASTER_IP="172.16.227.10"
  IFACE="ens34"

  # Désinstaller K3S standalone si présent
  if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    echo -e "${YELLOW}→ Désinstallation K3S standalone...${NC}"
    /usr/local/bin/k3s-uninstall.sh
  fi

  # Rejoindre le cluster
  curl -sfL https://get.k3s.io | \
    K3S_URL=https://${MASTER_IP}:6443 \
    K3S_TOKEN=${TOKEN} \
    INSTALL_K3S_EXEC="--node-ip=${WORKER_IP} --flannel-iface=${IFACE}" sh -

  echo -e "${GREEN}✅ Worker rejoint le cluster !${NC}"
  systemctl status k3s-agent --no-pager
}

# ------------------------------------------------------------------------------
# JOB 02 — DÉPLOIEMENT DES APPLICATIONS (replicas: 1)
# ------------------------------------------------------------------------------
deploy_apps() {
  echo -e "${CYAN}[JOB 02] Déploiement des applications...${NC}"

  mkdir -p ~/deployments && cd ~/deployments

  # --- Nginx ---
  cat > nginx.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    nodePort: 30080
EOF

  # --- Apache ---
  cat > apache.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      containers:
      - name: apache
        image: httpd:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: apache-svc
spec:
  type: NodePort
  selector:
    app: apache
  ports:
  - port: 80
    nodePort: 30081
EOF

  # --- MariaDB ---
  cat > mariadb.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
      - name: mariadb
        image: mariadb:latest
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "rootpassword"
        ports:
        - containerPort: 3306
---
apiVersion: v1
kind: Service
metadata:
  name: mariadb-svc
spec:
  type: NodePort
  selector:
    app: mariadb
  ports:
  - port: 3306
    nodePort: 30306
EOF

  kubectl apply -f nginx.yaml
  kubectl apply -f apache.yaml
  kubectl apply -f mariadb.yaml

  echo -e "${YELLOW}→ Attente du démarrage des pods...${NC}"
  kubectl get pods -w &
  sleep 30
  kill %1 2>/dev/null

  echo -e "${GREEN}✅ Applications déployées !${NC}"
  kubectl get pods
  kubectl get services
}

# ------------------------------------------------------------------------------
# JOB 04 — REDÉPLOIEMENT EN HAUTE DISPONIBILITÉ (replicas: 3)
# ------------------------------------------------------------------------------
deploy_ha() {
  echo -e "${CYAN}[JOB 04] Redéploiement en HA (replicas: 3)...${NC}"

  cd ~/deployments

  # Supprimer les déploiements existants
  echo -e "${YELLOW}→ Suppression des déploiements existants...${NC}"
  kubectl delete -f nginx.yaml 2>/dev/null
  kubectl delete -f apache.yaml 2>/dev/null
  kubectl delete -f mariadb.yaml 2>/dev/null

  # Mettre à jour replicas à 3
  sed -i 's/replicas: 1/replicas: 3/g' nginx.yaml apache.yaml mariadb.yaml

  # Redéployer
  kubectl apply -f nginx.yaml
  kubectl apply -f apache.yaml
  kubectl apply -f mariadb.yaml

  echo -e "${YELLOW}→ Vérification de la répartition sur les nodes...${NC}"
  sleep 20
  kubectl get pods -o wide

  echo -e "${GREEN}✅ HA activée — 9 pods déployés sur 3 nodes !${NC}"
}

# ------------------------------------------------------------------------------
# JOB 05 — VOLUMES PERSISTANTS (PV/PVC)
# ------------------------------------------------------------------------------
deploy_volumes() {
  echo -e "${CYAN}[JOB 05] Création des volumes persistants...${NC}"

  cd ~/deployments

  # --- PV/PVC Nginx ---
  cat > nginx-pv.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nginx-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  hostPath:
    path: /data/nginx
  persistentVolumeReclaimPolicy: Retain
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 1Gi
EOF

  # --- PV/PVC MariaDB ---
  cat > mariadb-pv.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mariadb-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  hostPath:
    path: /data/mariadb
  persistentVolumeReclaimPolicy: Retain
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 5Gi
EOF

  # Mettre à jour nginx.yaml avec volumeMounts
  cat > nginx.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-data
          mountPath: /usr/share/nginx/html
      volumes:
      - name: nginx-data
        persistentVolumeClaim:
          claimName: nginx-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    nodePort: 30080
EOF

  # Mettre à jour mariadb.yaml avec volumeMounts
  cat > mariadb.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
      - name: mariadb
        image: mariadb:latest
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mariadb-secret
              key: MYSQL_ROOT_PASSWORD
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mariadb-data
          mountPath: /var/lib/mysql
      volumes:
      - name: mariadb-data
        persistentVolumeClaim:
          claimName: mariadb-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mariadb-svc
spec:
  type: NodePort
  selector:
    app: mariadb
  ports:
  - port: 3306
    nodePort: 30306
EOF

  # Appliquer PV/PVC
  kubectl apply -f nginx-pv.yaml
  kubectl apply -f mariadb-pv.yaml

  echo -e "${YELLOW}→ Vérification des PV/PVC...${NC}"
  kubectl get pv
  kubectl get pvc

  echo -e "${GREEN}✅ Volumes persistants créés !${NC}"
}

# ------------------------------------------------------------------------------
# JOB 06 — CONFIGMAPS
# ------------------------------------------------------------------------------
deploy_configmaps() {
  echo -e "${CYAN}[JOB 06] Création des ConfigMaps...${NC}"

  cd ~/deployments

  # --- ConfigMap Nginx ---
  cat > nginx-configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>Nginx K3S</title></head>
    <body>
      <h1>Bienvenue sur Nginx</h1>
      <p>Deploye sur le cluster K3S - La Plateforme</p>
    </body>
    </html>
EOF

  # --- ConfigMap Apache ---
  cat > apache-configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: apache-config
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>Apache K3S</title></head>
    <body>
      <h1>Bienvenue sur Apache</h1>
      <p>Deploye sur le cluster K3S - La Plateforme</p>
    </body>
    </html>
EOF

  # Mettre à jour nginx.yaml avec ConfigMap
  cat > nginx.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-data
          mountPath: /usr/share/nginx/html
        - name: nginx-config
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
      volumes:
      - name: nginx-data
        persistentVolumeClaim:
          claimName: nginx-pvc
      - name: nginx-config
        configMap:
          name: nginx-config
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    nodePort: 30080
EOF

  # Mettre à jour apache.yaml avec ConfigMap
  cat > apache.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache
spec:
  replicas: 3
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      containers:
      - name: apache
        image: httpd:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: apache-config
          mountPath: /usr/local/apache2/htdocs/index.html
          subPath: index.html
      volumes:
      - name: apache-config
        configMap:
          name: apache-config
---
apiVersion: v1
kind: Service
metadata:
  name: apache-svc
spec:
  type: NodePort
  selector:
    app: apache
  ports:
  - port: 80
    nodePort: 30081
EOF

  kubectl apply -f nginx-configmap.yaml
  kubectl apply -f apache-configmap.yaml
  kubectl apply -f nginx.yaml
  kubectl apply -f apache.yaml

  echo -e "${GREEN}✅ ConfigMaps créés et appliqués !${NC}"
  kubectl get configmaps
}

# ------------------------------------------------------------------------------
# JOB 07 — SECRETS
# ------------------------------------------------------------------------------
deploy_secrets() {
  echo -e "${CYAN}[JOB 07] Création des Secrets...${NC}"

  cd ~/deployments

  echo -n "Mot de passe MariaDB root (défaut: rootpassword) : "
  read PASSWORD
  PASSWORD=${PASSWORD:-rootpassword}

  # Encoder en base64
  B64_PASSWORD=$(echo -n "${PASSWORD}" | base64)
  echo -e "${YELLOW}→ Mot de passe encodé en base64 : ${B64_PASSWORD}${NC}"

  cat > mariadb-secret.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: mariadb-secret
type: Opaque
data:
  MYSQL_ROOT_PASSWORD: ${B64_PASSWORD}
EOF

  kubectl apply -f mariadb-secret.yaml
  kubectl apply -f mariadb.yaml

  echo -e "${GREEN}✅ Secret créé !${NC}"
  kubectl get secrets
  kubectl describe secret mariadb-secret
}

# ------------------------------------------------------------------------------
# JOB 08 — RBAC
# ------------------------------------------------------------------------------
deploy_rbac() {
  echo -e "${CYAN}[JOB 08] Création des règles RBAC...${NC}"

  cd ~/deployments

  cat > rbac.yaml << 'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF

  kubectl apply -f rbac.yaml

  echo -e "${YELLOW}→ Test des permissions...${NC}"
  echo -n "list pods   : "
  kubectl auth can-i list pods --as=system:serviceaccount:default:app-sa
  echo -n "delete pods : "
  kubectl auth can-i delete pods --as=system:serviceaccount:default:app-sa
  echo -n "list services : "
  kubectl auth can-i list services --as=system:serviceaccount:default:app-sa

  echo -e "${GREEN}✅ RBAC configuré !${NC}"
  kubectl get roles
  kubectl get rolebindings
}

# ------------------------------------------------------------------------------
# JOB 04 — TEST HAUTE DISPONIBILITÉ
# ------------------------------------------------------------------------------
test_ha() {
  echo -e "${CYAN}[JOB 04] Test de Haute Disponibilité...${NC}"

  echo -e "${YELLOW}→ État initial du cluster :${NC}"
  kubectl get nodes
  kubectl get pods -o wide

  echo -e "${RED}→ Arrêt de kubes-02 (à exécuter sur kubes-02) :${NC}"
  echo "   ssh laplateforme@172.16.197.132 'sudo systemctl stop k3s-agent'"
  echo ""
  echo -e "${YELLOW}Attente du rescheduling (2-5 minutes)...${NC}"
  echo "Appuyer sur Entrée quand kubes-02 est arrêté..."
  read

  echo -e "${YELLOW}→ Surveillance des pods (Ctrl+C pour arrêter) :${NC}"
  kubectl get pods -o wide -w &
  WATCH_PID=$!

  sleep 60
  kill $WATCH_PID 2>/dev/null

  echo -e "${YELLOW}→ État après rescheduling :${NC}"
  kubectl get nodes
  kubectl get pods -o wide

  echo -e "${GREEN}→ Redémarrage de kubes-02 :${NC}"
  echo "   ssh laplateforme@172.16.197.132 'sudo systemctl start k3s-agent'"
}

# ------------------------------------------------------------------------------
# ÉTAT COMPLET DU CLUSTER
# ------------------------------------------------------------------------------
status() {
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
  helm list 2>/dev/null || echo "Helm non installé"

  echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
}

# ------------------------------------------------------------------------------
# NETTOYAGE COMPLET
# ------------------------------------------------------------------------------
cleanup() {
  echo -e "${RED}⚠️  Suppression de tous les déploiements...${NC}"
  echo -n "Confirmer ? (oui/non) : "
  read confirm

  if [ "$confirm" = "oui" ]; then
    cd ~/deployments

    kubectl delete -f nginx.yaml 2>/dev/null
    kubectl delete -f apache.yaml 2>/dev/null
    kubectl delete -f mariadb.yaml 2>/dev/null
    kubectl delete -f nginx-pv.yaml 2>/dev/null
    kubectl delete -f mariadb-pv.yaml 2>/dev/null
    kubectl delete -f nginx-configmap.yaml 2>/dev/null
    kubectl delete -f apache-configmap.yaml 2>/dev/null
    kubectl delete -f mariadb-secret.yaml 2>/dev/null
    kubectl delete -f rbac.yaml 2>/dev/null

    echo -e "${GREEN}✅ Nettoyage terminé !${NC}"
    kubectl get pods
  else
    echo -e "${YELLOW}Annulé.${NC}"
  fi
}

# ------------------------------------------------------------------------------
# POINT D'ENTRÉE
# ------------------------------------------------------------------------------
if [ "$1" != "" ]; then
  $1
else
  menu
fi
