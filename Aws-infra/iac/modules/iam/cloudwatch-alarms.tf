# ##############################################################################################
# # CLOUDWATCH FOR SECRET EXFILTRATION DETECTION
# ##############################################################################################

# # CloudWatch Log Group for CloudTrail
# resource "aws_cloudwatch_log_group" "secrets_audit" {
#   name              = "/aws/cloudtrail/secrets-audit"
#   retention_in_days = 90
  
#   tags = var.tags
# }

# # CloudWatch metric filter for secret retrieval
# resource "aws_cloudwatch_log_metric_filter" "secret_retrieval" {
#   name           = "${var.name_prefix}-secret-retrieval"
#   pattern        = "{ ($.eventSource = \"secretsmanager.amazonaws.com\") && ($.eventName = \"GetSecretValue\") }"
#   log_group_name = aws_cloudwatch_log_group.secrets_audit.name

#   metric_transformation {
#     name      = "SecretRetrievalCount"
#     namespace = "Security/SecretsManager"
#     value     = "1"
#     default_value = "0"
#   }
# }

# # CloudWatch alarm for bulk secret retrieval (potential exfiltration)
# resource "aws_cloudwatch_metric_alarm" "secret_exfiltration" {
#   alarm_name          = "${var.name_prefix}-secret-exfiltration-alarm"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "SecretRetrievalCount"
#   namespace           = "Security/SecretsManager"
#   period              = "300"  # 5 minutes
#   statistic           = "Sum"
#   threshold           = "5"   # Alert if 5+ secrets retrieved in 5 minutes
#   alarm_description   = "Alert on potential secret exfiltration - 5+ secrets retrieved in 5 minutes"
#   alarm_actions       = [aws_sns_topic.security_alerts.arn]
#   ok_actions          = [aws_sns_topic.security_alerts.arn]

#   tags = var.tags
# }

# # SNS Topic for security alerts
# resource "aws_sns_topic" "security_alerts" {
#   name = "${var.name_prefix}-security-alerts"

#   tags = var.tags
# }

# # SNS Topic subscription for email alerts
# resource "aws_sns_topic_subscription" "security_alerts_email" {
#   topic_arn = aws_sns_topic.security_alerts.arn
#   protocol  = "email"
#   endpoint  = "gmkrishna097@gmail.com"
# }