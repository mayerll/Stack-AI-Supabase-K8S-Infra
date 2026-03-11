
# ==========================================
# VPC Module Configuration (High Availability)
# ==========================================
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${locals.env_prefix}-vpc"
  cidr = var.vpc_cidr

  # Deploy across multiple AZs for resilience
  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = [cidrsubnet(var.vpc_cidr, 8, 1), cidrsubnet(var.vpc_cidr, 8, 2)]
  public_subnets  = [cidrsubnet(var.vpc_cidr, 8, 101), cidrsubnet(var.vpc_cidr, 8, 102)]

  # ==========================================
  # NAT Gateway Strategy (Performance Mode)
  # ==========================================
  # Since cost is not an issue, we use one NAT Gateway per AZ.
  # This avoids cross-AZ data transfer charges and prevents 
  # a single NAT failure from taking down the entire dev cluster.
  enable_nat_gateway     = true
  single_nat_gateway     = false 
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Standard EKS Discovery Tags
  public_subnet_tags = {
    "kubernetes.io/role/elb"                       = "1"
    "kubernetes.io/cluster/${locals.env_prefix}-eks" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"              = "1"
    "kubernetes.io/cluster/${locals.env_prefix}-eks" = "shared"
  }

  tags = locals.common_tags
}

# ==========================================
# Lifecycle & Dependency Analysis
# ==========================================
# No explicit depends_on is needed for the VPC itself.
# However, we will ensure RDS and EKS depend on this module 
# to guarantee the NAT Gateways are active before they attempt 
# outbound connections.


