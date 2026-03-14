output "secret_arns" {
  value = {
    auth_jwt    = data.aws_secretsmanager_secret.auth_jwt.arn
    auth_db     = data.aws_secretsmanager_secret.auth_db.arn
    patient_db  = data.aws_secretsmanager_secret.patient_db.arn
    api_gateway = data.aws_secretsmanager_secret.api_gateway_jwt.arn
  }
}

output "secret_names" {
  value = {
    auth_jwt    = data.aws_secretsmanager_secret.auth_jwt.name
    auth_db     = data.aws_secretsmanager_secret.auth_db.name
    patient_db  = data.aws_secretsmanager_secret.patient_db.name
    api_gateway = data.aws_secretsmanager_secret.api_gateway_jwt.name
  }
}
output "secret_ids" {
  description = "Map of secret keys to IDs"
  value = {
    auth_jwt    = data.aws_secretsmanager_secret.auth_jwt.id
    auth_db     = data.aws_secretsmanager_secret.auth_db.id
    patient_db  = data.aws_secretsmanager_secret.patient_db.id
    api_gateway = data.aws_secretsmanager_secret.api_gateway_jwt.id
  }
}

# Individual outputs for backward compatibility
output "auth_jwt_secret_arn" {
  description = "ARN of auth service JWT secret"
  value       = aws_secretsmanager_secret.secrets["auth_jwt"].arn
}

# output "auth_db_secret_arn" {
#   description = "ARN of auth service database credentials"
#   value       = aws_secretsmanager_secret.secrets["auth_db"].arn
# }

# output "patient_db_secret_arn" {
#   description = "ARN of patient service database credentials"
#   value       = aws_secretsmanager_secret.secrets["patient_db"].arn
# }

# output "api_gateway_jwt_secret_arn" {
#   description = "ARN of API Gateway JWT secret"
#   value       = aws_secretsmanager_secret.secrets["api_gateway_jwt"].arn
# }

# Lambda outputs
output "rotation_lambda_arn" {
  description = "ARN of the secret rotation Lambda function"
  value       = aws_lambda_function.secret_rotation.arn
}

output "rotation_lambda_role_arn" {
  description = "ARN of the Lambda rotation role"
  value       = aws_iam_role.rotation_lambda_role.arn
}

output "auth_jwt_secret_arn" {
  value = data.aws_secretsmanager_secret.auth_jwt.arn
}

output "auth_db_secret_arn" {
  value = data.aws_secretsmanager_secret.auth_db.arn
}

output "patient_db_secret_arn" {
  value = data.aws_secretsmanager_secret.patient_db.arn
}

output "api_gateway_jwt_secret_arn" {
  value = data.aws_secretsmanager_secret.api_gateway_jwt.arn
}

output "auth_jwt_secret_name" {
  value = data.aws_secretsmanager_secret.auth_jwt.name
}

output "auth_db_secret_name" {
  value = data.aws_secretsmanager_secret.auth_db.name
}

output "patient_db_secret_name" {
  value = data.aws_secretsmanager_secret.patient_db.name
}

output "api_gateway_jwt_secret_name" {
  value = data.aws_secretsmanager_secret.api_gateway_jwt.name
}
