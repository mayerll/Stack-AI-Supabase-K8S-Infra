
#!/bin/bash
set -e
cd terraform
terraform init
terraform apply -auto-approve
# Sync EKS credentials
aws eks update-kubeconfig --name supabase-eks --region us-east-1

