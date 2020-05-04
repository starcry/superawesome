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
  to_port = 8080
  listener_url = "www.example.com"
  family = "hello-world"
  azs = "us-west-2a, us-west-2b"
}



#module "eks_cluster" {
#  source = "./modules/eks"
#  cluster_name = "superawesome"
#  eks_role = "superawesome_cluster"
#  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
#}
