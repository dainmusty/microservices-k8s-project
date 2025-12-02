locals {
  log_bucket_domain = "${var.log_bucket_name}.s3.amazonaws.com"
}

# PRIMARY distribution (e.g., app.<domain>)
resource "aws_cloudfront_distribution" "primary" {
  enabled         = true
  is_ipv6_enabled = var.enable_ipv6
  http_version    = "http2and3"
  price_class     = "PriceClass_100"
  aliases         = [var.app_domain_primary]
  wait_for_deployment = true

  origin {
    domain_name = data.aws_lb.eks_ingress_alb.dns_name
    origin_id   = "alb-origin-primary"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "alb-origin-primary"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods  = ["GET","HEAD","OPTIONS","PUT","PATCH","POST","DELETE"]
    cached_methods   = ["GET","HEAD"]

    # API-friendly: disable caching and pass through headers/query/cookies
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
    compress                 = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "logging_config" {
    for_each = var.enable_cf_logging ? [1] : []
    content {
      bucket          = local.log_bucket_domain  # e.g., log_bucket.s3.amazonaws.com
      prefix          = "cloudfront/primary/"
      include_cookies = true
    }
  }

  viewer_certificate {
    # Use the *validated* certificate ARN to enforce dependency on DNS validation
    acm_certificate_arn      = aws_acm_certificate_validation.primary.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# SECONDARY distribution (e.g., api.<domain>)
resource "aws_cloudfront_distribution" "secondary" {
  enabled         = true
  is_ipv6_enabled = var.enable_ipv6
  http_version    = "http2and3"
  price_class     = "PriceClass_100"
  aliases         = [var.app_domain_secondary]
  wait_for_deployment = true

  origin {
    domain_name = data.aws_lb.eks_ingress_alb.dns_name
    origin_id   = "alb-origin-secondary"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "alb-origin-secondary"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods  = ["GET","HEAD","OPTIONS","PUT","PATCH","POST","DELETE"]
    cached_methods   = ["GET","HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
    compress                 = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "logging_config" {
    for_each = var.enable_cf_logging ? [1] : []
    content {
      bucket          = local.log_bucket_domain
      prefix          = "cloudfront/secondary/"
      include_cookies = true
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.secondary.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}



# Use AWS managed cache policies
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}
