project_name       = "devops-ecs-testing"
region             = "eu-west-1"
availability_zones = ["eu-west-1a", "eu-west-1c"]
cidr               = "10.10.0.0/16"
private_subnets    = ["10.10.10.0/24", "10.10.20.0/24"]
public_subnets     = ["10.10.1.0/24", "10.10.2.0/24"]
