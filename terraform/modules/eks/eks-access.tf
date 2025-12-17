resource "aws_eks_access_entry" "terraform" {
  cluster_name  = var.cluster_name
  principal_arn = var.eks_access_principal_arn  #"arn:aws:iam::651706774390:role/microservices-project-dev-tf-role"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "terraform_admin" {
  cluster_name  = var.cluster_name
  principal_arn = aws_eks_access_entry.terraform.principal_arn

  policy_arn = var.eks_access_entry_policies #"arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}


resource "aws_eks_access_entry" "nodes" {
  cluster_name  = var.cluster_name
  principal_arn = var.node_group_role_arn
  type          = "EC2_LINUX"
}

resource "aws_eks_access_policy_association" "nodes" {
  cluster_name  = var.cluster_name
  principal_arn = aws_eks_access_entry.nodes.principal_arn

  policy_arn = var.node_access_policies  #"arn:aws:eks::aws:cluster-access-policy/AmazonEKSWorkerNodePolicy"

  access_scope {
    type = "cluster"
  }
}
