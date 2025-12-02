# # Domain Registration and Hosted Zone Module
module "domain_registration" {
  source = "../../modules/domain-registration"

  domain_name = "companyname.com"
  
  contact = {
    first_name    = "companyname"
    last_name     = "companylogo"
    email         = "admin@companyname.com"
    phone_number  = "+11234567890"
    address       = "123 Main Street"
    city          = "companycitylocation"
    state         = "companystate"
    country_code  = "GH"          #expected country_code to be one of ["AC" "AD" "GH" "AF" "AG" "AL"] GH is supposed to be the country code for Ghana
    zip_code      = "00233"
  }
}


# Hosted Zone (referenced by all envs)
module "hosted_zone" {
  source    = "../../modules/hosted-zones"
  domain_name = module.domain_registration.registered_domain_name

}


# # Cloudfront and Route53 Module
module "cdn_route53" {
  source = "../../modules/cdn-route53"

  # AWS region where your EKS + ALB are deployed
  region = "us-east-1"

  # The root domain you want to register & host in Route 53
  hosted_zone_name = module.hosted_zone.hosted_zone_name

  # Two subdomains (will map to two CloudFront distributions)
  app_domain_primary   = "app.companyname.com"
  app_domain_secondary = "api.companyname.com"

  # ALB name as set by your Ingress annotation
  # e.g. alb.ingress.kubernetes.io/load-balancer-name: eks-alb
  alb_name = "eks-alb"  # Actual ALB is passed dynamically in the workflow. Update with the ALB name created by the ALB controller if you choose to run manually.

  # Enable or disable CloudFront logging
  enable_cf_logging = true

  # Pre-created S3 bucket for CloudFront logs
  log_bucket_name = "arn:aws:s3:::companybucket"   # Update with the bucket arn that was created during infra deployment.


}
