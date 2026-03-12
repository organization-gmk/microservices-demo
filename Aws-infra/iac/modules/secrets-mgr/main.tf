##############################################################################################
# SECRETS MANAGER - CREATE SECRETS
##############################################################################################

# main.tf - DRY version
locals {
  # Generate a timestamp once per apply
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
  
  rotation_enabled_secrets = {
    for k, v in var.secrets : k => v
    if v.enable_rotation == true
  }
}

# Create all secrets dynamically
resource "aws_secretsmanager_secret" "secrets" {
  for_each = var.secrets
  
  # Add timestamp to name to avoid conflicts
  name = "${each.value.name}-${local.timestamp}"
  description = each.value.description

  
  
  tags = merge(var.tags, {
    Service  = each.value.service_tag
    Rotation = each.value.enable_rotation ? "enabled" : "disabled"
    OriginalName = each.value.name  # Store original name for reference
  })
  
    
}

# Enable rotation only for secrets that need it
resource "aws_secretsmanager_secret_rotation" "rotation" {
  for_each = local.rotation_enabled_secrets
  
  secret_id           = aws_secretsmanager_secret.secrets[each.key].id
  rotation_lambda_arn = aws_lambda_function.secret_rotation.arn
  
  rotation_rules {
    automatically_after_days = 30
  }
}
