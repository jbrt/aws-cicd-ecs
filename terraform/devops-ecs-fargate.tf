provider "aws" {
  region = "${var.region}"
  version = "1.60.0"
}

# First, we'll create a VPC
# With: 2 AZs, 1 public subnet and 1 private subnet in each zone
module "vpc" {
  source               = "./modules/vpc"
  environment          = "devops-ecs-testing"
  region               = "${var.region}"
  vpc_cidr             = "10.10.0.0/16"
  public_subnets_cidr  = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnets_cidr = ["10.10.10.0/24", "10.10.20.0/24"]
  availability_zones   = "${var.availability_zones}"
}

# Then, we create a ECS cluster in Fargate mode 
module "ecs_fargate" {
  source              = "./modules/ecs_fargate"
  region              = "${var.region}"
  environment         = "devops-ecs-testing"
  vpc_id              = "${module.vpc.vpc_id}"
  repository_name     = "devops-ecs-testing/production"
  private_subnets_id  = ["${module.vpc.private_subnet_id}"]
  public_subnet_id    = ["${module.vpc.public_subnet_id}"]
  security_groups_ids = ["${module.vpc.security_groups_ids}"]
}

# Finally, we create a DevOps pipeline (source: codecommit, build: codebuild, 
# deploy: to ECS)
module "pipeline" {
  source                      = "./modules/pipeline"
  codebuild_project           = "devops-ecs-testing"
  actifact_bucket             = "devops-ecs-testing"
  environment                 = "devops-ecs-testing"
  pipeline_name               = "devops-ecs-testing"
  repository_url              = "${module.ecs_fargate.repository_url}"
  repository_source           = "devops-ecs-testing-source"
  region                      = "${var.region}"
  ecs_service_name            = "${module.ecs_fargate.service_name}"
  ecs_cluster_name            = "${module.ecs_fargate.cluster_name}"
  run_task_subnet_id          = "${module.vpc.private_subnet_id[0]}"
  run_task_security_group_ids = ["${module.vpc.security_groups_ids}", "${module.ecs_fargate.security_group_id}"]
}
