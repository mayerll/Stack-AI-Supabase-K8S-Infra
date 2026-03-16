#!/bin/bash

set -e
cd ./terraform/supabase-infra
terraform init
terraform plan -var-file="env/prod.tfvars"
terraform apply -var-file="env/prod.tfvars" --auto-approve
# Sync EKS credentials
aws eks update-kubeconfig --name prod-stackai-supabase-eks --region us-west-2
