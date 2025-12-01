output "cluster_name" {
  value = aws_eks_cluster.dev_cluster.name
}

output "cluster_version" {
  value = aws_eks_cluster.dev_cluster.version
}

output "oidc_provider_url" {
  value = aws_eks_cluster.dev_cluster.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}

output "cluster_endpoint" {
  value = aws_eks_cluster.dev_cluster.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.dev_cluster.certificate_authority[0].data
}


# Output the node group details
output "node_group_names" {
  value = [for ng in aws_eks_node_group.dev_wg : ng.node_group_name]
}
