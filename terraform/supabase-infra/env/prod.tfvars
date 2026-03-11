
aws_account_id    = "905921696455"
project_name      = "stackai-supabase"
region            = "us-west-2"

# Network - Isolated Range
vpc_cidr          = "10.30.0.0/16"

# Database (RDS) - Fixed Performance (m5)
db_instance_class = "db.m5.large"
db_password       = "PROD-COMPLEX-PASS-9059"
db_storage        = 100

# Compute (EKS) - High Availability (3 Nodes)
eks_instance_type = "m5.large"
eks_desired_size  = 3
eks_min_size      = 3
eks_max_size      = 10

