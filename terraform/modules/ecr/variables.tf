variable "repository_name" {
  type        = string
  description = "Name of the ECR repository"
}

variable "image_tag_mutability" {
  type        = string
  default     = "IMMUTABLE"
  description = "Whether image tags are mutable or immutable"
}

variable "scan_on_push" {
  type        = bool
  
}

variable "tags" {
  type    = map(string)
  default = {}
}
