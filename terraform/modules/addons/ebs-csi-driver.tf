resource "kubernetes_service_account" "ebs_csi_controller" {
  metadata {
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = var.ebs_csi_role_arn
    }
  }
}


# Helm release for EBS CSI Driver
resource "helm_release" "ebs_csi_driver" {
  name             = "aws-ebs-csi-driver"
  namespace        = "kube-system"
  create_namespace = false

  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  version    = "2.28.0"

  values = [
    yamlencode({
      controller = {
        serviceAccount = {
          create = false
          name   = "ebs-csi-controller-sa"
        }
      }
    })
  ]
  depends_on = [kubernetes_service_account.ebs_csi_controller]
}
