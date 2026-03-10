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

variable "secrets" {
  description = "Map of secrets to create"
  type = map(object({
    name            = string
    description     = string
    service_tag     = string
    enable_rotation = optional(bool, false)
   
    # For DB secrets that need password rotation
    is_db_secret    = optional(bool, false)
  }))
  default = {
    auth_jwt = {
      name        = "auth-service/jwt-secret"
      description = "JWT signing secret for auth service"
      service_tag = "auth"
      enable_rotation = false
    }
    auth_db = {
      name        = "auth-service/db-credentials"
      description = "Database credentials for auth service"
      service_tag = "auth"
      enable_rotation = true
      is_db_secret = true
    }
    patient_db = {
      name        = "patient-service/db-credentials"
      description = "Database credentials for patient service"
      service_tag = "patient"
      enable_rotation = true
      is_db_secret = true
    }
    api_gateway_jwt = {
      name        = "api-gateway/jwt-secret"
      description = "JWT secret for API Gateway validation"
      service_tag = "apigateway"
      enable_rotation = false
    }
  }
}