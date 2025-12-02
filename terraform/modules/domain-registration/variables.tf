variable "domain_name" {
  description = "The domain name to register"
  type        = string
}

variable "contact" {
  description = "Contact information for domain registration"
  type = object({
    first_name    = string
    last_name     = string
    email         = string
    phone_number  = string
    address       = string
    city          = string
    state         = string
    country_code  = string
    zip_code      = string
  })
}
