
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
resource "aws_eks_access_entry" "eks_admin" {
  cluster_name      = module.eks.cluster_name
  # Replace with your actual ARN from the command above
  principal_arn     = "arn:aws:iam::905921696455:root" 
  user_name         = "admin"
  type              = "STANDARD"

  depends_on = [module.eks]
}


# Grant ClusterAdmin permissions to the entry
resource "aws_eks_access_policy_association" "eks_admin_policy" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::${var.aws_account_id}:user/eks-admin"

  access_scope {
    type = "cluster"
  }

  # CRITICAL: The policy cannot be associated until the Access Entry exists
  # Terraform often misses this hidden dependency without an explicit block
  depends_on = [aws_eks_access_entry.eks_admin]
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

  # Lifecycle: Prevent accidental deletion of the core node role
  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}

# ==========================================
# 3. Standard EKS Node Policy Attachments
# ==========================================
# These managed policies are required for nodes to join the cluster and pull images
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

# Required for the EBS CSI Driver to manage gp3 volumes (Storage)
resource "aws_iam_role_policy_attachment" "node_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_nodes.name
}

