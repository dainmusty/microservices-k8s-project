# # Secret for Grafana Admin Password
# resource "aws_secretsmanager_secret" "grafana_admin" {
#   name        = "grafana-admin-password"
#   description = "Grafana admin password"
# }

# resource "aws_secretsmanager_secret_version" "grafana_admin_version" {
#   secret_id     = aws_secretsmanager_secret.grafana_admin.id
#   secret_string = jsonencode({ password = "StrongPassword123!" })
# }

# # Secret for Alertmanager Slack Webhook
# resource "aws_secretsmanager_secret" "slack_webhook" {
#   name = "slack/webhook/prometheus-alertmanager"
# }

# resource "aws_secretsmanager_secret_version" "slack_webhook_version" {
#   secret_id     = aws_secretsmanager_secret.slack_webhook.id
#   secret_string = jsonencode({ url = "https://hooks.slack.com/services/T0000/B0000/XXXX" })
# }
