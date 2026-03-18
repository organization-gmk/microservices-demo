output "sns_security_alerts_arn" {
    value = aws_sns_topic.security_alerts.arn
  
}
output "cw_log_groupcloudtrail_arn" {
  value = aws_cloudwatch_log_group.cloudtrail.arn
}