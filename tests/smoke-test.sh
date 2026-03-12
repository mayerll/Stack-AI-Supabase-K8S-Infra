
#!/bin/bash
set -e

echo "Starting Supabase Smoke Test..."

# 1. Check Pod Health
READY_PODS=$(kubectl get pods -n supabase --no-headers | grep -v Running | wc -l)
if [ "$READY_PODS" -eq 0 ]; then
    echo "All pods are Running."
else
    echo "Some pods are failing." && exit 1
fi

# 2. Test DB Connection
kubectl exec -n supabase supabase-supabase-db-0 -- psql -U postgres -c "SELECT 1;" > /dev/null
echo "Database is reachable."

# 3. Test API Gateway (Kong)
ANON_KEY=$(kubectl get secret supabase-jwt -n supabase -o jsonpath='{.data.anonKey}' | base64 --decode)
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "apikey: $ANON_KEY" http://localhost:8443/rest/v1/)

if [ "$STATUS" -eq 200 ]; then
    echo "API Gateway authenticated successfully."
else
    echo "API Test failed with status $STATUS" && exit 1
fi

echo "Smoke test PASSED!"

