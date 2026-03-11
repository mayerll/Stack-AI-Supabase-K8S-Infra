provider "aws" { 
  region = var.region 
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = [cidrsubnet(var.vpc_cidr, 8, 1), cidrsubnet(var.vpc_cidr, 8, 2)]
  public_subnets  = [cidrsubnet(var.vpc_cidr, 8, 101), cidrsubnet(var.vpc_cidr, 8, 102)]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project_name}-eks"
  cluster_version = var.eks_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  # This ensures the role name is clean and fixed
  iam_role_name            = "${var.project_name}-eks-cluster-role"
  iam_role_use_name_prefix = false

  eks_managed_node_groups = {
    general = {
      iam_role_name            = "${var.project_name}-node-group-role"
      iam_role_use_name_prefix = false
      instance_types           = ["t3.medium"]
      min_size                 = 2
      max_size                 = 5
      desired_size             = 2
      
      # Automatically attach the EBS Policy needed for gp3
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }
}

