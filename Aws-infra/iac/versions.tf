terraform {
  required_version = ">= 1.5"

  backend "s3" {
    # Placeholders - real values come from backend config file
    bucket         = "placeholder"
    key            = "placeholder"
    region         = "placeholder"
    encrypt        = true
    dynamodb_table = "placeholder"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

  }
}