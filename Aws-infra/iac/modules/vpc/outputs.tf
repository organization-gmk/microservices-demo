output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.gmk-vpc.id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "cluster_sg_id" {
  description = "ID of the cluster security group"
  value       = aws_security_group.cluster.id
}

output "nodes_security_group_id" {
  description = "ID of the nodes security group"
  value       = aws_security_group.nodes.id
}