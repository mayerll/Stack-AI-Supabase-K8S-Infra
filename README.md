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

#### Verify identity

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

#### Create the EKS Admin User

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
## 5. Test on Supabase

Once the pods are in a `Running` state, follow these steps to verify your deployment.

### Quick Access (No DNS Required)
Use Kubernetes port-forwarding to access the **Supabase Studio (Dashboard)** immediately on your local machine:

```bash
# Forward Studio (Dashboard)
$ kubectl port-forward -n supabase svc/supabase-supabase-studio 8000:3000

# Forward API Gateway (Kong)
$ kubectl port-forward -n supabase svc/supabase-supabase-kong 8443:8000
```

<img width="1957" height="965" alt="image" src="https://github.com/user-attachments/assets/03f49bd1-9219-4f26-81ce-681c1513c023" />

Follow these steps to ensure the database, API gateway, and dashboard are working correctly.

### Database Connectivity
Verify that the PostgreSQL engine is online and accepting internal queries:

```bash
$ kubectl exec -it -n supabase supabase-supabase-db-0 -- psql -U postgres -c "SELECT version();"
```
<img width="1492" height="145" alt="image" src="https://github.com/user-attachments/assets/3031228b-a68b-4927-b9db-dc2f96a7b6a3" />

### Retrieve API Credentials
You need the Anon Key to make authorized API requests and the Dashboard credentials to log in to the UI.

```bash
# 1. Get the Anon JWT Key
export ANON_KEY=$(kubectl get secret supabase-jwt -n supabase -o jsonpath='{.data.anonKey}' | base64 --decode)

# 2. Get Studio Login Credentials
export STUDIO_USER=$(kubectl get secret supabase-dashboard -n supabase -o jsonpath='{.data.username}' | base64 --decode)
export STUDIO_PASS=$(kubectl get secret supabase-dashboard -n supabase -o jsonpath='{.data.password}' | base64 --decode)

echo "User: $STUDIO_USER | Pass: $STUDIO_PASS"

```

<img width="1612" height="169" alt="image" src="https://github.com/user-attachments/assets/2d1b3d85-2ef3-4fcc-b021-0164caa7c585" />

### Test the API Gateway (Kong)
Test if the external ingress is routing traffic to the REST API.

#### Local Port-Forward (Quick Test):
```bash
$ kubectl port-forward -n supabase svc/supabase-supabase-kong 8443:8000
```
### Authenticated API Test
Run the following to verify the API accepts your `anon` key:

1. **Get the key:**
```bash
$ kubectl get secret supabase-jwt -n supabase -o jsonpath='{.data.anonKey}' | base64 --decode
```
You will get ANON_KEY key.

<img width="1955" height="84" alt="image" src="https://github.com/user-attachments/assets/dcc31bd2-358d-4a4c-8d77-3549704f769f" />

In a new terminal, run:

```bash
$ curl -i -H "apikey: $ANON_KEY" -H "Authorization: Bearer $ANON_KEY" http://localhost:8443/rest/v1/

```
#### Expected Result: HTTP/1.1 200 OK
<img width="1952" height="928" alt="image" src="https://github.com/user-attachments/assets/d5d51257-f2a7-4332-b06f-e241408c6f20" />

### Access the Studio (Dashboard)
Your Ingress is configured for the host supabase.local.
##### Option 1: Using /etc/hosts (Recommended for Ingress test)
Get your LoadBalancer IP: nslookup <YOUR_AWS_ELB_DNS_NAME>
Add to your local /etc/hosts: <LB_IP> supabase.local
Visit: http://supabase.local
##### Option 2: Port-Forward (Immediate access)
```bash
$ kubectl port-forward -n supabase svc/supabase-supabase-studio 8000:3000
```
Visit: http://localhost:8000 and use the credentials (username and password) retrieved before.

#### Access the Studio (Dashboard)
Your Ingress is configured for the host supabase.local.

##### Option 1: Using /etc/hosts (Recommended for Ingress test)
Get your LoadBalancer IP: nslookup <YOUR_AWS_ELB_DNS_NAME>
Add to your local /etc/hosts: <LB_IP> supabase.local
Visit: http://supabase.local

##### Option 2: Port-Forward (Immediate access)
```bash
$ kubectl port-forward -n supabase svc/supabase-supabase-studio 8000:3000
```

Visit: http://localhost:8000 and use the credentials (username and password) retrieved.

### Service Endpoint Summary

| Service | Internal Secret | Ingress Host |
| :--- | :--- | :--- |
| **PostgreSQL** | `supabase-db` | N/A (Internal Only) |
| **Auth/API** | `supabase-jwt` | `supabase.local/auth` |
| **Studio UI** | `supabase-dashboard` | `supabase.local` |

## 6. Security & Cloud Integration

#### AWS S3 & Secrets Manager
This project uses **AWS S3** for file storage and **AWS Secrets Manager** via External Secrets Operator to manage sensitive keys.

<img width="1954" height="435" alt="image" src="https://github.com/user-attachments/assets/6bbcb1a3-bb3a-4b7f-8174-c1ffc7b8c26a" />

#### Network Policies
Traffic is restricted using Kubernetes NetworkPolicies. Only the Ingress Controller and internal Supabase services can communicate.

#### Smoke Testing
To run the automated health check:

```bash
$ chmod +x tests/smoke-test.sh
$ ./tests/smoke-test.sh
```

## 7. Scalability & Performance

#### Autoscaling (HPA)
Key components (`postgrest`, `realtime`, `storage`) are configured with **Horizontal Pod Autoscalers (HPA)**. They will scale between 2 and 10 replicas based on CPU/Memory thresholds.

#### Cluster Autoscaling
We use **Karpenter** (or Cluster Autoscaler) to provision new EKS nodes automatically when HPA triggers pod expansion.

#### Cloud-Native Security
- **Secrets Management**: Integrated with AWS Secrets Manager via External Secrets Operator.
- **Storage**: AWS S3 is used for object storage (replacing MinIO).
- **Network Isolation**: Kubernetes NetworkPolicies restrict traffic to prevent unauthorized internal access.

#### Smoke Testing
Run the automated production check:
```bash
./tests/smoke-test.sh


## 8. Troubleshooting

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

## 8. CI/CD Pipeline (GitHub Actions)

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
## 9. Observability Strategy

While a full monitoring stack is not deployed in this implementation, the architecture is designed with observability in mind. In a production environment, the Supabase deployment would integrate with AWS-native monitoring services and open-source observability tools.

The following observability pillars would be implemented:

### Metrics Monitoring

Cluster and application metrics can be collected using **Prometheus** and visualized through **Grafana** dashboards.

Typical monitored metrics include:

* Kubernetes node CPU and memory utilization
* Pod-level resource consumption
* PostgREST request latency and throughput
* Realtime WebSocket connection counts
* Storage API request rate
* Database connection pool usage

Prometheus can be deployed using the `kube-prometheus-stack` Helm chart, which includes:

* Prometheus
* Grafana
* Alertmanager
* Node Exporter
* kube-state-metrics

Example installation:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

Grafana dashboards would provide operational visibility into Supabase components and Kubernetes cluster health.

---

### Logging

Container logs from Supabase services (PostgREST, Realtime, Auth, Storage API, Kong) can be aggregated using **AWS CloudWatch Logs**.

Recommended architecture:

```
Kubernetes Pods
      │
Fluent Bit / CloudWatch Agent
      │
Amazon CloudWatch Logs
```

This enables centralized log storage, log search, and retention policies.

Logs can also be exported to systems such as:

* Loki
* Elasticsearch / OpenSearch
* Datadog

---

### Kubernetes Cluster Monitoring

For Kubernetes infrastructure monitoring, **Amazon CloudWatch Container Insights** can be enabled on the EKS cluster.

This provides:

* Node-level metrics
* Pod lifecycle monitoring
* Cluster capacity tracking
* Performance dashboards

Container Insights integrates with:

* CloudWatch Metrics
* CloudWatch Logs
* CloudWatch Alarms

---

### Alerting

Alerting rules would be defined through **Prometheus Alertmanager** or **CloudWatch Alarms**.

Example alerts include:

* High CPU or memory usage on Supabase services
* Pod crash loops
* Kubernetes node exhaustion
* RDS database connection saturation
* Elevated API latency

Alerts can be routed to operational channels such as:

* Slack
* PagerDuty
* Email
* Incident management systems

---

### Database Observability

The managed PostgreSQL database running on **Amazon RDS** provides built-in monitoring capabilities:

* Amazon RDS Performance Insights
* CloudWatch metrics for database performance
* Slow query logging
* Automated backup monitoring

Key metrics monitored:

* Database connections
* CPU usage
* Read/write latency
* Query performance

---

### Autoscaling Observability

Autoscaling decisions are observable through:

* Kubernetes Horizontal Pod Autoscaler metrics
* Karpenter node provisioning metrics
* Prometheus metrics for pod resource utilization

These metrics allow operators to validate scaling behavior under load.

---

### Future Improvements

Future enhancements to observability could include:

* Distributed tracing using OpenTelemetry
* Service-level monitoring using Grafana Tempo
* Log aggregation using Loki
* Synthetic health checks for Supabase endpoints
* End-to-end request tracing across Supabase services

These improvements would further enhance system reliability and operational visibility.
