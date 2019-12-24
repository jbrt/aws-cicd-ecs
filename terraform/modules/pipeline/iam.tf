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

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "codebuild-policy"
  role   = aws_iam_role.codebuild_role.id
  policy = data.template_file.codebuild_policy.rendered
}