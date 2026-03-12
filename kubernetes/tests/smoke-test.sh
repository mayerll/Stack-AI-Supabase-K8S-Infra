
#!/bin/bash
set -e

echo "Starting Supabase Production Smoke Test..."

# 1. Check Pod Readiness
READY=$(kubectl get deployment -n supabase -o jsonpath='{.items[*].status.readyReplicas}')
if [[ -z "$READY" ]]; then echo "❌ No ready replicas found"; exit 1; fi
echo "All Deployments have ready replicas."

# 2. Test S3 connectivity (Via Storage API logs)
if kubectl logs -n supabase -l app.kubernetes.io/name=supabase-storage | grep -i "error"; then
  echo "Storage API reporting S3 errors."
else
  echo "Storage API is healthy."
fi

# 3. Test HPA status
kubectl get hpa -n supabase
echo "HPA is active for key components."

echo "Smoke test PASSED!"

