module "vpc" {
  source = "./modules/vpc"

  name = "superawesome"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-2a", "eu-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "allow_web" {
  name        = "superawesome"
  description = "Allow http/s inbound traffic"
  vpc_id   = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks   = module.vpc.public_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}


resource "aws_iam_role" "ecs_service_role" {
    name = "ecs_service_role"                                                                                                                                                                                      
    assume_role_policy = file("policies/ecs-role.json")
}            
             
resource "aws_iam_role_policy" "ecs_service_role_policy" {
    name = "ecs_service_role_policy"
    policy = file("policies/ecs-service-role-policy.json")
    role = aws_iam_role.ecs_service_role.id
} 

resource "aws_lb" "superawesome" {
  name               = "superawesome"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = true

}

resource "aws_lb_target_group" "superawesome" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  depends_on = [aws_lb.superawesome]
}

resource "aws_lb_listener" "superawesome" {
  load_balancer_arn = aws_lb.superawesome.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener_rule" "superawesome" {
  listener_arn = aws_lb_listener.superawesome.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.superawesome.arn
  }

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }

  condition {
    host_header {
      values = ["example.com"]
    }
  }
}

resource "aws_ecs_cluster" "superawesome" {
  name = "superawesome"
}

resource "aws_ecs_task_definition" "superawesome" {
  family                = "hello-world"
  container_definitions = file("task-definitions/service.json")

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  }
}

resource "aws_ecs_service" "superawesome" {
  name            = "superawesome"
  cluster         = aws_ecs_cluster.superawesome.id
  task_definition = aws_ecs_task_definition.superawesome.arn
  desired_count   = 3
  iam_role        = aws_iam_role.ecs_service_role.arn
  depends_on      = [aws_iam_role_policy.ecs_service_role_policy, aws_lb_target_group.superawesome, aws_lb_listener_rule.superawesome]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.superawesome.arn
    container_name   = "superawesome"
    container_port   = 8080
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [eu-west-2a, eu-west-2b]"
  }
}




#module "eks_cluster" {
#  source = "./modules/eks"
#  cluster_name = "superawesome"
#  eks_role = "superawesome_cluster"
#  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
#}




#resource "aws_iam_role" "example" {
#  name = "superawesome"
#
#  assume_role_policy = <<POLICY
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Effect": "Allow",
#      "Principal": {
#        "Service": "eks.amazonaws.com"
#      },
#      "Action": "sts:AssumeRole"
#    }
#  ]
#}
#POLICY
#
#}
#
#resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
#  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#  role       = aws_iam_role.example.name
#}
#
#resource "aws_iam_role_policy_attachment" "example-AmazonEKSServicePolicy" {
#  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
#  role       = aws_iam_role.example.name
#}

#resource "aws_eks_cluster" "example" {
#  name = "superawesome"
#  role_arn = aws_iam_role.example.arn
#
#  vpc_config {
#    subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
#  }
#
#  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
#  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
#  depends_on = [
#    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
#    aws_iam_role_policy_attachment.example-AmazonEKSServicePolicy,
#  ]
#}
#output "endpoint" {
#  value = "${aws_eks_cluster.example.endpoint}"
#}
#
#output "kubeconfig-certificate-authority-data" {
#  value = "${aws_eks_cluster.example.certificate_authority.0.data}"
#}

#module "eks" {
#  source = "./modules/eks"
#
#  eks_cluster_name   = "superawesome"
#  region             = var.region
#  private_subnet_ids = [aws_subnet_ids.private.*.id]
#  public_subnet_ids  = [aws_subnet_ids.public.*.id]
#  vpc_id             = aws_vpc.id
#
#  # Default worker pool
#  eks_worker_ssh_key_name     = "eks-worker-ssh-key"
#  eks_worker_desired_capacity = "1"
#  eks_worker_max_size         = "1"
#  eks_worker_min_size         = "1"
#  eks_worker_public_ip_enable = "false"
#  eks_worker_instance_type    = "t2.nano"
#}
#
#module "test_pool" {
#  source = "./modules/eks//modules/eks-compute"
#
#  eks_cluster_name            = "superawesome"
#  eks_cluster_ca_data         = module.eks.eks_cluster_ca_data
#  eks_cluster_endpoint        = module.eks.eks_cluster_endpoint
#  eks_worker_max_pods         = "2"
#  eks_worker_ssh_key_name     = "eks-worker-ssh-key"
#  eks_worker_instance_type    = "t2.nano"
#  eks_worker_desired_capacity = "1"
#  eks_worker_max_size         = "1"
#  eks_worker_min_size         = "1"
#  eks_worker_instance_profile = module.eks.eks_node_instance_profile_name
#
#  eks_worker_group_name       = "test-pool"
#  eks_worker_sg_id            = module.eks.eks_node_sg_id
#  eks_worker_subnet_ids       = [aws_subnet_ids.private.*.id]
#  eks_worker_public_ip_enable = "false"
#  region                      = var.region
#}

