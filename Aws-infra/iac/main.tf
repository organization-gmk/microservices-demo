module "vpc" {
  source = "./modules/vpc"

  name_prefix            = local.name_prefix
  vpc_cidr               = var.vpc_cidr
  azs                    = local.azs
  project_name           = var.project_name
  enable_nat_gateway     = true
  one_nat_gateway_per_az = false
  tags = local.common_tags
}

module "iam" {
  source = "./modules/iam"

  name_prefix       = local.name_prefix
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
 

  tags = local.common_tags
}

module "eks" {
  source = "./modules/eks"

  name_prefix            = local.name_prefix
  cluster_version        = var.cluster_version
  cluster_iam_role_arn  = module.iam.cluster_iam_role_arn
  subnet_ids            = module.vpc.private_subnet
  cluster_sg_id         = module.vpc.cluster_sg_id
  cluster_log_types     = var.cluster_log_types
  ebs_csi_driver_role   = module.iam.ebs_csi_driver_role_arn
  ebs_addon_version     = var.ebs_addon_version
  node_iam_role_arn     = module.iam.node_iam_role_arn
  node_groups           = var.node_groups
  cloudwatch_agent_role = module.iam.cloudwatch_agent_role_arn
  aws_load_balancer_controller_arn = module.iam.aws_load_balancer_controller_arn
  
  tags                  = local.common_tags

 
}