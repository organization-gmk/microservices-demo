locals {
  # Define your secrets
  secrets = {
    auth_jwt = {
      name           = "auth-service/jwt-secret"
      description    = "JWT signing secret for auth service"
      service_tag    = "auth"
      enable_rotation = false  
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
      enable_rotation = false  
    }
  }
  
  rotation_enabled_secrets = {
    for k, v in local.secrets : k => v
    if v.enable_rotation == true
  }
}

resource "aws_secretsmanager_secret" "secrets" {
  for_each = local.secrets
  
  name        = each.value.name
  description = each.value.description
  
  # Protect against accidental deletion
  recovery_window_in_days = 7
  
  tags = merge(var.tags, {
    Service  = each.value.service_tag
    Rotation = each.value.enable_rotation ? "enabled" : "disabled"
    ManagedBy = "terraform"
  })
}

# Enable rotation for database credentials
resource "aws_secretsmanager_secret_rotation" "auth_db_rotation" {
  count = local.secrets["auth_db"].enable_rotation ? 1 : 0
  
  secret_id           = aws_secretsmanager_secret.secrets["auth_db"].id
  rotation_lambda_arn = aws_lambda_function.secret_rotation.arn
  
  rotation_rules {
    automatically_after_days = 30
  }
}

resource "aws_secretsmanager_secret_rotation" "patient_db_rotation" {
  count = local.secrets["patient_db"].enable_rotation ? 1 : 0
  
  secret_id           = aws_secretsmanager_secret.secrets["patient_db"].id
  rotation_lambda_arn = aws_lambda_function.secret_rotation.arn
  
  rotation_rules {
    automatically_after_days = 30
  }
}