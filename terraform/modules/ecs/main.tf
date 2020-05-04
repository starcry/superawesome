resource "aws_security_group" "allow_web" {
  name        = "${var.name}-web"
  description = "Allow http/s inbound traffic"
  vpc_id   = var.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = var.from_port
    to_port     = var.to_port
    protocol    = var.protocol
    cidr_blocks   = var.cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_iam_role" "ecs_service_role" {
    name = "${var.name}_ecs_service_role"                                                                                                                                                                                      
    assume_role_policy = file("./policies/ecs-role.json")
}            
             
resource "aws_iam_role_policy" "ecs_service_role_policy" {
    name = "${var.name}_ecs_service_role_policy"
    policy = file("policies/ecs-service-role-policy.json")
    role = aws_iam_role.ecs_service_role.id
} 

resource "aws_lb" "ecs" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = var.subnets

  enable_deletion_protection = false

}

resource "aws_lb_target_group" "ecs" {
  name     = "${var.name}-target-group"
  port     = var.to_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  depends_on = [aws_lb.ecs]
}

resource "aws_lb_listener" "ecs" {
  load_balancer_arn = aws_lb.ecs.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.ecs.arn}"
  }
}

resource "aws_lb_listener_rule" "ecs" {
  listener_arn = aws_lb_listener.ecs.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }

  condition {
    host_header {
      values = [var.listener_url]
    }
  }
}

resource "aws_ecs_cluster" "ecs" {
  name = "${var.name}_ecs_cluster"
}

resource "aws_ecs_task_definition" "ecs" {
  family                = var.family
  container_definitions = file("task-definitions/service.json")

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [${var.azs}]"
    #expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  }
}

resource "aws_ecs_service" "ecs" {
  name            = "${var.name}_ecs"
  cluster         = aws_ecs_cluster.ecs.id
  task_definition = aws_ecs_task_definition.ecs.arn
  desired_count   = 3
  iam_role        = aws_iam_role.ecs_service_role.arn
  depends_on      = [aws_iam_role_policy.ecs_service_role_policy, aws_lb_target_group.ecs, aws_lb_listener_rule.ecs]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = var.container_name
    container_port   = 8080
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [eu-west-2a, eu-west-2b]"
  }
}