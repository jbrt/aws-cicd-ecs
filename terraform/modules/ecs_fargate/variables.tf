variable "region" {
  description = "Region where the resource will be created"
  type        = "string"
}

variable "environment" {
  description = "The environment"
}

variable "vpc_id" {
  description = "The VPC id"
}

variable "security_groups_ids" {
  description = "The SGs to use"
}

variable "private_subnets_id" {
  type        = "list"
  description = "The private subnets to use"
}

variable "public_subnet_id" {
  type        = "list"
  description = "The private subnets to use"
}

variable "repository_name" {
  description = "The name of the ECR repository"
}

