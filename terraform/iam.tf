
resource "aws_eks_access_entry" "eks_admin" {
  cluster_name      = "supabase-eks"
  principal_arn     = "arn:aws:iam::905921696455:user/eks-admin"
  user_name         = "eks-admin"
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "eks_admin_policy" {
  cluster_name  = "supabase-eks"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::905921696455:user/eks-admin"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.eks_admin]
}

