##############################################################################################
resource "aws_iam_role" "cluster" {
  name = "${var.name_prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "aws_cloudwatch_log_groups" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.cluster.name
}

##############################################################################################

resource "aws_iam_role" "node" {
  name = "${var.name_prefix}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

########################CUSTOM-POLICIES#####################################################
data "aws_ecr_repository" "microservices_repos" {
  for_each = toset(var.ecr_repository_names)
  name     = each.value
}

resource "aws_iam_policy" "eks_ecr_access_policy" {
  name        = "EKSECRAccessPolicy"
  description = "Allow EKS workloads to pull images from private ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = [
            for repo in data.aws_ecr_repository.microservices_repos :
            repo.arn
        ]
      },
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_ecr_access_policy_attachment" {
  policy_arn = aws_iam_policy.eks_ecr_access_policy.arn
  role       = aws_iam_role.node.name
}

# resource "aws_iam_role" "eks_ecr_access_role" {
#   name = "eks-ecr-access-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.eks[0].arn
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringEquals = {
#             "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:default:ecr-pull-sa"
#           }
#         }
#       }
#     ]
#   })
# }


########################EBS-CSI-DRIVER-POLICY#####################################################
data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.name_prefix}-ebs-csi-driver-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}


##################OIDC-EKS#######################################################
resource "aws_iam_openid_connect_provider" "eks" {

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  url             = var.oidc_provider_url
}
data "tls_certificate" "oidc" {
  
  url   = var.oidc_provider_url
}
###############################################################################################
# IAM Role for RDS Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

########################################################################################
# AWS Load Balancer Controller IAM Policy
resource "aws_iam_policy" "alb_ingress_controller" {
  name        = "${var.name_prefix}-ALBIngressControllerPolicy"
  description = "Policy for AWS Load Balancer Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:AddTags",  
          "elasticloadbalancing:RemoveTags", 
          "elasticloadbalancing:SetIpAddressType", 
          "elasticloadbalancing:SetSecurityGroups",  
          "elasticloadbalancing:SetSubnets", 
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:CreateListenerCertificates",
          "elasticloadbalancing:DeleteListenerCertificates",
          "elasticloadbalancing:DescribeListenerAttributes",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection",
          "ec2:DescribeTags",
          "ec2:CreateSecurityGroup",     
          "ec2:CreateTags",               
          "ec2:DeleteSecurityGroup",     
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",    
          "ec2:DeleteTags"

        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name  = "${var.name_prefix}-aws-load-balancer-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.alb_ingress_controller.arn
}


########################################################################################

##############################################################################################
resource "aws_iam_role" "cw_observability" {
  name = "${var.name_prefix}-cw-observability-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cw_observability" {
  role       = aws_iam_role.cw_observability.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

########################Secrets-CSI-DRIVER-POLICY#####################################################
resource "aws_iam_role" "secrets_store_csi_driver_role" {
  name = "${var.name_prefix}-secrets-store-csi-driver-role"
  
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn 
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:secrets-store-csi-driver-sa"
            "${replace(var.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Service = "csi-driver"
    RoleType = "addon"
  })
}

# Minimal policy for CSI driver to operate (NO secret access!)
resource "aws_iam_policy" "secrets_store_csi_driver_policy" {
  name        = "${var.name_prefix}-secrets-store-csi-driver-policy"
  description = "Minimal policy for Secrets Store CSI driver to operate"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "*"
      }
      
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_store_csi_driver_attach" {
  role       = aws_iam_role.secrets_store_csi_driver_role.name
  policy_arn = aws_iam_policy.secrets_store_csi_driver_policy.arn
}



#############PATIENT-NAMESPACE-IRSA-ROLE############################
resource "aws_iam_policy" "patient_secrets_policy" {
  name = "${var.name_prefix}-patient-secrets-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/App" = "patient-service"
          }
        }
      }
    ]
  })
}


data "aws_iam_policy_document" "patient_irsa_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:patient-service:patient-sa"]
    }
  }
}

resource "aws_iam_role" "patient_irsa_role" {
  name               = "${var.name_prefix}-patient-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.patient_irsa_assume_role.json
}

resource "aws_iam_role_policy_attachment" "patient_secrets_attach" {
  role       = aws_iam_role.patient_irsa_role.name
  policy_arn = aws_iam_policy.patient_secrets_policy.arn
}
##############################################################################################
# IRSA ASSUME ROLE POLICY MODULE - ONE FOR EACH SERVICE ACCOUNT
##############################################################################################
locals {
  oidc_sub_prefix = replace(var.oidc_provider_url, "https://", "")
}

# ABAC Policy - allows access only if tags match
resource "aws_iam_policy" "abac_secrets_policy" {
  name        = "${var.name_prefix}-abac-secrets-policy"
  description = "ABAC policy for secrets access based on tags"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccessBasedOnTags"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Service"     = "$${aws:PrincipalTag/Service}"
            "aws:ResourceTag/Environment" = "$${aws:PrincipalTag/Environment}"
          }
        }
      },
      {
        Sid    = "DenyCrossEnvironmentAccess"
        Effect = "Deny"
        Action = "secretsmanager:GetSecretValue"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:ResourceTag/Environment" = "$${aws:PrincipalTag/Environment}"
          }
        }
      }
    ]
  })
}


# Single module for all IRSA roles
resource "aws_iam_role" "irsa_roles" {
  for_each = var.service_accounts
  
  name               = "${var.name_prefix}-${each.key}-role"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role[each.key].json
  
  tags = merge(var.tags, {
    Service  = each.value.service_tag
    RoleType = "irsa"
  })
}

# Dynamic assume role policies
data "aws_iam_policy_document" "irsa_assume_role" {
  for_each = var.service_accounts
  
  statement {
    effect  = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
      "sts:TagSession"
    ]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_sub_prefix}:sub"
      values   = ["system:serviceaccount:${each.value.namespace}:${each.value.service_account}"]
    }
    
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_sub_prefix}:aud"
      values   = ["sts.amazonaws.com"]
    }
    
    condition {
      test     = "StringEquals"
      variable = "sts:RequestTag/Environment"
      values   = [lookup(var.tags, "Environment", "dev")]
    }
    
    condition {
      test     = "StringEquals"
      variable = "sts:RequestTag/Service"
      values   = [each.value.service_tag]
    }
  }
}

# Attach ABAC policy to all roles
resource "aws_iam_role_policy_attachment" "abac_attach" {
  for_each   = var.service_accounts
  role       = aws_iam_role.irsa_roles[each.key].name
  policy_arn = aws_iam_policy.abac_secrets_policy.arn
}
