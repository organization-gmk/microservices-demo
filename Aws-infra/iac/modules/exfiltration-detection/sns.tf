resource "aws_sns_topic" "security_alerts" {
  name = "${var.name_prefix}-security-alerts"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-security-alerts"
  })
}

# Email subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.security_alert_email
}

# Slack webhook subscription (optional)
# resource "aws_sns_topic_subscription" "slack" {
#   count      = var.slack_webhook_url != "" ? 1 : 0
#   topic_arn  = aws_sns_topic.security_alerts.arn
#   protocol   = "https"
#   endpoint   = var.slack_webhook_url
# }