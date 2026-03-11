
# ==========================================
# 1. EKS Cluster Admin Access
# ==========================================
# Modern EKS Access Entry (Replaces aws-auth ConfigMap)
#resource "aws_eks_access_entry" "eks_admin" {
#  cluster_name      = module.eks.cluster_name
#  principal_arn     = "arn:aws:iam::${var.aws_account_id}:user/eks-admin"
#  user_name         = "eks-admin"
#  type              = "STANDARD"
#
#  # CRITICAL: Must wait for the EKS Cluster control plane to be fully 'ACTIVE'
#  depends_on = [module.eks]
#}
#
# ==========================================
# 1. EKS Cluster Access Management
# ==========================================

# Create the Access Entry for the admin user
resource "aws_eks_access_entry" "eks_admin" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = "arn:aws:iam::${var.aws_account_id}:user/eks-admin"
  user_name         = "eks-admin"
  type              = "STANDARD"

  # Must wait for the cluster to be active
  depends_on = [module.eks]
}

# PROFESSIONAL FIX: Add a 30s delay to handle AWS IAM eventual consistency.
# This prevents the "PrincipalArn could not be found" error during policy association.
resource "time_sleep" "wait_for_iam_propagation" {
  depends_on = [aws_eks_access_entry.eks_admin]

  create_duration = "30s"
}

# Associate the ClusterAdmin policy to the user
resource "aws_eks_access_policy_association" "eks_admin_policy" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::${var.aws_account_id}:user/eks-admin"

  access_scope {
    type = "cluster"
  }

  # Wait for the 30s timer instead of the resource directly
  depends_on = [time_sleep.wait_for_iam_propagation]
}

# ==========================================
# 2. Worker Node IAM Role
# ==========================================
resource "aws_iam_role" "eks_nodes" {
  name = "${local.env_prefix}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}

# ==========================================
# 3. Standard EKS Node Policy Attachments
# ==========================================
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_nodes.name
}

