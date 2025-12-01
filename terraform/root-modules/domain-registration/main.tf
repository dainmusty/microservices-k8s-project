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

