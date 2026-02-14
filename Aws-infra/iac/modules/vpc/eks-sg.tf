resource "aws_security_group" "cluster" {
  name        = "${var.name_prefix}-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = aws_vpc.gmk-vpc.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cluster-sg"
  })
}

resource "aws_security_group" "nodes" {
  name        = "${var.name_prefix}-nodes-sg"
  description = "EKS node security group"
  vpc_id      = aws_vpc.gmk-vpc.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nodes-sg"
  })
}

resource "aws_security_group_rule" "cluster_ingress_nodes" {
  description              = "Allow nodes to communicate with cluster"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.nodes.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "nodes_ingress_cluster" {
  description              = "Allow cluster to communicate with nodes"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.cluster.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "nodes_ingress_self" {
  description       = "Allow nodes to communicate with each other"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  security_group_id = aws_security_group.nodes.id
  self              = true
  type              = "ingress"
}