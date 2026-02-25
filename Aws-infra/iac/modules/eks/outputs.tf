output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.gmk_cluster.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.gmk_cluster.arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.gmk_cluster.endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = aws_eks_cluster.gmk_cluster.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = aws_eks_cluster.gmk_cluster.identity[0].oidc[0].issuer
}