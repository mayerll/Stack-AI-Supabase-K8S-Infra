# StackAI Supabase Infrastructure

A professional Infrastructure as Code (IaC) project using Terraform to deploy a highly available Supabase-style stack on AWS (us-west-2).


## 0. Deployment Environment

This project follows a branch-driven deployment strategy. Pushing code to the following branches triggers an automatic deployment to their respective environments:


| Branch | Environment | Purpose |
| :--- | :--- | :--- |
| `main` | **Production** | Live environment for end-users. |
| `staging` | **Staging** | Pre-production testing and final QA. |
| `qa` | **QA** | Quality Assurance and integration testing. |
| `dev` | **Development** | Sandbox for feature testing and dev syncing. |



## 1. Pre-deployment Checks

Ensure your local environment is authenticated with the correct AWS Account (905921696455).

```bash
# Check current AWS credentials

$ env | grep AWS
```

# Verify identity

```bash
$ aws sts get-caller-identity
```

####  Expected Output:

```bash
$ aws sts get-caller-identity
 {
     "UserId": "905921696455",
     "Account": "905921696455",
     "Arn": "arn:aws:iam::905921696455:root"
 }
```

####  If identity is missing or incorrect, run:
```bash
$ aws configure
```

# Create the EKS Admin User

```bash
# The Terraform configuration (05-iam.tf) expects this user to exist 
# to grant ClusterAdmin permissions via Access Entries.

$ aws iam create-user --user-name eks-admin
```

#### Why we create this user manually:

In a professional production environment, Identity (IAM Users) and Infrastructure (EKS/RDS) are managed in separate layers.

Decoupling: Prevents the admin user from being accidentally deleted if the EKS cluster is destroyed.
Consistency: Ensures the same management identity can be used across dev, staging, and prod without naming conflicts inside Terraform state.



## 2. Bootstrap Remote Backend

Terraform requires an S3 bucket and a DynamoDB table to manage state files and state locking. These must be created manually before running terraform init.

### Create S3 Bucket (State Storage)


####  1. Create the S3 Bucket

```bash

$ aws s3api create-bucket \
    --bucket stackai-supabase-terraform-state \
    --region us-west-2 \
    --create-bucket-configuration LocationConstraint=us-west-2
```

####  2. Enable Versioning (Required for state recovery)

```bash

$ aws s3api put-bucket-versioning \
    --bucket stackai-supabase-terraform-state \
    --versioning-configuration Status=Enabled

```
####  3. Enable Default Encryption

```bash
$ aws s3api put-bucket-encryption \
    --bucket stackai-supabase-terraform-state \
    --server-side-encryption-configuration '{
        "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
    }'
```

### Create DynamoDB Table (State Locking)

```bash
# Create the table with the required Partition Key: LockID

$ aws dynamodb create-table \
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
$ terraform init

# Create and switch to the 'prod' workspace
$ terraform workspace new prod

# Verify current workspace
$ terraform workspace show  # Should display 'prod'
```

### Deploying Infrastructure

```bash

# Execute deployment using environment-specific variables, for example:
$ terraform apply -var-file="env/prod.tfvars"
```
<img width="822" height="189" alt="bash-5 1# terraform workspace new prod" src="https://github.com/user-attachments/assets/6b10a769-6402-4b9f-9e5c-b178af9a76c3" />


## 4. Output and Connectivity

Upon a successful `apply`, Terraform will output the following details. You can use these to verify the resources or connect to the EKS cluster and RDS database.

### Example Production Output

```hcl
deployment_info = {
  "prefix"    = "prod-stackai-supabase"
  "region"    = "us-west-2"
  "workspace" = "prod"
}
eks_cluster_name       = "prod-stackai-supabase-eks"
eks_cluster_endpoint   = "https://7484600AD96A0363244A4FEE39CDA4B2.gr7.us-west-2.eks.amazonaws.com"
kubectl_config_command = "aws eks update-kubeconfig --region us-west-2 --name prod-stackai-supabase-eks"
rds_db_endpoint        = "prod-stackai-supabase-db.c3cqiieqif31.us-west-2.rds.amazonaws.com:5432"
rds_db_name            = "postgres"
s3_bucket_name         = "stackai-supabase-storage-prod-us-west-2"
vpc_id                 = "vpc-03a2636c324942e42"
vpc_cidr_block         = "10.30.0.0/16"
```

<img width="1493" height="436" alt="image" src="https://github.com/user-attachments/assets/3345353c-b1c7-4739-99e5-20430fdb5108" />


#### Connect to EKS Cluster

Simply copy and run the generated kubectl_config_command to update your local kubeconfig:

```bash
# Run the command from your output

$ aws eks update-kubeconfig --region us-west-2 --name prod-stackai-supabase-eks

# Verify connection

$ kubectl get nodes

$ kubectl get pod -A

```

<img width="1535" height="1009" alt="image" src="https://github.com/user-attachments/assets/8ced9895-60cc-4bb3-8a6a-c476f0419698" />


#### Access RDS Database
The database is located in the Private Subnets for security. Access it via the EKS pods or a VPN/Bastion host within the VPC using the rds_db_endpoint.

```bash
# Example psql string

$ psql -h <rds_db_endpoint> -U supabase_admin -d postgres
```

## 5. Troubleshooting

### Handling State Lock Errors

If a deployment is interrupted, you may encounter a ConditionalCheckFailedException. You must force-unlock the state using the ID provided in the error message.

```bash
# Example Error: Error acquiring the state lock
# Lock Info ID: ff9f9069-c27b-ea13-d2a1-7f8feae274fb

# Resolution: Force unlock
$ terraform force-unlock ff9f9069-c27b-ea13-d2a1-7f8feae274fb
```

### EKS Version Upgrades

AWS EKS does not support skipping minor versions (e.g., 1.28 directly to 1.30).
Correct Path: Upgrade to 1.29 first, apply, then upgrade to 1.30.

## 6. CI/CD Pipeline (GitHub Actions)

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
