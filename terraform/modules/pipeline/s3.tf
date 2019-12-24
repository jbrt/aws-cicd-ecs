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