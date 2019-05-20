# Global variables

variable "region" {
  description = "Region where all AWS objects will be created"
  default = "eu-west-1"
}

variable "availability_zones" {
  description = "Which AZs will be used"
  type        = "list"
  default     = ["eu-west-1a", "eu-west-1c"]
}
