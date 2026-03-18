variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {

    owner = "krishna"
  }
}
variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA)"
  type        = bool
  default     = true
}
variable "oidc_provider_url" {
  description = "OIDC Provider URL for the EKS cluster"
  type        = string

}

variable "ecr_repository_names" {
    type = list(string)
    default = [ "micro-services/analytics-service", "micro-services/api-gateway", "micro-services/auth-service", "micro-services/billing-service", "micro-services/patient-service" ]
  
}

variable "service_accounts" {
  description = "Map of service accounts and their configurations"
  type = map(object({
    namespace       = string
    service_account = string
    service_tag     = string
    # Optional: Add custom policies per service
    policy_arns     = optional(list(string), [])
  }))
  default = {
    auth = {
      namespace       = "patient-service"
      service_account = "auth-service-sa"
      service_tag     = "auth"
    }
    patient = {
      namespace       = "patient-service"
      service_account = "patient-service-sa"
      service_tag     = "patient"
    }
    api-gateway = {
      namespace       = "patient-service"
      service_account = "api-gateway-sa"
      service_tag     = "apigateway"
    }
    
  }
}

variable "sns_security_alerts_arn" {
  type = string
}