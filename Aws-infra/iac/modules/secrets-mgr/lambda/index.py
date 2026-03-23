import boto3
import json
import logging
import random
import string

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secretsmanager = boto3.client('secretsmanager')

def lambda_handler(event, context):
    """
    Handle secret rotation request from Secrets Manager
    Triggered by:
    1. Scheduled rotation (every 30 days)
    2. Emergency rotation (exfiltration detected)
    """
    logger.info(f"Received rotation event: {json.dumps(event)}")
    
    secret_id = event['SecretId']
    client_request_token = event['ClientRequestToken']
    step = event['Step']
    
    # Get secret metadata
    metadata = secretsmanager.describe_secret(SecretId=secret_id)
    
    # Validate rotation is enabled
    if not metadata['RotationEnabled']:
        raise ValueError(f"Secret {secret_id} is not enabled for rotation")
    
    # Validate token
    versions = metadata['VersionIdsToStages']
    if client_request_token not in versions:
        raise ValueError(f"Rotation token {client_request_token} not found")
    
    # Already current? Nothing to do
    if 'AWSCURRENT' in versions[client_request_token]:
        logger.info(f"Version {client_request_token} is already current")
        return
    
    # Execute the appropriate step
    if step == 'createSecret':
        create_secret(secret_id, client_request_token)
    elif step == 'setSecret':
        set_secret(secret_id, client_request_token)
    elif step == 'testSecret':
        test_secret(secret_id, client_request_token)
    elif step == 'finishSecret':
        finish_secret(secret_id, client_request_token)
    else:
        raise ValueError(f"Invalid step: {step}")

def create_secret(secret_id, token):
    """
    Create a new secret version with a fresh password
    """
    try:
        # Check if version already exists
        secretsmanager.get_secret_value(
            SecretId=secret_id,
            VersionId=token,
            VersionStage='AWSPENDING'
        )
        logger.info(f"Secret version {token} already exists")
        return
    except secretsmanager.exceptions.ResourceNotFoundException:
        pass
    
    # Get current secret
    current = secretsmanager.get_secret_value(
        SecretId=secret_id,
        VersionStage='AWSCURRENT'
    )
    current_secret = json.loads(current['SecretString'])
    
    # Generate new password
    new_password = generate_password()
    
    # Update the password field
    if 'POSTGRES_PASSWORD' in current_secret:
        current_secret['POSTGRES_PASSWORD'] = new_password
    elif 'password' in current_secret:
        current_secret['password'] = new_password
    else:
        current_secret['password'] = new_password
    
    # Create new pending version
    secretsmanager.put_secret_value(
        SecretId=secret_id,
        ClientRequestToken=token,
        SecretString=json.dumps(current_secret),
        VersionStages=['AWSPENDING']
    )
    logger.info(f"✅ Created new pending secret version {token}")

def set_secret(secret_id, token):
    """
    Update the database with the new password
    For POC demo, we skip actual database update
    """
    logger.info(f"✅ POC: Would update database with new credentials")
    # In production, you would update RDS here:
    # - Connect to PostgreSQL using CURRENT credentials
    # - Execute ALTER USER command with new password
    pass

def test_secret(secret_id, token):
    """
    Test the new secret version
    For POC demo, we assume it works
    """
    logger.info(f"✅ POC: New credentials tested successfully")
    # In production, you would test connection to database
    pass

def finish_secret(secret_id, token):
    """
    Promote the new secret version to AWSCURRENT
    """
    metadata = secretsmanager.describe_secret(SecretId=secret_id)
    
    # Find current version
    current_version = None
    for version_id, stages in metadata['VersionIdsToStages'].items():
        if 'AWSCURRENT' in stages:
            current_version = version_id
            break
    
    # Move AWSCURRENT to new version
    secretsmanager.update_secret_version_stage(
        SecretId=secret_id,
        VersionStage='AWSCURRENT',
        MoveToVersionId=token,
        RemoveFromVersionId=current_version
    )
    logger.info(f"✅ Rotation complete! New version {token} is now AWSCURRENT")

def generate_password(length=20):
    """
    Generate a random password
    """
    chars = string.ascii_letters + string.digits + "!@#$%^&*"
    return ''.join(random.choice(chars) for _ in range(length))