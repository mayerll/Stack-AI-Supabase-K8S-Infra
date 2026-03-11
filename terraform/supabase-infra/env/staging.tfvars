
aws_account_id    = "905921696455"
project_name      = "stackai-supabase"
region            = "us-west-2"

# Network - Isolated Range
vpc_cidr          = "10.20.0.0/16"

# Database (RDS) - Large for load testing
db_instance_class = "db.t3.large"
db_password       = "staging-secure-pass-9059"
db_storage        = 50

# Compute (EKS) - Scaling Ready
eks_instance_type = "t3.large"
eks_desired_size  = 2
eks_min_size      = 2
eks_max_size      = 5

