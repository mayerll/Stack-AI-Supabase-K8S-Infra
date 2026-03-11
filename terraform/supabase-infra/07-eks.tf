

# ==========================================
# EKS Cluster Module
# ==========================================
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${locals.env_prefix}-eks"
  cluster_version = var.eks_version

  # Networking
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  # Authentication Mode (Required for 05-iam.tf Access Entries)
  authentication_mode = "API_AND_CONFIG_MAP"

  # Managed Node Groups
  eks_managed_node_groups = {
    general = {
      # Use the IAM Role defined in 05-iam.tf
      create_iam_role          = false
      iam_role_arn             = aws_iam_role.eks_nodes.arn
      
      instance_types           = [var.eks_instance_type]
      min_size                 = var.eks_min_size
      max_size                 = var.eks_max_size
      desired_size             = var.eks_desired_size

      # Update Strategy: Rolling update
      update_config = {
        max_unavailable = 1
      }
    }
  }

  # Cluster Add-ons (Required for EBS/Storage & Networking)
  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
    aws-ebs-csi-driver = { most_recent = true }
  }

  # ==========================================
  # Dependency & Lifecycle
  # ==========================================

  # CRITICAL: EKS requires the VPC (NAT Gateways & Routes) to be 100% ready 
  # so that nodes can join the cluster and pull images.
  depends_on = [
    module.vpc,
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly
  ]

  # Lifecycle: Protect the cluster from accidental deletion
  # If you change the cluster name, Terraform will block the destroy.
  lifecycle {
    prevent_destroy       = true
    create_before_destroy = true
    # Ignore changes to desired_size if you use Cluster Autoscaler
    ignore_changes        = [eks_managed_node_groups["general"].desired_size]
  }

  tags = locals.common_tags
}



