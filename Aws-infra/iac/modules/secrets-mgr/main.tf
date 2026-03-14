locals {
  # Define your secrets
  secrets = {
    auth_jwt = {
      name           = "auth-service/jwt-secret"
      description    = "JWT signing secret for auth service"
      service_tag    = "auth"
      enable_rotation = false  # JWT doesn't auto-rotate
    }
    auth_db = {
      name           = "auth-service/db-credentials"
      description    = "Database credentials for auth service"
      service_tag    = "auth"
      enable_rotation = true   # DB rotates
    }
    patient_db = {
      name           = "patient-service/db-credentials"
      description    = "Database credentials for patient service"
      service_tag    = "patient"
      enable_rotation = true   # DB rotates
    }
    api_gateway_jwt = {
      name           = "api-gateway/jwt-secret"
      description    = "JWT secret for API Gateway"
      service_tag    = "apigateway"
      enable_rotation = false  # JWT doesn't auto-rotate
    }
  }
  
  rotation_enabled_secrets = {
    for k, v in local.secrets : k => v
    if v.enable_rotation == true
  }
}

data "aws_secretsmanager_secret" "auth_jwt" {
  name = "auth-service/jwt-secret"
}

data "aws_secretsmanager_secret" "auth_db" {
  name = "auth-service/db-credentials"
}

data "aws_secretsmanager_secret" "patient_db" {
  name = "patient-service/db-credentials"
}

data "aws_secretsmanager_secret" "api_gateway_jwt" {
  name = "api-gateway/jwt-secret"
}


resource "aws_secretsmanager_secret_rotation" "auth_db_rotation" {
  count = local.rotation_enabled_secrets["auth_db"] ? 1 : 0
  
  secret_id           = data.aws_secretsmanager_secret.auth_db.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation.arn
  
  rotation_rules {
    automatically_after_days = 30
  }
}

resource "aws_secretsmanager_secret_rotation" "patient_db_rotation" {
  count = local.rotation_enabled_secrets["patient_db"] ? 1 : 0
  
  secret_id           = data.aws_secretsmanager_secret.patient_db.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation.arn
  
  rotation_rules {
    automatically_after_days = 30
  }
}