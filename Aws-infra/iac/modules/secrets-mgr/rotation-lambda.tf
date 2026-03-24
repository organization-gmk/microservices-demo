##############################################################################################
# LAMBDA FOR SECRET ROTATION
##############################################################################################

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

# Lambda function
resource "aws_lambda_function" "secret_rotation" {
  function_name = "${var.name_prefix}-secret-rotation"
  role          = aws_iam_role.rotation_lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  timeout       = 300
  memory_size   = 128

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${var.aws_region}.amazonaws.com"
      LOG_LEVEL                = "INFO"
    }
  }

  tags = var.tags
}

# Lambda basic execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.rotation_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda policy for Secrets Manager
resource "aws_iam_role_policy" "secrets_manager_access" {
  name = "${var.name_prefix}-secrets-manager-access"
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
          "secretsmanager:UpdateSecretVersionStage",
          "secretsmanager:GetRandomPassword"
        ]
        # Using the secrets resources
        Resource = [
          aws_secretsmanager_secret.secrets["auth_db"].arn,
          aws_secretsmanager_secret.secrets["patient_db"].arn
        ]
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

# Create separate permission for EACH secret that needs rotation
locals {
  rotation_secrets_map = {
    for k, v in aws_secretsmanager_secret.secrets : k => v
    if local.secrets[k].enable_rotation == true
  }
}

resource "aws_lambda_permission" "secrets_manager" {
  for_each = local.rotation_secrets_map
  
  statement_id  = "AllowSecretsManagerInvocation-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secret_rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = each.value.arn
}

# Archive file for Lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda-rotation.zip"
}