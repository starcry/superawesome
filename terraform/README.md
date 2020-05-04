# terraform code

### prerequisists
you will need the following environment variables, I recomend adding them to your bashrc
```
TF_VAR_access=<your aws access id key>
TF_VAR_secret=<your aws secret access id key>
```

you should be able to just run terraform apply and it should work

## EKS and K8S
Although not directly related to the project I included it because it was easy, here's an example on how to run the module
```yaml
module "eks_cluster" {
  source = "./modules/eks"
  cluster_name = "superawesome"
  eks_role = "superawesome_cluster"
  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
}
```