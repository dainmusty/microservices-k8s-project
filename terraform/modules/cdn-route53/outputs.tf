output "primary_cf_domain"         { value = aws_cloudfront_distribution.primary.domain_name }
output "secondary_cf_domain"       { value = aws_cloudfront_distribution.secondary.domain_name }

output "primary_fqdn"              { value = var.app_domain_primary }
output "secondary_fqdn"            { value = var.app_domain_secondary }
