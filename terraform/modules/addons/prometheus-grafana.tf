# Create Kubernetes Service Account for Grafana
resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Create Kubernetes Service Account for Grafana
resource "kubernetes_service_account_v1" "grafana" {
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

resource "kubernetes_secret_v1" "grafana_admin" {
  metadata {
    name      = "grafana-admin"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
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
  namespace        = kubernetes_namespace_v1.monitoring.metadata[0].name
  create_namespace = false

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.prometheus_stack_version

  # 🔑 Stability fixes
  timeout          = 900        # 15 minutes (mandatory for k-p-stack)
  wait             = true
  atomic           = true       # rollback on failure
  cleanup_on_fail  = true       # avoid broken helm state
  force_update     = false
  recreate_pods    = false

  values = [
    # Grafana service + admin secret
    templatefile("${path.module}/values/grafana-service.yaml", {
      region               = var.region
      grafana_admin_secret = kubernetes_secret_v1.grafana_admin.metadata[0].name
    }),

    # Alertmanager config
    file("${path.module}/values/alertmanager.yaml"),

    # Dashboards
    file("${path.module}/values/grafana-dashboards.yaml"),

    # Prometheus rules + performance tuning (see note below)
    file("${path.module}/values/prometheus_rules.yaml"),

    # 🔽 CRITICAL: disable CRD management in Helm
    file("${path.module}/values/kube-prometheus-crds.yaml")
  ]

  depends_on = [
    kubernetes_service_account_v1.grafana,
    kubernetes_secret_v1.grafana_admin,
    kubernetes_secret_v1.alertmanager_slack_webhook
  ]
}


data "aws_secretsmanager_secret_version" "slack_webhook" {
  secret_id = var.slack_webhook_secret_name
}

resource "kubernetes_secret_v1" "alertmanager_slack_webhook" {
  metadata {
    name      = "alertmanager-slack-webhook"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  data = {
    slack_url = jsondecode(data.aws_secretsmanager_secret_version.slack_webhook.secret_string)["url"]
  }

  type = "Opaque"
}

