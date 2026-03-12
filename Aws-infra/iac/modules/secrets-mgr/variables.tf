variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {

    owner = "krishna"
  }
}

variable "aws_region" {
  description = "AWS region for Secrets Manager endpoint"
  type        = string
 
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

# variables.tf
variable "secrets" {
  description = "Secrets configuration"
  type = map(object({
    name           = string
    description    = string
    service_tag    = string
    enable_rotation = bool
  }))
  default = {
    auth_jwt = {
      name           = "auth-service/jwt-secret"
      description    = "JWT signing secret for auth service"
      service_tag    = "auth"
      enable_rotation = false  # JWT secrets shouldn't auto-rotate
    }
    auth_db = {
      name           = "auth-service/db-credentials"
      description    = "Database credentials for auth service"
      service_tag    = "auth"
      enable_rotation = true   # DB passwords should rotate
    }
    patient_db = {
      name           = "patient-service/db-credentials"
      description    = "Database credentials for patient service"
      service_tag    = "patient"
      enable_rotation = true
    }
    api_gateway_jwt = {
      name           = "api-gateway/jwt-secret"
      description    = "JWT secret for API Gateway"
      service_tag    = "apigateway"
      enable_rotation = false
    }
  }
}