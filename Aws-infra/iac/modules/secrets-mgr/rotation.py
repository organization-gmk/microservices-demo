import json
import boto3
import logging
import os
import random
import string

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secretsmanager = boto3.client('secretsmanager')

def lambda_handler(event, context):
    """
    Handle secret rotation request from Secrets Manager
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    secret_id = event['SecretId']
    client_request_token = event['ClientRequestToken']
    step = event['Step']
    
    # Get the secret metadata
    metadata = secretsmanager.describe_secret(SecretId=secret_id)
    
    # Validate the rotation token
    if not metadata['RotationEnabled']:
        raise ValueError(f"Secret {secret_id} is not enabled for rotation")
    
    versions = metadata['VersionIdsToStages']
    if client_request_token not in versions:
        raise ValueError(f"Rotation token {client_request_token} not found in secret versions")
    
    if 'AWSCURRENT' in versions[client_request_token]:
        logger.info(f"Version {client_request_token} is already current for secret {secret_id}")
        return
    
    if step == 'createSecret':
        create_secret(secret_id, client_request_token)
    elif step == 'setSecret':
        set_secret(secret_id, client_request_token)
    elif step == 'testSecret':
        test_secret(secret_id, client_request_token)
    elif step == 'finishSecret':
        finish_secret(secret_id, client_request_token)
    else:
        raise ValueError(f"Invalid step parameter: {step}")

def create_secret(secret_id, token):
    """
    Create a new secret version
    """
    try:
        secretsmanager.get_secret_value(SecretId=secret_id, VersionId=token, VersionStage='AWSPENDING')
        logger.info(f"createSecret: Successfully retrieved secret for {secret_id} version {token}")
    except secretsmanager.exceptions.ResourceNotFoundException:
        # Get current secret value
        current = secretsmanager.get_secret_value(SecretId=secret_id, VersionStage='AWSCURRENT')
        current_secret = json.loads(current['SecretString'])
        
        # Generate new password for database secrets
        if 'POSTGRES_PASSWORD' in current_secret:
            new_password = generate_password()
            current_secret['POSTGRES_PASSWORD'] = new_password
        
        # Create new version
        secretsmanager.put_secret_value(
            SecretId=secret_id,
            ClientRequestToken=token,
            SecretString=json.dumps(current_secret),
            VersionStages=['AWSPENDING']
        )
        logger.info(f"createSecret: Successfully created pending secret for {secret_id} version {token}")

def set_secret(secret_id, token):
    """
    Set the secret in the target service (e.g., update database password)
    """
    # For database secrets, you would update the actual database here
    # This example assumes the application handles rotation via retry logic
    logger.info(f"setSecret: Skipping - application handles rotation via retry logic")
    pass

def test_secret(secret_id, token):
    """
    Test the new secret version
    """
    # Get the pending secret
    pending = secretsmanager.get_secret_value(
        SecretId=secret_id,
        VersionId=token,
        VersionStage='AWSPENDING'
    )
    logger.info(f"testSecret: Successfully retrieved pending secret version")
    # In a real implementation, you might test connecting with the new credentials
    pass

def finish_secret(secret_id, token):
    """
    Mark the new secret as current
    """
    # Get current metadata
    metadata = secretsmanager.describe_secret(SecretId=secret_id)
    
    # Move AWSCURRENT to the new version
    secretsmanager.update_secret_version_stage(
        SecretId=secret_id,
        VersionStage='AWSCURRENT',
        MoveToVersionId=token,
        RemoveFromVersionId=metadata['VersionIdsToStages']['AWSCURRENT'][0]
    )
    logger.info(f"finishSecret: Successfully moved AWSCURRENT to version {token}")

def generate_password(length=16):
    """
    Generate a random password
    """
    chars = string.ascii_letters + string.digits + "!@#$%^&*()"
    return ''.join(random.choice(chars) for _ in range(length))