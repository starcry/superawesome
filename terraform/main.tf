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
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_iam_role" "example" {
  name = "superawesome"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.example.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.example.name
}

module "eks" {
  source = "./modules/eks"

  eks_cluster_name                    = "superawesome"
  region                              = var.region
  private_subnet_ids                  = ["${aws_subnet_ids.private.*.id}"]
  public_subnet_ids                   = ["${aws_subnet_ids.public.*.id}"]
  vpc_id                              = "${aws_vpc.id}"

  # Default worker pool
  eks_worker_ssh_key_name             = "eks-worker-ssh-key"
  eks_worker_desired_capacity         = "1"
  eks_worker_max_size                 = "1"
  eks_worker_min_size                 = "1"
  eks_worker_public_ip_enable         = "false"
  eks_worker_instance_type    = "t2.nano"

}

module "test_pool" {
  source = "./modules/eks//modules/eks-compute"

  eks_cluster_name            = "superawesome"
  eks_cluster_ca_data         = "${module.eks.eks_cluster_ca_data}"
  eks_cluster_endpoint        = "${module.eks.eks_cluster_endpoint}"
  eks_worker_max_pods         = "2"
  eks_worker_ssh_key_name     = "eks-worker-ssh-key"
  eks_worker_instance_type    = "t2.nano"
  eks_worker_desired_capacity = "1"
  eks_worker_max_size         = "1"
  eks_worker_min_size         = "1"
  eks_worker_instance_profile = "${module.eks.eks_node_instance_profile_name}"

  eks_worker_group_name       = "test-pool"
  eks_worker_sg_id            = "${module.eks.eks_node_sg_id}"
  eks_worker_subnet_ids       = ["${aws_subnet_ids.private.*.id}"]
  eks_worker_public_ip_enable = "false"
  region                      = var.region
}

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
