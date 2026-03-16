
#!/bin/bash
# =============================================
# deploy-supabase.sh
# Deploy Supabase to EKS
# Prerequisites: kubectl, helm, terraform
# =============================================

set -euo pipefail

echo "Step 0: Retrieve Terraform outputs for RDS endpoint and S3 bucket"
echo "Loading Terraform outputs..."
cd ./terraform/supabase-infra/
RDS_ENDPOINT=$(terraform output -raw rds_db_endpoint | cut -d':' -f1)
S3_BUCKET=$(terraform output -raw s3_bucket_name)
REGION=$(terraform output -json deployment_info | jq -r '.region')

echo "RDS endpoint: $RDS_ENDPOINT"
echo "S3 bucket: $S3_BUCKET"
echo "Region: $REGION"

cd -

# --- 1. StorageClass ---
echo "Step 1: Apply StorageClass"
kubectl create namespace supabase
kubectl apply -f kubernetes/operators/storage-class.yaml

# --- 2. Ingress NGINX ---
echo "Step 2: Install NGINX Ingress Controller"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# --- 3. External Secrets ---
echo "Step 3: Install ExternalSecrets Operator (with CRDs)"
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace \
  --set installCRDs=true

# Wait for CRDs to be registered
echo "Waiting for ExternalSecrets CRDs..."
kubectl wait --for=condition=established --timeout=60s crd/secretstores.external-secrets.io
kubectl wait --for=condition=established --timeout=60s crd/externalsecrets.external-secrets.io

# Wait for CRDs be Ready
sleep 600 

# --- 4. Apply AWS SecretStore / ExternalSecrets ---
echo "Step 4: Apply SecretStore and ExternalSecrets"
kubectl apply -f kubernetes/operators/aws-secret-store.yaml

# --- 5. Deploy Supabase Helm Chart ---
echo "Step 5: Deploy Supabase"
helm repo add supabase https://supabase-community.github.io/supabase-kubernetes
helm repo update

# Update supabase-values.yaml dynamically with RDS endpoint and S3 bucket
echo $RDS_ENDPOINT
echo $S3_BUCKET
echo $REGION

helm upgrade --install supabase supabase/supabase \
  -n supabase \
  --create-namespace \
  -f ./kubernetes/helm/supabase-values.yaml

# --- 6. HPA ---
echo "Step 6: Apply HAP "
kubectl autoscale deployment supabase-supabase-studio \
  --cpu-percent=80 \
  --min=2 \
  --max=4 \
  -n supabase

# --- 7. NetworkPolicy ---
echo "Step 7: Apply Supabase NetworkPolicy"
kubectl apply -f kubernetes/security/network-policy.yaml

# --- 8. Metrics Server ---
echo "Step 8: Apply Metrics Server"
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server
helm repo update
helm install metrics-server metrics-server/metrics-server --namespace kube-system
# Run the command line listed below to test HPA
kubectl patch deployment supabase-supabase-studio -n supabase --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {"requests": {"cpu": "100m", "memory": "128Mi"}}}]'


# --- 9. Wait for all Supabase pods ---
echo "Step 9: Wait for Supabase pods to be ready..."
kubectl wait --namespace supabase --for=condition=Ready pods --all --timeout=600s

echo "✅ Supabase deployment completed successfully!"
echo "Check pods: kubectl get pods -n supabase"
echo "Check services: kubectl get svc -n supabase"
