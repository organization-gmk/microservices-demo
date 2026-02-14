resource "aws_eks_cluster" "gmk_cluster" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = var.cluster_iam_role_arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [var.cluster_sg_id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = var.cluster_log_types

  tags = var.tags


}

#---------------Node Group-----------------
resource "aws_eks_node_group" "gmk_node_group" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.gmk_cluster.name
  node_group_name = each.value.name
  node_role_arn   = var.node_iam_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  instance_types = each.value.instance_types
  ami_type       = each.value.ami_type
  disk_size      = each.value.disk_size
  capacity_type  = each.value.capacity_type

  tags = merge(
    var.tags,
    {
      Name = "${each.value.name}-node"
    }
  )

  depends_on = [
    aws_eks_cluster.gmk_cluster
  ]
}

#--------------EBS CSI Driver IAM Role----------------
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.gmk_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.ebs_addon_version
  service_account_role_arn = var.ebs_csi_driver_role

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [
    aws_eks_node_group.gmk_node_group
  ]
}
#--------------ClowdWatch Agent & Fluent Bit----------------
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name             = aws_eks_cluster.gmk_cluster.name
  addon_name               = "amazon-cloudwatch-observability"
  service_account_role_arn = var.cloudwatch_agent_role

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [
    aws_eks_node_group.gmk_node_group,
    aws_iam_role_policy_attachment.cw_observability
  ]
}
#--------------AWS Load Balancer Controller----------------
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = var.aws_load_balancer_controller_arn
    }
  }
}
