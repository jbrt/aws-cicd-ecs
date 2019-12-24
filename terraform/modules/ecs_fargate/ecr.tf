# Creation of an ECR repository
resource "aws_ecr_repository" "repo" {
  name = var.repository_name
}