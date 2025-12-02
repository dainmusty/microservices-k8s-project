# 1. Create Namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# 2. Create IRSA-enabled Service Account
resource "kubernetes_service_account" "argocd_sa" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = var.argocd_role_arn
    }
  }

  depends_on = [kubernetes_namespace.argocd]
}

# 3. Install ArgoCD via Helm with Ingress enabled (HTTP only)
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false

  values = [file("${path.module}/values/argo-ingress-values.yaml")]

  set {
    name  = "server.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "server.serviceAccount.name"
    value = kubernetes_service_account.argocd_sa.metadata[0].name
  }
}
