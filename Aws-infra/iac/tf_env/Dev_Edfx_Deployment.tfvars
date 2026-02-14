aws_region   = "us-east-2"
vpc_cidr      = "10.0.0.0/16"
project_name  = "microservices"
environment   = "dev"
cluster_version = "1.33"
ebs_addon_version = "v1.53.0-eksbuild.1"


node_groups = {
  example-node-group = {
    name           = "ecomm-uat-node-group"
    desired_size   = 2
    min_size       = 1
    max_size       = 3
    instance_types = ["t3.medium"]
    ami_type       = "AL2023_x86_64_STANDARD"
    disk_size      = 20
    capacity_type  = "ON_DEMAND"

    labels = {
      role = "worker"
    }
  }
}