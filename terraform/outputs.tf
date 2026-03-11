
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
