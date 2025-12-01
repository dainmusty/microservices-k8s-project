# (A/AAAA aliases → each CF distribution)

resource "aws_route53_record" "primary_a" {
  zone_id = data.aws_route53_zone.dev_hosted_zone.zone_id
  name    = var.app_domain_primary
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.primary.domain_name
    zone_id                = aws_cloudfront_distribution.primary.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "primary_aaaa" {
  count  = var.enable_ipv6 ? 1 : 0
  zone_id = data.aws_route53_zone.dev_hosted_zone.zone_id
  name    = var.app_domain_primary
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.primary.domain_name
    zone_id                = aws_cloudfront_distribution.primary.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "secondary_a" {
  zone_id = data.aws_route53_zone.dev_hosted_zone.zone_id
  name    = var.app_domain_secondary
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.secondary.domain_name
    zone_id                = aws_cloudfront_distribution.secondary.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "secondary_aaaa" {
  count  = var.enable_ipv6 ? 1 : 0
  zone_id = data.aws_route53_zone.dev_hosted_zone.zone_id
  name    = var.app_domain_secondary
  type    = "AAAA"  
  alias {
    name                   = aws_cloudfront_distribution.secondary.domain_name
    zone_id                = aws_cloudfront_distribution.secondary.hosted_zone_id
    evaluate_target_health = false
  }
}
