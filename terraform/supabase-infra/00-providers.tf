provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    # Replace with your actual bucket name
    bucket         = "stackai-supabase-terraform-state" 
    # This is the path/name of the state file within the bucket
    key            = "supabase-infra/terraform.tfstate"
    region         = "us-west-2"

    # Enable state locking via DynamoDB to prevent concurrent runs
    dynamodb_table = "supabase-terraform-state-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

