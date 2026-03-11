variable "region" {
  default = "us-west-2"
}

variable "project_name" {
  default = "supabase"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "eks_version" {
  default = "1.30"
}

variable "postgres_version" {
  default = "18.3"
}

variable "db_instance_class" {
  default = "db.t3.micro"
}

variable "db_password" {
  description = "RDS root password"
  type        = string
  sensitive   = true
  # Note: You should ideally set this in secrets.tf or via ENV var
  default     = "SuperSecretPassword123" 
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "905921696455"
}

