variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

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

