# StackAI Supabase Infrastructure

A professional Infrastructure as Code (IaC) project using Terraform to deploy a highly available Supabase-style stack on AWS (us-west-2).

## 1. Pre-deployment Checks

Ensure your local environment is authenticated with the correct AWS Account (905921696455).

```bash
# Check current AWS credentials
env | grep AWS

# Verify identity
aws sts get-caller-identity

# Expected Output:
# {
#     "UserId": "905921696455",
#     "Account": "905921696455",
#     "Arn": "arn:aws:iam::905921696455:root"
# }

# If identity is missing or incorrect, run:
aws configure
```

## 2. Bootstrap Remote Backend

Terraform requires an S3 bucket and a DynamoDB table to manage state files and state locking. These must be created manually before running terraform init.

### Create S3 Bucket (State Storage)

```bash
# 1. Create the S3 Bucket
aws s3api create-bucket \
    --bucket stackai-supabase-terraform-state \
    --region us-west-2 \
    --create-bucket-configuration LocationConstraint=us-west-2

# 2. Enable Versioning (Required for state recovery)
aws s3api put-bucket-versioning \
    --bucket stackai-supabase-terraform-state \
    --versioning-configuration Status=Enabled

# 3. Enable Default Encryption
aws s3api put-bucket-encryption \
    --bucket stackai-supabase-terraform-state \
    --server-side-encryption-configuration '{
        "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
    }'
```

### Create DynamoDB Table (State Locking)

```bash

# Create the table with the required Partition Key: LockID
aws dynamodb create-table \
    --table-name supabase-terraform-state-lock \
    --region us-west-2 \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

## 3. Environment Management (IaaS)

We use Terraform Workspaces to isolate Dev, Staging, and Prod environments.

### Initialize and Switch Workspace

```bash
# Initialize backend and download modules
terraform init

# Create and switch to the 'prod' workspace
terraform workspace new prod

# Verify current workspace
terraform workspace show  # Should display 'prod'
```
### Deploying Infrastructure

```bash
# Execute deployment using environment-specific variables, for example:
terraform apply -var-file="env/prod.tfvars"
```
<img width="1029" height="252" alt="bash-5 1# terraform workspace new prod" src="https://github.com/user-attachments/assets/6b10a769-6402-4b9f-9e5c-b178af9a76c3" />

## 4. Troubleshooting

### Handling State Lock Errors

If a deployment is interrupted, you may encounter a ConditionalCheckFailedException. You must force-unlock the state using the ID provided in the error message.

```bash
# Example Error: Error acquiring the state lock
# Lock Info ID: ff9f9069-c27b-ea13-d2a1-7f8feae274fb

# Resolution: Force unlock
terraform force-unlock ff9f9069-c27b-ea13-d2a1-7f8feae274fb
```

### EKS Version Upgrades

AWS EKS does not support skipping minor versions (e.g., 1.28 directly to 1.30).
Correct Path: Upgrade to 1.29 first, apply, then upgrade to 1.30.

## 5. CI/CD Pipeline (GitHub Actions)

The project includes a GitHub Action workflow for automated or manual deployments.

### Configuration
Add AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to GitHub Secrets.
Add TF_VAR_DB_PASSWORD to GitHub Secrets to avoid plain-text passwords in the repo.

### Manual Trigger Logic
The workflow uses workflow_dispatch to allow manual selection of the target environment.

```bash
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target Environment'
        required: true
        default: 'dev'
        type: choice
        options:
        - dev
        - staging
        - prod
```
### Project Structure

```bash
.
├── 00-providers.tf    # S3 Backend & AWS Provider
├── 01-variables.tf    # Input variables with descriptions
├── 02-locals.tf       # Dynamic naming logic
├── 03-network.tf      # VPC & NAT Gateways
├── 04-storage.tf      # S3 Buckets & Encryption
├── 05-iam.tf          # EKS Access Entries & Roles
├── 06-database.tf     # RDS PostgreSQL (Multi-AZ)
├── 07-eks.tf          # Kubernetes Cluster & Add-ons
├── 08-outputs.tf      # Endpoints and connection strings
├── Makefile           # CLI Shortcuts
└── env/               # Environment variable files
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```
