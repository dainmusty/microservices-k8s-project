# Lookup existing hosted zone by domain name
data "aws_route53_zone" "dev_hosted_zone" {
  name         = var.hosted_zone_name
  private_zone = false
}
