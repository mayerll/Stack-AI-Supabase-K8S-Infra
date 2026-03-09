
#!/bin/bash
# 1. Install Ingress Controller
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io \
  --namespace ingress-nginx --create-namespace

# 2. Install External Secrets Operator (Requirement for Secret Vaults)
helm upgrade --install external-secrets external-secrets \
  --repo https://charts.external-secrets.io \
  --namespace external-secrets --create-namespace

# 3. Deploy Supabase
helm upgrade --install supabase ./kubernetes/helm -f ./kubernetes/helm/supabase-values.yaml

