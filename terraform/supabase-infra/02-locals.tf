locals {
  env_prefix = "${terraform.workspace}-${var.project_name}"

  common_tags = {
    Project     = var.project_name
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
  }
}
