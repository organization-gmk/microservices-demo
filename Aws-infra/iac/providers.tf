provider "aws" {
  region = var.aws_region
}



data "aws_eks_cluster" "gmk-cluster" {
  name = local.cluster_name
  depends_on = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "gmk-cluster" {
  name = local.cluster_name
  depends_on = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.gmk-cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.gmk-cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.gmk-cluster.token

  exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        data.aws_eks_cluster.gmk-cluster.name
      ]
    }
}



