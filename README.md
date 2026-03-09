# Supabase Production Deployment on AWS EKS

## Architecture Overview
- **VPC**: Isolated network with Public/Private subnets across 2 AZs.
- **Compute**: Managed EKS Node Groups in private subnets.
- **Data**: Amazon RDS for PostgreSQL (Multi-AZ) for durability.
- **Secrets**: AWS Secrets Manager integrated via External Secrets Operator.

## Deployment Instructions

### 1. Provision Infrastructure
```bash
./scripts/deploy-infra.sh
```




