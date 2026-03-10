output "secret_arns" {
  description = "Map of secret keys to ARNs"
  value = {
    for k, secret in aws_secretsmanager_secret.secrets : k => secret.arn
  }
}

output "secret_ids" {
  description = "Map of secret keys to IDs"
  value = {
    for k, secret in aws_secretsmanager_secret.secrets : k => secret.id
  }
}

# Individual outputs for backward compatibility
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

output "rotation_lambda_arn" {
  value = aws_lambda_function.secret_rotation.arn
}

output "rotation_lambda_role_arn" {
  value = aws_iam_role.rotation_lambda_role.arn
}