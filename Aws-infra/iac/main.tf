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