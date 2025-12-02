#######################################
# 1. Domain Registration
#########################################
resource "aws_route53domains_registered_domain" "dev_domain" {
  domain_name = var.domain_name
  auto_renew  = false

  admin_contact {
    first_name    = var.contact.first_name
    last_name     = var.contact.last_name
    contact_type  = "PERSON"
    email         = var.contact.email
    phone_number  = var.contact.phone_number
    address_line_1= var.contact.address
    city          = var.contact.city
    state         = var.contact.state
    country_code  = var.contact.country_code
    zip_code      = var.contact.zip_code
  }

  registrant_contact {
    first_name    = var.contact.first_name
    last_name     = var.contact.last_name
    contact_type  = "PERSON"
    email         = var.contact.email
    phone_number  = var.contact.phone_number
    address_line_1= var.contact.address
    city          = var.contact.city
    state         = var.contact.state
    country_code  = var.contact.country_code
    zip_code      = var.contact.zip_code
  }

  tech_contact {
    first_name    = var.contact.first_name
    last_name     = var.contact.last_name
    contact_type  = "PERSON"
    email         = var.contact.email
    phone_number  = var.contact.phone_number
    address_line_1= var.contact.address
    city          = var.contact.city
    state         = var.contact.state
    country_code  = var.contact.country_code
    zip_code      = var.contact.zip_code
  }
}
