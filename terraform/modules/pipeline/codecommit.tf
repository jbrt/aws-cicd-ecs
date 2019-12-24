# Creating of a Git repository
resource "aws_codecommit_repository" "source_code" {
  repository_name = var.repository_source
  description     = "This is the Sample App Repository"
}