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

module "ecs" {
  source = "./modules/ecs"
  name = "superawesome"
  container_name = "superawesome"
  vpc_id = module.vpc.vpc_id
  cidr_blocks   = module.vpc.public_subnets_cidr_blocks
  subnets            = module.vpc.public_subnets
  from_port = 80
  to_port = 80
  listener_url = "www.example.com"
  family = "hello-world"
  azs = "us-west-2a, us-west-2b"
  subnet_ids = module.vpc.public_subnets
}


##########################
###### CIRCLECI STUFF#####
##########################

resource "aws_ecr_repository" "superawesome" {
  name = "superawesome"
}

resource "aws_iam_group" "clientci" {
  name = "clientci"
  path = "/"
}

resource "aws_iam_policy" "clientci_ecs_service_policy" {
  name = "clientci_ecs_service_role_policy"
  path        = "/"
  policy = file("policies/clientci_ecs_policy.json")
}

resource "aws_iam_policy" "clientci_ecr_service_policy" {
  name = "clientci_ecr_service_policy"
  policy = file("policies/clientci_ecr_policy.json")
  path        = "/"
}

resource "aws_iam_group_policy_attachment" "clientci_ecr_attach" {
  group      = aws_iam_group.clientci.name
  policy_arn = aws_iam_policy.clientci_ecr_service_policy.arn
}

resource "aws_iam_group_policy_attachment" "clientci_ecs_attach" {
  group      = aws_iam_group.clientci.name
  policy_arn = aws_iam_policy.clientci_ecs_service_policy.arn
}

resource "aws_iam_user" "clientci" {
  name = "clientci"
}

resource "aws_iam_user_group_membership" "clientci" {
  user = aws_iam_user.clientci.name

  groups = [
    aws_iam_group.clientci.name,
  ]
}

##########################