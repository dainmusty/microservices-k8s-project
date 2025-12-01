# Create Kubernetes Service Account for Grafana
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Create Kubernetes Service Account for Grafana
resource "kubernetes_service_account" "grafana" {
  metadata {
    name      = "grafana"
    namespace = "monitoring"
    annotations = {
      "eks.amazonaws.com/role-arn" = var.grafana_irsa_arn
    }
  }
}


data "aws_secretsmanager_secret_version" "grafana_admin" {
  secret_id = var.grafana_secret_name
}

locals {
  grafana_secret = jsondecode(data.aws_secretsmanager_secret_version.grafana_admin.secret_string)
}

resource "kubernetes_secret" "grafana_admin" {
  metadata {
    name      = "grafana-admin"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    admin-user     = local.grafana_secret.username
    admin-password = local.grafana_secret.password
  }

  type = "Opaque"
}


# Deploys the kube-prometheus-stack Helm chart for monitoring(Prometheus, Grafana, etc.)
resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "56.7.0"

  values = [
  templatefile("${path.module}/values/grafana.yaml", {
    region              = var.region
    grafana_admin_secret = kubernetes_secret.grafana_admin.metadata[0].name
  }),
  file("${path.module}/values/alertmanager.yaml"),
  file("${path.module}/values/prometheus_rules.yaml")

  ]

  depends_on = [
    kubernetes_service_account.grafana,
    kubernetes_secret.grafana_admin,
    kubernetes_secret.alertmanager_slack_webhook
  ]
}

data "aws_secretsmanager_secret_version" "slack_webhook" {
  secret_id = var.slack_webhook_secret_name
}

resource "kubernetes_secret" "alertmanager_slack_webhook" {
  metadata {
    name      = "alertmanager-slack-webhook"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    slack_url = jsondecode(data.aws_secretsmanager_secret_version.slack_webhook.secret_string)["url"]
  }

  type = "Opaque"
}



# resource "kubernetes_storage_class" "ebs_sc" {
#   metadata {
#     name = "ebs-sc"
#   }

#   provisioner          = "ebs.csi.aws.com"
#   reclaim_policy       = "Delete"
#   volume_binding_mode  = "WaitForFirstConsumer"
#   allow_volume_expansion = true
# }

