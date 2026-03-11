
output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_arn" {
  description = "EKS Cluster ARN"
  value       = module.eks.cluster_arn
}

output "rds_db_endpoint" {
  description = "RDS Database Endpoint"
  value       = aws_db_instance.supabase_db.endpoint
}

output "rds_db_arn" {
  description = "RDS Database ARN"
  value       = aws_db_instance.supabase_db.arn
}

output "rds_db_name" {
  description = "RDS Database Name"
  value       = aws_db_instance.supabase_db.db_name
}

output "rds_db_instance_class" {
  description = "RDS Database Instance Class"
  value       = aws_db_instance.supabase_db.instance_class
}

