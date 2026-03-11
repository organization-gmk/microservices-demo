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
  capacity_type  = each.value.capacity_type

  tags = merge(
    var.tags,
    {
      Name = "${each.value.name}-node-group"
    }
  )

  launch_template {
    name    = aws_launch_template.node_group[each.key].name
    version = "$Latest"
  }

  depends_on = [
    aws_eks_cluster.gmk_cluster
  ]
}

resource "aws_launch_template" "node_group" {
  for_each = var.node_groups

  name_prefix = "${each.value.name}-"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = each.value.disk_size
      volume_type = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${each.value.name}-node"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      {
        Name = "${each.value.name}-volume"
      }
    )
  }
}

#--------------EBS CSI Driver ----------------
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

#--------------Secrets CSI Driver----------------
# Secrets Store CSI Driver Addon
resource "aws_eks_addon" "secrets_store_csi" {
  cluster_name             = aws_eks_cluster.gmk_cluster.name
  addon_name               = "secrets-store-csi-driver"
  
 
  service_account_role_arn = var.csi_secrets_driver_role_arn
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
    aws_eks_node_group.gmk_node_group
  ]
}
#--------------AWS Load Balancer Controller----------------
resource "kubernetes_service_account_v1" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = var.aws_load_balancer_controller_arn
    }
  }
}

resource "kubernetes_namespace_v1" "app_namespace" {
  metadata {
    name = "patient-service"
  }
}


resource "kubernetes_service_account_v1" "patient_service_account" {
  metadata {
    name      = "patient-sa"
    namespace = "patient-service"

    annotations = {
      "eks.amazonaws.com/role-arn" = var.patient_irsa_role_arn
    }
  }
}


# ------------- Auth Service Account -------------
resource "kubernetes_service_account_v1" "auth_service" {


  depends_on = [kubernetes_namespace_v1.app_namespace]
  metadata {
    name      = "auth-service-sa"
    namespace = kubernetes_namespace_v1.app_namespace.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn"                 = var.auth_service_role_arn
      "eks.amazonaws.com/sts-regional-endpoints"   = "true"
      "eks.amazonaws.com/tags"                      = jsonencode({
        Service     = "auth"
        Environment = var.tags["Environment"]
      })
    }

    labels = {
      service     = "auth"
      Environment = var.tags["Environment"]
    }
  }

}

# ------------- Patient Service Account -------------
resource "kubernetes_service_account_v1" "patient_service" {
depends_on = [kubernetes_namespace_v1.app_namespace]

  metadata {
    name      = "patient-service-sa"
    namespace = kubernetes_namespace_v1.app_namespace.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn"                 = var.patient_service_role_arn
      "eks.amazonaws.com/sts-regional-endpoints"   = "true"
      "eks.amazonaws.com/tags"                      = jsonencode({
        Service     = "patient"
        Environment = var.tags["Environment"] 
      })
    }

    labels = {
      service     = "patient"
      Environment = var.tags["Environment"] 
    }
  }

 
}

# ------------- API Gateway Service Account -------------
resource "kubernetes_service_account_v1" "api_gateway_service" {
depends_on = [kubernetes_namespace_v1.app_namespace]

  metadata {
    name      = "api-gateway-sa"
    namespace = kubernetes_namespace_v1.app_namespace.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn"                 = var.api_gateway_role_arn
      "eks.amazonaws.com/sts-regional-endpoints"   = "true"
      "eks.amazonaws.com/tags"                      = jsonencode({
        Service     = "apigateway"
        Environment = var.tags["Environment"] 
      })
    }

    labels = {
      service     = "apigateway"
      Environment = var.tags["Environment"]
    }
  }


}