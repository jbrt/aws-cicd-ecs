output "alb_dns_name" {
  value = "${aws_alb.alb_logs.dns_name}"
}

output "alb_zone_id" {
  value = "${aws_alb.alb_logs.zone_id}"
}

output "cluster_name" {
  value = "${aws_ecs_cluster.cluster.name}"
}

output "repository_url" {
  value = "${aws_ecr_repository.repo.repository_url}"
}

output "service_name" {
  value = "${aws_ecs_service.devops-ecs-testing.name}"
}

output "security_group_id" {
  value = "${aws_security_group.ecs_service.id}"
}
