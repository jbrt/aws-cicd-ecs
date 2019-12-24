# CloudWatch
resource "aws_cloudwatch_log_group" "logs" {
  name = "devops-ecs-testing"

  tags = {
    Environment = var.environment
    Application = "devops-ecs-testing"
    Terraform   = true
  }
}