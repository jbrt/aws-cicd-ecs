# Variables

variable "project_name" {
  description = "Name of the project"
}
# Global variables

variable "region" {
  description = "Region where all AWS objects will be created"
}

variable "availability_zones" {
  description = "Which AZs will be used"
  type        = list(string)
}

variable "cidr" {
  description = "CIDR for the VPC"
}

variable "public_subnets" {
  description = "VPC Public sunets"
  type        = list(string)
}

variable "private_subnets" {
  description = "VPC Private sunets"
  type        = list(string)
}
