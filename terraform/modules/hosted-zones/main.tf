#########################################
# 1. Hosted Zone
#########################################
resource "aws_route53_zone" "dev_hosted_zone" {
  name = var.domain_name
}


