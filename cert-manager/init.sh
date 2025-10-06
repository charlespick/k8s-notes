#!/bin/bash
microk8s enable cert-manager
read -sp "Enter your Cloudflare API token: " CLOUDFLARE_TOKEN
echo
microk8s kubectl create namespace cert-manager
microk8s kubectl -n cert-manager create secret generic cloudflare-api-token \
    --from-literal=api-token="$CLOUDFLARE_TOKEN"

# patch split-dns to use cert-manager
microk8s kubectl -n cert-manager patch deploy cert-manager --type='json' -p='[
 {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--dns01-recursive-nameservers=1.1.1.1:53,8.8.8.8:53"},
 {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--dns01-recursive-nameservers-only=true"}
]'
microk8s kubectl -n cert-manager rollout restart deploy cert-manager
microk8s kubectl -n cert-manager rollout status deploy/cert-manager

echo "Now apply the cluster issuer yaml"
