variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default = {
    owner = "krishna"
  }
}

variable "security_alert_email" {
    description = "sns subscription mail"
    type = string
}

variable "aws_region" {
  type = string
}

variable "cloudtrail_cloudwatch_role_arn" {
  type = string
}

variable "auto_revoke_lambda_arn" {
    type = string
  
}

variable "threshold_rapid_retrieval" {
    description = "Secrets threshold for alaram"
  type = string
  default = "10"
}

variable "threshold_failed_access" {
  description = ""
  type = string
  default = "5"
}
variable "rotation_lambda_arn" {
  type = string
}