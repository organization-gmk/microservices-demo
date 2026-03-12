# Detailed map of all secrets
output "secret_names" {
  description = "Detailed map of secret keys with name and ARN"
  value = {
    for k, secret in aws_secretsmanager_secret.secrets : k => {
      name = secret.name
      arn  = secret.arn
      id   = secret.id
    }
  }
}

# Simple ARN map (most commonly used)
output "secret_arns" {
  description = "Map of secret keys to ARNs"
  value = {
    for k, secret in aws_secretsmanager_secret.secrets : k => secret.arn
  }
}

# Secret IDs map
output "secret_ids" {
  description = "Map of secret keys to IDs"
  value = {
    for k, secret in aws_secretsmanager_secret.secrets : k => secret.id
  }
}

# Individual outputs for backward compatibility
output "auth_jwt_secret_arn" {
  description = "ARN of auth service JWT secret"
  value       = aws_secretsmanager_secret.secrets["auth_jwt"].arn
}

output "auth_db_secret_arn" {
  description = "ARN of auth service database credentials"
  value       = aws_secretsmanager_secret.secrets["auth_db"].arn
}

output "patient_db_secret_arn" {
  description = "ARN of patient service database credentials"
  value       = aws_secretsmanager_secret.secrets["patient_db"].arn
}

output "api_gateway_jwt_secret_arn" {
  description = "ARN of API Gateway JWT secret"
  value       = aws_secretsmanager_secret.secrets["api_gateway_jwt"].arn
}

# Lambda outputs
output "rotation_lambda_arn" {
  description = "ARN of the secret rotation Lambda function"
  value       = aws_lambda_function.secret_rotation.arn
}

output "rotation_lambda_role_arn" {
  description = "ARN of the Lambda rotation role"
  value       = aws_iam_role.rotation_lambda_role.arn
}

# Mapping of original names to actual names (helpful for reference)
output "original_name_mapping" {
  description = "Mapping of original secret names to actual names with timestamps"
  value = {
    for k, secret in aws_secretsmanager_secret.secrets : k => {
      original_name = var.secrets[k].name
      actual_name   = secret.name
      arn          = secret.arn
    }
  }
}