
# ==========================================
# 1. Global & Project Settings
# ==========================================
variable "project_name" {
  description = "The name of the project, used as a prefix for all resources to ensure uniqueness."
  type        = string
  default     = "stackai-supabase"
}

variable "region" {
  description = "The AWS region where resources will be deployed (e.g., us-west-2)."
  type        = string
  default     = "us-west-2"
}

variable "aws_account_id" {
  description = "The 12-digit AWS account ID required for IAM principal ARNs and EKS access entries."
  type        = string
  default     = "905921696455" # <--- Added Default
}

# ==========================================
# 2. Network (VPC) Configuration
# ==========================================
variable "vpc_cidr" {
  description = "The CIDR block for the VPC (e.g., 10.0.0.0/16)."
  type        = string
  default     = "10.0.0.0/16"
}

# ==========================================
# 3. Database (RDS) Configuration
# ==========================================
variable "postgres_version" {
  description = "The version of the PostgreSQL engine to use for the RDS instance."
  type        = string
  default     = "15"
}

variable "db_instance_class" {
  description = "The compute instance type for the RDS database (e.g., db.t3.medium)."
  type        = string
  default     = "db.t3.medium" 
}

variable "db_password" {
  description = "The master password for the PostgreSQL database. This is marked as sensitive."
  type        = string
  sensitive   = true
  default     = "REPLACE_IT"  
}

variable "db_storage" {
  description = "The amount of allocated storage in GB for the RDS instance."
  type        = number
  default     = 20
}

# ==========================================
# 4. Compute (EKS) Configuration
# ==========================================
variable "eks_version" {
  description = "The desired Kubernetes version for the EKS cluster (e.g., 1.28)."
  type        = string
  default     = "1.29"
}

variable "eks_instance_type" {
  description = "The EC2 instance type for the EKS managed node group (e.g., t3.medium)."
  type        = string
  default     = "t3.medium" # <--- Added Default
}

variable "eks_desired_size" {
  description = "The initial number of worker nodes in the EKS node group."
  type        = number
  default     = 2
}

variable "eks_min_size" {
  description = "The minimum number of worker nodes for the auto-scaling group."
  type        = number
  default     = 1
}

variable "eks_max_size" {
  description = "The maximum number of worker nodes for the auto-scaling group."
  type        = number
  default     = 5
}

variable "eks_node_role_name" {
  description = "The name of the IAM role for the EKS worker nodes"
  type        = string
  default     = "stackai-supabase-node-role" 
}

# ==========================================
# 5. Secrets Manager
# ==========================================

variable "secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  type        = string
  default     = "supabase-db-credentials"
}

variable "secret_description" {
  description = "Description of the secret"
  type        = string
  default     = "Supabase database credentials"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

