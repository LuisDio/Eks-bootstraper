data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

module "vpc" {
  source               = "../../modules/vpc"
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  cluster_name         = var.cluster_name
}

module "eks" {
  source          = "../../modules/eks"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  node_groups     = var.node_groups
}

module "argocd" {
  depends_on      = [module.eks]
  source          = "../../modules/argocd"
  argo_namespace  = var.argo_namespace
  argo_name       = var.argo_name
  argo_chart      = var.argo_chart
  argo_repository = var.argo_repository
  argo_version    = var.argo_version
  argo_values = [
    file("${path.root}/configs/argo-values.yaml")
  ]

}
