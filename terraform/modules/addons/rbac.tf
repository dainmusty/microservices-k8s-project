resource "kubernetes_cluster_role_binding_v1" "terraform_admin" {
  metadata {
    name = "terraform-admin"
  }

  subject {
    kind      = "User"
    name      = var.terraform_role_arn
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}
