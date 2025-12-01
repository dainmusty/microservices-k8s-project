provider "aws" {
  region  = "us-east-1"

}

# CloudFront requires ACM certs in us-east-1
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}
