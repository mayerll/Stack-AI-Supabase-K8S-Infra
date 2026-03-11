
aws_account_id    = "905921696455"
project_name      = "stackai-supabase"
region            = "us-west-2"

# Network - Isolated Range
vpc_cidr          = "10.10.0.0/16"

# Database (RDS) - Performance Mode
db_instance_class = "db.t3.medium"
db_password       = "dev-secure-pass-9059" # Replace with your secret
db_storage        = 20

# Compute (EKS) - 2 Nodes min
eks_instance_type = "t3.medium"
eks_desired_size  = 2
eks_min_size      = 2
eks_max_size      = 4

