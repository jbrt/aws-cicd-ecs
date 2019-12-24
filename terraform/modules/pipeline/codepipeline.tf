# pipeline module
# Creation of :
# - S3 Bucket for storing artifacts
# - CodeCommit repository
# - CodeBuild project
# - CodePipeline

# Creating of an S3 bucket for storing CodePipeline artifacts
resource "aws_s3_bucket" "source" {
  bucket        = "${var.actifact_bucket}-experiment-source"
  acl           = "private"
  force_destroy = true

  tags = {
    Name        = "${var.environment}-devops-ecs-testing"
    Environment = var.environment
    Terraform   = true
  }
}

# Creating of a Git repository
resource "aws_codecommit_repository" "source_code" {
  repository_name = var.repository_source
  description     = "This is the Sample App Repository"
}

# IAM role for the pipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = file("${path.module}/policies/codepipeline_role.json")
}

# IAM policy for the pipeline
data "template_file" "codepipeline_policy" {
  template = file("${path.module}/policies/codepipeline.json")

  vars = {
    aws_s3_bucket_arn = aws_s3_bucket.source.arn
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.template_file.codepipeline_policy.rendered
}

# CodeBuild project
resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild-role"
  assume_role_policy = file("${path.module}/policies/codebuild_role.json")
}

data "template_file" "codebuild_policy" {
  template = file("${path.module}/policies/codebuild_policy.json")

  vars = {
    aws_s3_bucket_arn = aws_s3_bucket.source.arn
  }
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "codebuild-policy"
  role   = aws_iam_role.codebuild_role.id
  policy = data.template_file.codebuild_policy.rendered
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

# Create and define the pipeline
resource "aws_codepipeline" "pipeline" {
  name     = var.pipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.source.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        RepositoryName = var.repository_source
        BranchName     = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["imagedefinitions"]

      configuration = {
        ProjectName = var.codebuild_project
      }
    }
  }

  stage {
    name = "Production"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["imagedefinitions"]
      version         = "1"

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
