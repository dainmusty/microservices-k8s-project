resource "aws_eks_node_group" "dev_wg" {
  for_each = var.eks_node_groups_configuration

  cluster_name    = var.cluster_name
  node_group_name = each.key
  node_role_arn   = var.node_group_role_arn
  subnet_ids      = var.subnet_ids

  ami_type        = lookup(var.eks_managed_node_group_defaults, "ami_type", "AL2023_x86_64_STANDARD")
  instance_types  = lookup(each.value, "instance_types", var.eks_managed_node_group_defaults.instance_types)
  capacity_type   = lookup(each.value, "capacity_type", "SPOT")

  scaling_config {
    desired_size = lookup(each.value, "desired_size", 1)
    max_size     = lookup(each.value, "max_size", 2)
    min_size     = lookup(each.value, "min_size", 1)
  }

  tags = lookup(each.value, "tags", {})

  depends_on = [var.eks_node_policies]
}
