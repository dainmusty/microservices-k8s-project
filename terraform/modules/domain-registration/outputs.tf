output "registered_domain_name"                 { 
    value = aws_route53domains_registered_domain.dev_domain.domain_name
    description = "name of the registered domain"
  
}