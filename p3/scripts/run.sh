#!/bin/bash
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'

CDIR="../config/"

#################################################################
            echo -e ${BLUE} "install and run k3d" ${RED} 

curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash 1> /dev/null
k3d cluster delete --all 1> /dev/null
k3d cluster create  --port 8080:443@loadbalancer --port 8888:80@loadbalancer 1> /dev/null # localhost:8080 -> loadbalancer:443

#wait traefik deploy
kubectl -n kube-system wait --for=condition=complete jobs/helm-install-traefik-crd  --timeout=320s 1> /dev/null
kubectl -n kube-system wait --for=condition=complete jobs/helm-install-traefik --timeout=320s 1> /dev/null

echo -e ${GREEN} "traefik deploy successfully" ${RED}



#################################################################
            echo -e ${BLUE} "install argocd" ${RED}

kubectl create namespace argocd 1> /dev/null
kubectl apply -n argocd -f ${CDIR}argocd-install.yaml 1> /dev/null

#wait argcd-server deploy
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=120s 1> /dev/null
kubectl apply -n argocd -f ${CDIR}argocd-ingress.yaml  1> /dev/null

echo -e ${GREEN} "argocd installed successfully" ${RED}

#to get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > super-secret-password
echo -e ${YELLOW} "admin password: "; cat super-secret-password; echo -e
echo -e "ArgoCD URL -> https://127.0.0.1:8080"




#################################################################
            echo -e ${BLUE} "run Guestbook" ${RED}

kubectl create namespace dev 1> /dev/null
kubectl apply -f ${CDIR}playground.yaml -n argocd 1> /dev/null
#wait application deploy
sleep 3
kubectl wait deployment -n dev guestbook-ui --for condition=Available=True --timeout=90s 1> /dev/null

#expose application
kubectl apply -f ${CDIR}ingress-playground.yaml -n dev 1> /dev/null

echo -e ${GREEN} "Guestbook deploy successfully" ${RED}
echo -e ${YELLOW} "Guestbook URL -> http://localhost:8888" ${NC}

