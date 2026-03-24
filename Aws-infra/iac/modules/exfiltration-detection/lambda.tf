data "archive_file" "auto_revoke_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda-auto-revoke.zip"
  excludes    = ["__pycache__", "*.pyc"]  # Exclude Python cache files
}

# Lambda function (updated)
resource "aws_lambda_function" "auto_revoke" {
  filename         = data.archive_file.auto_revoke_lambda.output_path
  function_name    = "${var.name_prefix}-auto-revoke-secrets"
  role             = var.auto_revoke_lambda_arn
  handler          = "auto-revoke.lambda_handler"
  runtime          = "python3.9"
  timeout          = 60
  memory_size      = 256
  description      = "Auto-revokes compromised secrets when exfiltration detected"
  source_code_hash = data.archive_file.auto_revoke_lambda.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN      = aws_sns_topic.security_alerts.arn
      LOG_LEVEL          = "INFO"
      ROTATION_DAYS      = "1"
      DRY_RUN_MODE       = "false"
      ROTATION_LAMBDA_ARN = var.rotation_lambda_arn
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-auto-revoke-secrets"
  })

  depends_on = [
    data.archive_file.auto_revoke_lambda
  ]
}

# Allow SNS to invoke Lambda
resource "aws_lambda_permission" "sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_revoke.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.security_alerts.arn
}

# Subscribe Lambda to SNS
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.auto_revoke.arn
}
