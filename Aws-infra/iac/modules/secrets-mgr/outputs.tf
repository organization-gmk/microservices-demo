output "secret_arns" {
  value = {
    for k, secret in aws_secretsmanager_secret.secrets : k => secret.arn
  }
}

# Secret names (full names with suffixes)
output "secret_names" {
  value = {
    for k, secret in aws_secretsmanager_secret.secrets : k => secret.name
  }
}

# Secret IDs
output "secret_ids" {
  description = "Map of secret keys to IDs"
  value = {
    for k, secret in aws_secretsmanager_secret.secrets : k => secret.id
  }
}

# Individual outputs
output "auth_jwt_secret_arn" {
  value = aws_secretsmanager_secret.secrets["auth_jwt"].arn
}

output "auth_db_secret_arn" {
  value = aws_secretsmanager_secret.secrets["auth_db"].arn
}

output "patient_db_secret_arn" {
  value = aws_secretsmanager_secret.secrets["patient_db"].arn
}

output "api_gateway_jwt_secret_arn" {
  value = aws_secretsmanager_secret.secrets["api_gateway_jwt"].arn
}

output "auth_jwt_secret_name" {
  value = aws_secretsmanager_secret.secrets["auth_jwt"].name
}

output "auth_db_secret_name" {
  value = aws_secretsmanager_secret.secrets["auth_db"].name
}

output "patient_db_secret_name" {
  value = aws_secretsmanager_secret.secrets["patient_db"].name
}

output "api_gateway_jwt_secret_name" {
  value = aws_secretsmanager_secret.secrets["api_gateway_jwt"].name
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