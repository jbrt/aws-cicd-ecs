data "template_file" "codebuild_policy" {
  template = file("${path.module}/policies/codebuild_policy.json")

  vars = {
    aws_s3_bucket_arn = aws_s3_bucket.source.arn
  }
}

# Using the buildspec file
data "template_file" "buildspec" {
  template = file("${path.module}/buildspec.yml")

  vars = {
    repository_url     = var.repository_url
    region             = var.region
    cluster_name       = var.ecs_cluster_name
    subnet_id          = var.run_task_subnet_id
    security_group_ids = join(",", var.run_task_security_group_ids)
  }
}

resource "aws_codebuild_project" "devops-ecs-testing" {
  name          = var.codebuild_project
  build_timeout = "10"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/docker:17.09.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = data.template_file.buildspec.rendered
  }
}