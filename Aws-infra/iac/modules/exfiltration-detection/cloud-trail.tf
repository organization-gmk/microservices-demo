resource "aws_cloudtrail" "secrets_audit" {
  name                          = "${var.name_prefix}-secrets-audit-trail"
  s3_bucket_name                = aws_s3_bucket.audit_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch.arn

  # Enable data events for Secrets Manager
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::SecretsManager::Secret"
      values = ["arn:aws:secretsmanager:*:*:secret:*"]
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-secrets-audit-trail"
  })
}

