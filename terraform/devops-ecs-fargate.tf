provider "aws" {
  region  = var.region
  version = "~> 2.43"
}

# First, we'll create a VPC
# With: 2 AZs, 1 public subnet and 1 private subnet in each zone
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name               = var.project_name
  cidr               = var.cidr
  azs                = var.availability_zones
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Then, we create a ECS cluster in Fargate mode 
module "ecs_fargate" {
  source              = "./modules/ecs_fargate"
  region              = var.region
  environment         = var.project_name
  vpc_id              = module.vpc.vpc_id
  repository_name     = "${var.project_name}/production"
  private_subnets_id  = module.vpc.private_subnets
  public_subnet_id    = module.vpc.public_subnets
  security_groups_ids = module.vpc.default_security_group_id
}

# Finally, we create a pipeline (source: codecommit, build: codebuild, deploy: to ECS)
module "pipeline" {
  source                      = "./modules/pipeline"
  codebuild_project           = var.project_name
  actifact_bucket             = var.project_name
  environment                 = var.project_name
  pipeline_name               = var.project_name
  repository_url              = module.ecs_fargate.repository_url
  repository_source           = "${var.project_name}-source"
  region                      = var.region
  ecs_service_name            = module.ecs_fargate.service_name
  ecs_cluster_name            = module.ecs_fargate.cluster_name
  run_task_subnet_id          = module.vpc.private_subnets[0]
  run_task_security_group_ids = [module.vpc.default_security_group_id, module.ecs_fargate.security_group_id]
}
