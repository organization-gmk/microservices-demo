output "cluster_name" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.gmk-cluster.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.gmk-cluster.arn
}