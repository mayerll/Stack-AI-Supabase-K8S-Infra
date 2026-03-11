#!/bin/bash
set -e

# 0. Install Storage Class
kubectl apply -f ../kubernetes/operators/storage-class.yaml

# 1. Ingress NGINX
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# 2. External Secrets
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace

# 3. Install/Upgrade Supabase 
helm repo add supabase https://supabase-community.github.io/supabase-kubernetes
helm repo update

helm upgrade --install supabase supabase/supabase \
  -n supabase \
  --create-namespace \
  -f ../kubernetes/helm/supabase-values.yaml

