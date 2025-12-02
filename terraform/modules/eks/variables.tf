# Variables for EKS Cluster.
variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
  
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "cluster_endpoint_public_access" {
  description = "Enable or disable public access to EKS endpoint"
  type        = bool
  default     = true
}

variable "cluster_version" {
  description = "EKS Cluster version"
  type        = string
  default     = "1.34"
}

variable "subnet_ids" {
  description = "Subnets used by EKS"
  type        = list(string)
}

variable "private_sg_id" {
  description = "SG for the private subnet"
  type        = list(string)
}

variable "cluster_role" {
  description = "ARN of the EKS Cluster Role"
  type        = string
  
}

variable "eks_cluster_tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}


variable "eks_cluster_policies" {
  description = "EKS Cluster Policy Attachment"
  type        = any
}



# Variables for EKS Managed Node Groups.
variable "node_group_role_arn" {
  description = "ARN of the Node Group IAM Role"
  type        = string
  
}

variable "eks_node_groups_configuration" {
  description = "Node group configuration map"
  type = map(object({
    min_size       = number
    max_size       = number
    desired_size   = number
    instance_types = list(string)
    capacity_type  = optional(string)
    tags           = optional(map(string))
  }))
  default = {}
}

variable "eks_managed_node_group_defaults" {
  description = "Defaults for node groups"
  type = object({
    ami_type                             = string
    instance_types                       = list(string)
    attach_cluster_primary_security_group = optional(bool, false)
  })
  default = {
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = ["t2.micro"]
  }
  
}


# Variables for EKS and Node Group role and policies.
variable "eks_node_policies" {
  description = "List of IAM policies to attach to the EKS Node Group role"
  type        = list(string)
  default     = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
  
}
