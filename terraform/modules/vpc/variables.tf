variable "region" {
  description = "The region where the VPC will be created"
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
}

variable "public_subnets_cidr" {
  type        = "list"
  description = "The CIDR block for the public subnet"
}

variable "availability_zones" {
  type = "list"
  description = "AZs"
}

variable "private_subnets_cidr" {
  type        = "list"
  description = "The CIDR block for the private subnet"
}

variable "environment" {
  description = "The environment name for this project"
  type        = "string"
}
