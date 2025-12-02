########################################
# EKS Cluster
########################################
resource "aws_eks_cluster" "dev_cluster" {
  name     = var.cluster_name
  role_arn = var.cluster_role
  version  = var.cluster_version

  vpc_config {
    subnet_ids             = var.subnet_ids
    endpoint_public_access = var.cluster_endpoint_public_access
    security_group_ids     = var.private_sg_id
  }

    tags = var.eks_cluster_tags

    depends_on = [var.eks_cluster_policies]
  }





########################################
# OIDC Provider for IRSA
########################################
data "tls_certificate" "oidc_cert" {
  url = aws_eks_cluster.dev_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.dev_cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc_cert.certificates[0].sha1_fingerprint]
}


