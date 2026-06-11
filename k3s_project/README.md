# Projet Kubernetes K3S — La Plateforme

## Structure du projet

```
k3s_project/
├── deployments/               ← Fichiers YAML Kubernetes
│   ├── nginx.yaml             ← Deployment + Service Nginx (NodePort 30080)
│   ├── apache.yaml            ← Deployment + Service Apache (NodePort 30081)
│   ├── mariadb.yaml           ← Deployment + Service MariaDB (NodePort 30306)
│   ├── nginx-pv.yaml          ← PersistentVolume + PVC Nginx (1Gi)
│   ├── mariadb-pv.yaml        ← PersistentVolume + PVC MariaDB (5Gi)
│   ├── nginx-configmap.yaml   ← ConfigMap page d'accueil Nginx
│   ├── apache-configmap.yaml  ← ConfigMap page d'accueil Apache
│   ├── mariadb-secret.yaml    ← Secret mot de passe MariaDB
│   ├── rbac.yaml              ← ServiceAccount + Role + RoleBinding
│   └── values-nginx.yaml      ← Values Helm pour nginx-custom
│
└── scripts/                   ← Scripts d'automatisation
    ├── install_master.sh      ← Installation K3S master (kubes-01)
    ├── install_worker.sh      ← Rejoindre le cluster (kubes-02/03)
    ├── deploy_all.sh          ← Déploiement complet dans l'ordre
    ├── status.sh              ← État complet du cluster
    ├── test_ha.sh             ← Test de la haute disponibilité
    └── cleanup.sh             ← Suppression de tous les déploiements
```

## Infrastructure

| VM | Hostname | IP Host-Only | IP NAT | Rôle |
|---|---|---|---|---|
| kubes-01 | kubes-01.local | 172.16.227.10 | 172.16.197.131 | Master |
| kubes-02 | kubes-02.local | 172.16.227.11 | 172.16.197.132 | Worker |
| kubes-03 | kubes-03.local | 172.16.227.12 | 172.16.197.133 | Worker |

## Utilisation des scripts

```bash
# Rendre les scripts exécutables
chmod +x scripts/*.sh

# Installation master (sur kubes-01)
sudo bash scripts/install_master.sh

# Installation worker (sur kubes-02)
sudo bash scripts/install_worker.sh 172.16.227.11 <TOKEN>

# Installation worker (sur kubes-03)
sudo bash scripts/install_worker.sh 172.16.227.12 <TOKEN>

# Déploiement complet (sur kubes-01)
sudo bash scripts/deploy_all.sh

# État du cluster
sudo bash scripts/status.sh

# Test HA
sudo bash scripts/test_ha.sh

# Nettoyage
sudo bash scripts/cleanup.sh
```

## Déploiement manuel dans l'ordre

```bash
cd ~/deployments

# 1. Secrets
kubectl apply -f mariadb-secret.yaml

# 2. Volumes
kubectl apply -f nginx-pv.yaml
kubectl apply -f mariadb-pv.yaml

# 3. ConfigMaps
kubectl apply -f nginx-configmap.yaml
kubectl apply -f apache-configmap.yaml

# 4. Applications
kubectl apply -f nginx.yaml
kubectl apply -f apache.yaml
kubectl apply -f mariadb.yaml

# 5. RBAC
kubectl apply -f rbac.yaml
```

## Accès aux applications

| App | URL |
|---|---|
| Nginx | http://172.16.197.131:30080 |
| Apache | http://172.16.197.131:30081 |
| MariaDB | 172.16.197.131:30306 |
