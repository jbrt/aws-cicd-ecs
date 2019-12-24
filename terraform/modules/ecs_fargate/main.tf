# ecs_fargate module
# Here we create:
# - CloudWatch log group
# - ECR repository
# - ECS cluster
# - ECS task definition
# - ALB load balancer
# - ECS service

# CloudWatch
resource "aws_cloudwatch_log_group" "logs" {
  name = "devops-ecs-testing"

  tags = {
    Environment = var.environment
    Application = "devops-ecs-testing"
    Terraform   = true
  }
}

# Creation of an ECR repository
resource "aws_ecr_repository" "repo" {
  name = var.repository_name
}

# Creation of the Cluster ECS
resource "aws_ecs_cluster" "cluster" {
  name = "${var.environment}-cluster"
}

# Create a simple task definition
data "template_file" "task_file" {
  template = file("${path.module}/files/task_definition.json")

  vars = {
    region     = var.region
    image      = aws_ecr_repository.repo.repository_url
    log_group  = aws_cloudwatch_log_group.logs.name
    log_prefix = "devops-ecs-testing"
  }
}

resource "aws_ecs_task_definition" "task_def" {
  family                   = "${var.environment}_task"
  container_definitions    = data.template_file.task_file.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_execution_role.arn
}

# ALB load balancer
resource "random_id" "target_group_sufix" {
  byte_length = 2
}

resource "aws_alb_target_group" "alb_target_group" {
  name        = "${var.environment}-tg-${random_id.target_group_sufix.hex}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  depends_on = [
    "aws_alb.alb_logs",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# security group for ALB
resource "aws_security_group" "devops-ecs_inbound_sg" {
  name        = "${var.environment}-devops-ecs-inbound-sg"
  description = "Allow HTTP from Anywhere into ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-devops-ecs-inbound-sg"
    Environment = var.environment
    Terraform   = true
  }
}

resource "aws_alb" "alb_logs" {
  name            = "${var.environment}-alb-logs"
  subnets         = var.public_subnet_id
  security_groups = [var.security_groups_ids, aws_security_group.devops-ecs_inbound_sg.id]

  tags = {
    Name        = "${var.environment}-alb-logs"
    Environment = var.environment
    Terraform   = true
  }
}

resource "aws_alb_listener" "logs" {
  load_balancer_arn = aws_alb.alb_logs.arn
  port              = "80"
  protocol          = "HTTP"
  depends_on        = ["aws_alb_target_group.alb_target_group"]

  default_action {
    target_group_arn = aws_alb_target_group.alb_target_group.arn
    type             = "forward"
  }
}

# IAM roles
data "aws_iam_policy_document" "ecs_service_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_role" {
  name               = "ecs_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_service_role.json
}

data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress"
    ]
  }
}

# ECS service IAM role
resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "ecs_service_role_policy"
  policy = data.aws_iam_policy_document.ecs_service_policy.json
  role   = aws_iam_role.ecs_role.id
}

# Role for the ECS container
resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = file("${path.module}/files/ecs-task-execution-role.json")
}
resource "aws_iam_role_policy" "ecs_execution_role_policy" {
  name   = "ecs_execution_role_policy"
  policy = file("${path.module}/files/ecs-execution-role-policy.json")
  role   = aws_iam_role.ecs_execution_role.id
}

# Let's describe an ECS service
# SG for this service
resource "aws_security_group" "ecs_service" {
  vpc_id      = var.vpc_id
  name        = "${var.environment}-ecs-service-sg"
  description = "Allow egress from container"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ecs-service-sg"
    Environment = var.environment
    Terraform   = true
  }
}

# Get the last version of the task definition by fetching the latest active revision
data "aws_ecs_task_definition" "task_def" {
  task_definition = aws_ecs_task_definition.task_def.family
}

# Create ECS service
resource "aws_ecs_service" "devops-ecs-testing" {
  name            = "${var.environment}-service"
  task_definition = "${aws_ecs_task_definition.task_def.family}:${max("${aws_ecs_task_definition.task_def.revision}", "${data.aws_ecs_task_definition.task_def.revision}")}"
  desired_count   = 2
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.cluster.id
  depends_on      = ["aws_iam_role_policy.ecs_service_role_policy", "aws_alb_target_group.alb_target_group"]

  network_configuration {
    security_groups = [var.security_groups_ids, aws_security_group.ecs_service.id]
    subnets         = var.private_subnets_id
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.alb_target_group.arn
    container_name   = "devops-ecs-testing"
    container_port   = "80"
  }

}
