
# ==========================================
# 01. Network Outputs (VPC)
# ==========================================
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

# ==========================================
# 02. EKS Cluster Outputs
# ==========================================
output "eks_cluster_name" {
  description = "The name of the EKS Cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "The API endpoint for the EKS Cluster"
  value       = module.eks.cluster_endpoint
}

output "kubectl_config_command" {
  description = "Command to update your local kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
  
  # Ensure the command is only shown once the Access Entry is actually ready
  depends_on = [aws_eks_access_policy_association.eks_admin_policy]
}

# ==========================================
# 03. Database Outputs (RDS)
# ==========================================
output "rds_db_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.supabase_db.endpoint
  
  # Ensure the endpoint is only displayed once the DB is fully 'Available'
  depends_on = [aws_db_instance.supabase_db]
}

output "rds_db_name" {
  description = "The name of the default database"
  value       = aws_db_instance.supabase_db.db_name
}

# ==========================================
# 04. Storage Outputs (S3)
# ==========================================
output "s3_bucket_name" {
  description = "The unique name of the S3 bucket"
  value       = aws_s3_bucket.storage.id
}

# ==========================================
# 05. Environment Metadata
# ==========================================
output "deployment_info" {
  description = "Current deployment context"
  value = {
    workspace = terraform.workspace
    region    = var.region
    prefix    = local.env_prefix
  }
}



