#!/bin/bash
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'

CDIR="../config/"
ARGO_PORT="1234"




#################################################################
            echo -e ${BLUE} "install and run k3d" ${RED} 

curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash 1> /dev/null
k3d cluster delete 1> /dev/null
k3d cluster create  1> /dev/null #--port 8080:443@loadbalancer #--port 8888:80@loadbalancer 1> /dev/null # localhost:8080 -> loadbalancer:443

#wait traefik deploy
kubectl -n kube-system wait --for=condition=complete jobs/helm-install-traefik-crd  --timeout=320s 1> /dev/null
kubectl -n kube-system wait --for=condition=complete jobs/helm-install-traefik --timeout=320s 1> /dev/null
until [[ $(kubectl -n kube-system get endpoints/traefik -o=jsonpath='{.subsets[*].addresses[*].ip}') ]]; do sleep 5; done

#configure traefik, add a new port for argocd, au passage on recup l'ip du cluster
IP_TRAEFIK="$(kubectl get service traefik -n kube-system -o yaml | tail -n 1 | cut -b 11-)" 1> /dev/null

kubectl get service traefik -n kube-system -o yaml | head -n 39 > traefik.yaml
cat << EOF >> traefik.yaml 
  - name: argocentry
    port: $ARGO_PORT
    protocol: TCP
    targetPort: websecure
EOF
kubectl get service traefik -n kube-system -o yaml | tail -n 9 >> traefik.yaml
kubectl replace -f traefik.yaml -n kube-system 1> /dev/null
rm -rf traefik.yaml

echo -e $GREEN "traefik deploy successfully $YELLOW -> on ip $IP_TRAEFIK" ${RED}





#################################################################
            echo -e ${BLUE} "install argocd" ${RED}

kubectl create namespace argocd 1> /dev/null


#on creer un yaml temporaire avec l'ip et port choisis

sed "s/__IP_TRAEFIK__/$IP_TRAEFIK/g"    ${CDIR}argocd-install.yaml.conf > ${CDIR}argocd-install.yaml
sed -i "s/__ARGO_PORT__/$ARGO_PORT/g"   ${CDIR}argocd-install.yaml
kubectl apply -n argocd -f              ${CDIR}argocd-install.yaml 1> /dev/null

#wait argcd-server deploy
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=120s 1> /dev/null


#et on fait la meme chose pour argo ingress
sed "s/__IP_TRAEFIK__/$IP_TRAEFIK/g"    ${CDIR}argocd-ingress.yaml.conf > ${CDIR}argocd-ingress.yaml
sed -i "s/__ARGO_PORT__/$ARGO_PORT/g"   ${CDIR}argocd-ingress.yaml
kubectl apply -n argocd -f              ${CDIR}argocd-ingress.yaml 1> /dev/null 


rm -rf ${CDIR}argocd-ingress.yaml 
rm -rf ${CDIR}argocd-install.yaml 


echo -e ${GREEN} "argocd installed successfully" ${RED}

#to get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > super-secret-password
echo -e ${YELLOW} "admin password: " "$(cat super-secret-password)";
echo -e " ArgoCD URL -> https://$IP_TRAEFIK:$ARGO_PORT"







################################################################
            echo -e ${BLUE} "run Guestbook" ${RED}

kubectl create namespace dev 1> /dev/null
kubectl apply -f ${CDIR}app-ui.yaml -n argocd 1> /dev/null
#wait application deploy
sleep 3
kubectl wait deployment -n dev app-ui --for condition=Available=True --timeout=90s 1> /dev/null

#expose application
kubectl apply -f ${CDIR}app-ui-ingress.yaml -n dev 1> /dev/null

echo -e ${GREEN} "Guestbook deploy successfully" ${RED}
echo -e ${YELLOW} "Guestbook URL -> http://localhost:8888" ${NC}

