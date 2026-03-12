#!/bin/bash

set -e
cd ./terraform
terraform init
terraform plan 
terraform apply 
# Sync EKS credentials
aws eks update-kubeconfig --name supabase-eks --region us-west-2

