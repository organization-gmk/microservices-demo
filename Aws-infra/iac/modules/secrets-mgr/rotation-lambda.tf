# Rotation Lambda function
resource "aws_lambda_function" "secret_rotation" {
  filename      = "lambda-rotation.zip"
  function_name = "${var.name_prefix}-secret-rotation"
  role          = aws_iam_role.rotation_lambda_role.arn
  handler       = "rotation.lambda_handler"
  runtime       = "python3.9"
  timeout       = 300
  memory_size   = 128

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${var.aws_region}.amazonaws.com"
      # Add logging level for debugging
      LOG_LEVEL = "INFO"
    }
  }

  tags = var.tags
}

# Lambda permission for Secrets Manager to invoke it
resource "aws_lambda_permission" "secrets_manager" {
  statement_id  = "AllowSecretsManagerInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secret_rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = [for secret in aws_secretsmanager_secret.secrets : secret.arn]
}


# IAM role for Lambda
resource "aws_iam_role" "rotation_lambda_role" {
  name = "${var.name_prefix}-secret-rotation-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

# Lambda policy for Secrets Manager access
resource "aws_iam_role_policy" "rotation_lambda_policy" {
  name = "${var.name_prefix}-rotation-lambda-policy"
  role = aws_iam_role.rotation_lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        # Grant access to all secrets created by this module
        Resource = [for secret in aws_secretsmanager_secret.secrets : secret.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}
