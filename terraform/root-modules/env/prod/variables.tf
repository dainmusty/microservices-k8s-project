variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "effulgencetech-dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
