# Primary certificate
resource "aws_acm_certificate" "primary" {
  provider          = aws.useast1
  domain_name       = var.app_domain_primary
  validation_method = "DNS"
}

resource "aws_route53_record" "primary_validation" {
  for_each = {
    for dvo in aws_acm_certificate.primary.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  zone_id = data.aws_route53_zone.dev_hosted_zone.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}


resource "aws_acm_certificate_validation" "primary" {
  provider                = aws.useast1
  certificate_arn         = aws_acm_certificate.primary.arn
  validation_record_fqdns = [for r in aws_route53_record.primary_validation : r.fqdn]
}

# Secondary certificate
resource "aws_acm_certificate" "secondary" {
  provider          = aws.useast1
  domain_name       = var.app_domain_secondary
  validation_method = "DNS"
}

resource "aws_route53_record" "secondary_validation" {
  for_each = {
    for dvo in aws_acm_certificate.secondary.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  zone_id = data.aws_route53_zone.dev_hosted_zone.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "secondary" {
  provider                = aws.useast1
  certificate_arn         = aws_acm_certificate.secondary.arn
  validation_record_fqdns = [for r in aws_route53_record.secondary_validation : r.fqdn]
}
