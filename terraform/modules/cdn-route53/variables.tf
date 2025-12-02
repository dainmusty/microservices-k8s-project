variable "region" {
  description = "AWS region for your EKS/ALB"
  type        = string
  default     = "us-east-1"
}

variable "hosted_zone_name" {
  description = "Root domain to register (e.g. mycoolapp.com)"
  type        = string
}

variable "app_domain_primary" {
  description = "First subdomain (e.g. app.mycoolapp.com)"
  type        = string
}

variable "app_domain_secondary" {
  description = "Second subdomain (e.g. api.mycoolapp.com)"
  type        = string
}

variable "alb_name" {
  description = "Name of the ALB created by AWS LB Controller"
  type        = string
}

variable "log_bucket_name" {
  description = "Existing S3 bucket for CloudFront logs"
  type        = string
  default     = ""
  
}

variable "enable_cf_logging" {
  description = "Enable CloudFront standard logs to S3"
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Enable IPv6 on CloudFront and AAAA records"
  type        = bool
  default     = true
}


