resource "aws_cloudtrail" "secrets_audit" {
  name                          = "${var.name_prefix}-secrets-audit-trail"
  s3_bucket_name                = aws_s3_bucket.audit_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = var.cloudtrail_cloudwatch_role_arn

  # Enable data events for Secrets Manager
   advanced_event_selector {
    name = "SecretsManagerEvents"
    
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]  # For Secrets Manager, use "Data" as eventCategory
    }
    
   field_selector {
      field  = "eventName"
      equals = [
        "GetSecretValue",
        "DescribeSecret",
        "ListSecrets"
      ]
    }
     field_selector {
      field  = "readOnly"
      equals = ["true"]
    }
   }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-secrets-audit-trail"
  })
}

