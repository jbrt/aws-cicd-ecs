# Finally we print the URL of the ALB
output "git_repository" {
  value = "${module.pipeline.repository_url}"
}

output "load_balancer_url" {
  value = "${module.ecs_fargate.alb_dns_name}"
}
