resource "aws_eks_access_entry" "eks_admin" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = "arn:aws:iam::${var.aws_account_id}:user/eks-admin"
  user_name         = "eks-admin"
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "eks_admin_policy" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::${var.aws_account_id}:user/eks-admin"

  access_scope {
    type = "cluster"
  }
  
  depends_on = [aws_eks_access_entry.eks_admin]
}

resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-eks-node-group"

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
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_nodes.name
}

