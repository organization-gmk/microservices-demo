data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {

  name_prefix = "${var.project_name}"
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  
  # Common tags
  common_tags = merge({
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }, var.tags)

  cluster_name = "${local.name_prefix}-cluster"

}


