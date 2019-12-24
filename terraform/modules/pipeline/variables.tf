variable "actifact_bucket" {
  description = "The name of the bucket where the artifact will be send"
  type        = "string"
}

variable "codebuild_project" {
  description = "The name of the CodeBuild project"
  type        = "string"
}

variable "pipeline_name" {
  description = "The name of the pipeline"
  type        = "string"
}

variable "ecs_cluster_name" {
  description = "The cluster that we will deploy"
}

variable "ecs_service_name" {
  description = "The ECS service that will be deployed"
}

variable "environment" {
  description = "The environment"
}

variable "region" {
  description = "The region to use"
}

variable "repository_url" {
  description = "The url of the ECR repository"
}

variable "repository_source" {
  description = ""
  type        = "string"
}

variable "run_task_subnet_id" {
  description = "The subnet Id where single run task will be executed"
}

variable "run_task_security_group_ids" {
  type        = "list"
  description = "The security group Ids attached where the single run task will be executed"
}
