data "aws_eks_addon_version" "latest" {
  for_each           = { for k, v in var.cluster_addons : k => v if lookup(v, "most_recent", false) == true }
  addon_name         = each.key
  kubernetes_version = var.cluster_version
  most_recent        = true
}

resource "aws_eks_addon" "addons" {
  for_each = var.cluster_addons

  cluster_name             = var.cluster_name
  addon_name               = each.key
  service_account_role_arn = var.vpc_cni_irsa_role_arn

  addon_version = lookup(each.value, "addon_version", try(data.aws_eks_addon_version.latest[each.key].version, null))
  resolve_conflicts_on_update = lookup(each.value, "resolve_conflicts_on_update", "PRESERVE")
}
