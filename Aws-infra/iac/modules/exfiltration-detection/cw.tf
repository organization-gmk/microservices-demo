#---------------------------------------------------------------------
# CLOUDWATCH ALARMS (EXFILTRATION DETECTION)
#---------------------------------------------------------------------

# Alarm #1: Rapid secret retrieval (SIMPLE THRESHOLD)
resource "aws_cloudwatch_metric_alarm" "rapid_retrieval" {
  alarm_name          = "${var.name_prefix}-rapid-retrieval-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecretRetrievalCount"
  namespace           = "Security/SecretsManager"
  period              = "300"  # 5 minutes
  statistic           = "Sum"
  threshold           = var.threshold_rapid_retrieval  # 3+ retrievals for testing (change to 20 for production)
  alarm_description   = "POSSIBLE EXFILTRATION: ${var.threshold_rapid_retrieval} secrets retrieved in 5 minutes"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  ok_actions          = [aws_sns_topic.security_alerts.arn]
  
  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-rapid-retrieval-alarm"
    Severity    = "CRITICAL"
    Response    = "auto-revoke"
  })
}

# Alarm #2: Unusual number of distinct secrets (ANOMALY DETECTION)
resource "aws_cloudwatch_metric_alarm" "unusual_pattern" {
  alarm_name          = "${var.name_prefix}-unusual-pattern-alarm"
  comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
  evaluation_periods  = "2"
  threshold_metric_id = "ad1"
  alarm_description   = "ANOMALY DETECTED: Unusual pattern in secret access"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  ok_actions          = [aws_sns_topic.security_alerts.arn]
  insufficient_data_actions = []

  # First metric query - the actual data
  metric_query {
    id          = "m1"
    return_data = true
    metric {
      metric_name = "DistinctSecretsAccessed"
      namespace   = "Security/SecretsManager"
      period      = "300"
      stat        = "Sum"
    }
  }

  # Second metric query - anomaly detection band
  metric_query {
    id          = "ad1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
    label       = "DistinctSecretsAccessed (expected range)"
    return_data = true
  }

  tags = var.tags
}

# Alarm #3: Failed access attempts (SIMPLE THRESHOLD)
resource "aws_cloudwatch_metric_alarm" "failed_access_alarm" {
  alarm_name          = "${var.name_prefix}-failed-access-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedSecretAccess"
  namespace           = "Security/SecretsManager"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.threshold_failed_access   # 5+ failed attempts
  alarm_description   = "Multiple failed secret access attempts (${var.threshold_failed_access}+ in 5 minutes)"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.name_prefix}-secrets-audit"
  retention_in_days = 90

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cloudtrail-logs"
  })
}

#---------------------------------------------------------------------
# CLOUDWATCH DASHBOARD
#---------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "security_dashboard" {
  dashboard_name = "${var.name_prefix}-security-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["Security/SecretsManager", "SecretRetrievalCount", { stat = "Sum", label = "Secret Retrievals" }],
            ["Security/SecretsManager", "FailedSecretAccess", { stat = "Sum", label = "Failed Attempts" }],
            ["Security/SecretsManager", "DistinctSecretsAccessed", { stat = "Sum", label = "Distinct Secrets" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Secret Access Metrics (Last 6 hours)"
          view   = "timeSeries"
          stacked = false
          yAxis = {
            left = {
              label = "Count"
              showUnits = false
            }
          }
          setPeriodToTimeRange = true
        }
      },
      {
        type = "alarm"
        properties = {
          alarms = [
            aws_cloudwatch_metric_alarm.rapid_retrieval.arn,
            aws_cloudwatch_metric_alarm.unusual_pattern.arn,
            aws_cloudwatch_metric_alarm.failed_access_alarm.arn
          ]
          title = "Security Alarms"
        }
      },
      {
        type = "log"
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.cloudtrail.name}' | fields @timestamp, eventName, userIdentity.arn as User, resources.0.ARN as Secret, errorCode | filter eventName = 'GetSecretValue' | sort @timestamp desc | limit 20"
          region  = var.aws_region
          title   = "Recent Secret Access Events"
          view    = "table"
        }
      },
      {
        type = "text"
        properties = {
          markdown = <<EOF
#Secrets Manager Security Dashboard

## Auto-Revocation Status: ACTIVE
- Response Time: < 2 minutes
- Rotation on detection: **Immediate (1 day)**
- Monitoring: 24/7
- Alerts: Email + Slack

## Recent Auto-Revocation Events
Check Lambda logs for details: `/aws/lambda/${var.name_prefix}-auto-revoke-secrets`
EOF
          title   = "Security Summary"
        }
      }
    ]
  })
}